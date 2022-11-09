import os
from hm_pyhelper.hardware_definitions import variant_definitions
from pktfwd.utils import init_sentry, is_concentrator_sx1302, \
                        update_global_conf, write_diagnostics, \
                        await_system_ready, retry_start_concentrator
from hm_pyhelper.logger import get_logger
from hm_pyhelper.miner_param import retry_get_region, await_spi_available


LOGGER = get_logger(__name__)
# Name of envvar that reset_lgw.sh expects to contain the reset_pin value
RESET_LGW_RESET_PIN_ENV_KEY = "CONCENTRATOR_RESET_PIN"


class PktfwdApp:
    def __init__(self, variant, region_override, region_filepath,
                 sx1301_region_configs_dir, sx1302_region_configs_dir,
                 sentry_dsn, balena_id, balena_app,
                 diagnostics_filepath, await_system_sleep_seconds,
                 reset_lgw_filepath,
                 util_chip_id_filepath, root_dir,
                 sx1302_lora_pkt_fwd_filepath, sx1301_lora_pkt_fwd_dir):  # noqa

        init_sentry(sentry_dsn, balena_id, balena_app)
        self.set_variant_attributes(variant)
        self.sx1301_region_configs_dir = sx1301_region_configs_dir
        self.sx1302_region_configs_dir = sx1302_region_configs_dir
        self.region_override = region_override
        self.region_filepath = region_filepath
        self.diagnostics_filepath = diagnostics_filepath
        self.await_system_sleep_seconds = await_system_sleep_seconds
        self.reset_lgw_filepath = reset_lgw_filepath
        self.util_chip_id_filepath = util_chip_id_filepath
        self.root_dir = root_dir
        self.sx1301_lora_pkt_fwd_dir = sx1301_lora_pkt_fwd_dir
        self.sx1302_lora_pkt_fwd_filepath = sx1302_lora_pkt_fwd_filepath

    def start(self):
        LOGGER.debug("STARTING PKTFWD")
        self.prepare_to_start()

        is_sx1302 = is_concentrator_sx1302(self.util_chip_id_filepath,
                                           self.spi_bus)

        update_global_conf(is_sx1302, self.root_dir,
                           self.sx1301_region_configs_dir,
                           self.sx1302_region_configs_dir, self.region,
                           self.spi_bus)

        retry_start_concentrator(is_sx1302, self.spi_bus,
                                 self.sx1302_lora_pkt_fwd_filepath,
                                 self.sx1301_lora_pkt_fwd_dir,
                                 self.reset_lgw_filepath,
                                 self.diagnostics_filepath,
                                 self.region_filepath)

        # retry_start_concentrator will hang indefinitely while the
        # upstream packet_forwarder runs. The lines below will only
        # be reached if the concentrator exits unexpectedly.
        LOGGER.warning("Shutting down concentrator.")
        self.stop()

    def prepare_to_start(self):
        """
        Performs additional initialization not done in __init__
        because it depends on the filesystem being available.
        """
        write_diagnostics(self.diagnostics_filepath, False)
        await_spi_available(self.spi_bus)

        self.region = retry_get_region(self.region_override,
                                       self.region_filepath)

        LOGGER.debug("Region set to %s" % self.region)

        await_system_ready(self.await_system_sleep_seconds)
        LOGGER.debug("Finished preparing pktfwd")

    def stop(self):
        LOGGER.debug("STOPPING PKTFWD")
        write_diagnostics(self.diagnostics_filepath, False)

    def set_variant_attributes(self, variant):
        self.variant = variant
        self.variant_attributes = variant_definitions[self.variant]
        self.reset_pin = self.variant_attributes['RESET']
        # reset_lgw.sh is called throughout this app without supplying
        # the reset pin as an argument. The script falls back to the
        # value in envvar RESET_LGW_RESET_PIN_ENV_KEY.
        os.environ[RESET_LGW_RESET_PIN_ENV_KEY] = str(self.reset_pin)
        self.spi_bus = self.variant_attributes['SPIBUS']
        LOGGER.debug("Variant %s set with reset_pin %s and spi_bus %s" %
                     (self.variant, self.reset_pin, self.spi_bus))
