from time import sleep
import os
import json
import subprocess
import retry
from hm_pyhelper.logger import get_logger
from shutil import copyfile
import sentry_sdk
from pktfwd.config.region_config_filenames import REGION_CONFIG_FILENAMES

LOGGER = get_logger(__name__)
LORA_PKT_FWD_RETRY_SLEEP_SECONDS = 2
LORA_PKT_FWD_MAX_TRIES = 5

def init_sentry(sentry_key, balena_id, balena_app):
    if(sentry_key):
        sentry_sdk.init(sentry_key, environment=balena_app)
        sentry_sdk.set_user({"id": balena_id})


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
    TODO: Get more information about why.
    Original code: https://github.com/NebraLtd/hm-pktfwd/blob/5a0178341e69ecbf6b1dbc8463f6bd1231e9e657/files/configurePktFwd.py#L77
    """
    LOGGER.debug("Waiting %s seconds for systems to be ready" % sleep_seconds)
    sleep(sleep_seconds)
    LOGGER.debug("System now ready")


def run_reset_lgw(reset_lgw_filepath, reset_lgw_pin_envvar, reset_lgw_pin):
    """
    Invokes reset_lgw.sh script after setting the reset pin envvar
    TODO permalink to script
    """
    os.environ[reset_lgw_pin_envvar] = reset_lgw_pin
    subprocess.run([reset_lgw_filepath, "stop"])
    subprocess.run([reset_lgw_filepath, "start"])


def is_concentrator_sx1302(util_chip_id_filepath, spi_bus):
    """
    Use the util_chip_id to determine if concentrator is sx1302
    TODO permalink to script
    """
    util_chip_id_cmd = [util_chip_id_filepath, "-d", "/dev/{}".format(spi_bus)]
    util_chip_id_response = subprocess.run(util_chip_id_cmd, capture_output=True, text=True).stdout  # nosec (B603)
    return "concentrator EUI:" in util_chip_id_response


def get_region_filename(region):
    return REGION_CONFIG_FILENAMES[region]


def update_global_conf(is_sx1302, sx1301_region_configs_path, sx1302_region_configs_path, region, spi_bus):
    if is_sx1302:
        replace_sx1302_global_conf_with_regional(sx1302_region_configs_path, region, spi_bus)
    else:
        replace_sx1301_global_conf_with_regional(sx1301_region_configs_path, region)


def replace_sx1301_global_conf_with_regional(sx1301_region_configs_path, region):
    """
    Copy the regional configuration file to global_conf.json
    """
    region_config_filepath = "%s/%s" % (sx1301_region_configs_path, get_region_filename(region))
    global_config_filepath = "%s/%s" % (sx1301_region_configs_path, "global_conf.json")
    copyfile(region_config_filepath, global_config_filepath)


def replace_sx1302_global_conf_with_regional(sx1302_region_configs_path, region, spi_bus):
    """
    Parses the regional configuration file in order to make changes and save them 
    to global_conf.json
    """
    # Writes the configuration files
    region_config_filepath = "%s/%s" % (sx1302_region_configs_path, get_region_filename(region))
    global_config_filepath = "%s/%s" % (sx1302_region_configs_path, "global_conf.json")
  
    with open(region_config_filepath) as region_config_file:
        new_global_conf = json.load(region_config_file)

    # Inject SPI Bus
    new_global_conf['SX130x_conf']['com_path'] = "/dev/%s" % spi_bus

    with open(global_config_filepath, 'w') as global_config_file:
        json.dump(new_global_conf, global_config_file)


@retry(Exception, delay=LORA_PKT_FWD_RETRY_SLEEP_SECONDS, tries=LORA_PKT_FWD_MAX_TRIES, logger=LOGGER) # noqa
def retry_start_concentrator(is_sx1302, spi_bus, sx1302_lora_pkt_fwd_filepath, sx1301_lora_pkt_fwd_dir,
                            reset_lgw_filepath, reset_lgw_pin_envvar, reset_lgw_pin):
    """
    Retry to start lora_pkt_fwd for the corresponding concentrator model.
    Runs the reset_lgw script before every attempt.
    """
    run_reset_lgw(reset_lgw_filepath, reset_lgw_pin_envvar, reset_lgw_pin)

    if is_sx1302:
        subprocess.run(sx1302_lora_pkt_fwd_filepath) 
    else:
        sx1301_lora_pkt_fwd_filepath = "%s/lora_pkt_fwd_%s" % (sx1301_lora_pkt_fwd_dir, spi_bus)
        subprocess.run(sx1301_lora_pkt_fwd_filepath)