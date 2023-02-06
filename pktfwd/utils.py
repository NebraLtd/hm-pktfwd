import json
import subprocess
import sentry_sdk
import logging
import os
from time import sleep
from shutil import copyfile
from tenacity import retry, wait_fixed, before_sleep_log
from jinja2 import Template
from hm_pyhelper.logger import get_logger, LOGLEVEL
from pktfwd.config.region_config_filenames import REGION_CONFIG_FILENAMES
from hm_pyhelper.miner_param import retry_get_region
from hm_pyhelper.miner_param import get_ethernet_addresses


LOGGER = get_logger(__name__)
LOGLEVEL_INT = getattr(logging, LOGLEVEL)
# Number of seconds to sleep between lora_pkt_fwd start attempts.
# Also num secs to wait before attempts at updating the diagnostics value.
LORA_PKT_FWD_BEFORE_CHECK_SLEEP_SECONDS = int(os.getenv('LORA_PKT_FWD_BEFORE_CHECK_SLEEP_SECONDS', '5'))  # noqa: E501
LORA_PKT_FWD_AFTER_SUCCESS_SLEEP_SECONDS = int(os.getenv('LORA_PKT_FWD_AFTER_SUCCESS_SLEEP_SECONDS', '30'))  # noqa: E501
LORA_PKT_FWD_AFTER_FAILURE_SLEEP_SECONDS = int(os.getenv('LORA_PKT_FWD_AFTER_FAILURE_SLEEP_SECONDS', '2'))  # noqa: E501


class LoraPacketForwarderStoppedWithoutError(Exception):
    pass


def init_sentry(sentry_dsn, balena_id, balena_app):
    """
    Initialize sentry with balena_id and balena_app as tag.
    If sentry_dsn is not set, do nothing.
    """

    if not sentry_dsn:
        return

    sentry_sdk.init(sentry_dsn)

    sentry_sdk.set_tag("balena_id", balena_id)
    sentry_sdk.set_tag("balena_app", balena_app)


def write_diagnostics(diagnostics_filepath, is_running):
    """
    Write "true" to diagnostics_filepath if pktfwd is running,
    "false" otherwise.
    """
    with open(diagnostics_filepath, 'w') as diagnostics_stream:
        if (is_running):
            diagnostics_stream.write("true")
        else:
            diagnostics_stream.write("false")


def await_system_ready(sleep_seconds):
    """
    Sleep before starting core functions.
    """
    LOGGER.debug("Waiting %s seconds for systems to be ready" % sleep_seconds)
    sleep(sleep_seconds)
    LOGGER.debug("System now ready")


def run_reset_lgw(reset_lgw_filepath):
    """
    Invokes reset_lgw.sh script with the reset pin value.
    """
    subprocess.run([reset_lgw_filepath, "stop"])
    subprocess.run([reset_lgw_filepath, "start"])


def is_concentrator_sx1302(util_chip_id_filepath, spi_bus):
    """
    Use the util_chip_id to determine if concentrator is sx1302.
    util_chip_id calls the sx1302_hal reset_lgw.sh script during execution.
    """
    util_chip_id_cmd = [util_chip_id_filepath, "-d", "/dev/{}".format(spi_bus)]

    try:
        subprocess.run(util_chip_id_cmd, capture_output=True,
                       text=True, check=True)
        LOGGER.debug("SX1302 / SX1303 detected. \
                     util_chip_id script exited without error.")
        return True
    # CalledProcessError raised if there is a non-zero exit code
    # https://docs.python.org/3/library/subprocess.html#using-the-subprocess-module
    except subprocess.CalledProcessError as e:
        LOGGER.debug(e)
    except Exception:
        LOGGER.exception("SX1301 detected.\
                          util_chip_id script exited with error.")

    return False


def get_region_filename(region):
    """
    Return filename for config corresponding to region.
    """
    return REGION_CONFIG_FILENAMES[region]


def update_global_conf(is_sx1302, root_dir, sx1301_region_configs_dir,
                       sx1302_region_configs_dir, region, spi_bus):
    """
    Replace global_conf.json with the configuration necessary given
    the concentrator chip type, region, and spi_bus. Also copies the
    local_conf.json to the correct location
    """
    if is_sx1302:
        replace_sx1302_global_conf_with_regional(root_dir,
                                                 sx1302_region_configs_dir,
                                                 region, spi_bus)
    else:
        replace_sx1301_global_conf_with_regional(root_dir,
                                                 sx1301_region_configs_dir,
                                                 region)


def populate_local_conf_template(template_file):
    mac_addrs = {'E0': '', 'W0': ''}
    get_ethernet_addresses(mac_addrs)

    mac_address = mac_addrs.get('E0')
    if not mac_address:
        mac_address = mac_addrs.get('W0')

    gateway_id = mac_address.replace(':', '')
    with open(template_file) as file_:
        template = Template(file_.read())

    rendered = template.render(gateway_id=gateway_id)
    with open(template_file, "w") as file_:
        file_.write(rendered)


def replace_sx1301_global_conf_with_regional(root_dir,
                                             sx1301_region_configs_dir,
                                             region):
    """
    Copy the regional configuration file to global_conf.json
    and copy the local_conf.json to the correct locaion
    """
    region_config_filepath = "%s/%s" % \
                             (sx1301_region_configs_dir,
                              get_region_filename(region))

    old_local_config_filepath = "%s/%s" % \
                                (sx1301_region_configs_dir,
                                 "local_conf.json")

    global_config_filepath = "%s/%s" % (root_dir, "global_conf.json")
    local_config_filepath = "%s/%s" % (root_dir, "local_conf.json")
    LOGGER.debug("Copying SX1301 global conf from %s to %s" %
                 (region_config_filepath, global_config_filepath))
    copyfile(region_config_filepath, global_config_filepath)
    LOGGER.debug("Copying SX1301 local conf from %s to %s" %
                 (old_local_config_filepath, local_config_filepath))
    populate_local_conf_template(old_local_config_filepath)
    copyfile(old_local_config_filepath, local_config_filepath)


def replace_sx1302_global_conf_with_regional(root_dir,
                                             sx1302_region_configs_dir,
                                             region, spi_bus):
    """
    Parses the regional configuration file in order to make changes
    and save them to global_conf.json and copies the local_conf.json
    to the correct locaion
    """
    # Write the configuration files
    region_config_filepath = "%s/%s" % \
                             (sx1302_region_configs_dir,
                              get_region_filename(region))

    old_local_config_filepath = "%s/%s" % \
                                (sx1302_region_configs_dir,
                                 "local_conf.json")

    global_config_filepath = "%s/%s" % \
                             (root_dir,
                              "global_conf.json")

    local_config_filepath = "%s/%s" % \
                            (root_dir,
                             "local_conf.json")

    with open(region_config_filepath) as region_config_file:
        new_global_conf = json.load(region_config_file)

    with open(old_local_config_filepath) as local_config_file:
        local_conf = json.load(local_config_file)

    merged_global_conf = dict(new_global_conf)
    merged_global_conf.update(local_conf)

    LOGGER.debug("Injecting SPI bus %s into global conf" %
                 (spi_bus))

    # Inject SPI Bus
    merged_global_conf['SX130x_conf']['com_path'] = "/dev/%s" % spi_bus

    LOGGER.debug("Saving SX1302 global conf from %s to %s with spi bus %s" %
                 (region_config_filepath, global_config_filepath, spi_bus))

    with open(global_config_filepath, 'w') as global_config_file:
        json.dump(merged_global_conf, global_config_file)

    LOGGER.debug("Copying SX1302 local conf from %s to %s" %
                 (old_local_config_filepath, local_config_filepath))
    populate_local_conf_template(old_local_config_filepath)
    copyfile(old_local_config_filepath, local_config_filepath)


@retry(wait=wait_fixed(LORA_PKT_FWD_AFTER_FAILURE_SLEEP_SECONDS),
       before_sleep=before_sleep_log(LOGGER, LOGLEVEL_INT))
def retry_start_concentrator(is_sx1302, spi_bus,
                             sx1302_lora_pkt_fwd_filepath,
                             sx1301_lora_pkt_fwd_dir,
                             reset_lgw_filepath,
                             diagnostics_filepath,
                             region_filepath):
    """
    Retry to start lora_pkt_fwd for the corresponding concentrator model.
    """
    lora_pkt_fwd_filepath = sx1302_lora_pkt_fwd_filepath

    if not is_sx1302:
        # sx1301 must explicitly reset,
        # sx1302 automatically resets before starting
        run_reset_lgw(reset_lgw_filepath)
        lora_pkt_fwd_filepath = "%s/lora_pkt_fwd_%s" % \
                                (sx1301_lora_pkt_fwd_dir, spi_bus)

    old_region = retry_get_region(None, region_filepath)

    LOGGER.debug("Region before starting concentrator %s" % old_region)

    lora_pkt_fwd_proc = subprocess.Popen([lora_pkt_fwd_filepath])
    lora_pkt_fwd_proc_is_running = True
    sleep(LORA_PKT_FWD_BEFORE_CHECK_SLEEP_SECONDS)

    while lora_pkt_fwd_proc_is_running:
        lora_pkt_fwd_proc_returncode = lora_pkt_fwd_proc.poll()
        lora_pkt_fwd_proc_is_running = lora_pkt_fwd_proc_returncode is None
        write_diagnostics(diagnostics_filepath, lora_pkt_fwd_proc_is_running)

        # lora_pkt_fwd is running, sleep then poll again.
        if lora_pkt_fwd_proc_is_running:
            sleep(LORA_PKT_FWD_AFTER_SUCCESS_SLEEP_SECONDS)

        # lora_pkt_fwd exited without error. Attempt to restart the process
        # by throwing an exception, which will trigger retry.
        elif lora_pkt_fwd_proc_returncode == 0:
            raise LoraPacketForwarderStoppedWithoutError(
                "lora_pkt_fwd stopped without error.")

        # lora_pkt_fwd exited with error. Restart the container by letting
        # the python application exit without error.
        else:
            LOGGER.warning("lora_pkt_fwd stopped with code=%s." %
                           lora_pkt_fwd_proc_returncode)

        # check if concentrator restart is needed. we depend on container
        # restart to restart the concentrator with correct configuration.
        # Thus we exit the application without error.
        new_region = retry_get_region(None, region_filepath)
        if old_region != new_region:
            lora_pkt_fwd_proc.kill()
            LOGGER.warning("concentrator exiting due to region plan change"
                           f" old: {old_region} to new: {new_region}")
            exit(0)
