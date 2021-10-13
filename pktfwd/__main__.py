import os
from hm_pyhelper.logger import get_logger
from pktfwd.pktfwd_app import PktfwdApp


LOGGER = get_logger(__name__)


#
# Mandatory
#
VARIANT = os.environ['VARIANT']
SX1301_REGION_CONFIGS_DIR = os.environ['SX1301_REGION_CONFIGS_DIR']
SX1302_REGION_CONFIGS_DIR = os.environ['SX1302_REGION_CONFIGS_DIR']
UTIL_CHIP_ID_FILEPATH = os.environ['UTIL_CHIP_ID_FILEPATH'] # '/opt/iotloragateway/packet_forwarder/sx1302/util_chip_id/chip_id')
RESET_LGW_FILEPATH = os.environ['RESET_LGW_FILEPATH']
# Directory the python script will be run from. global_conf.json will be copied here
ROOT_DIR = os.environ['ROOT_DIR']
SX1302_LORA_PKT_FWD_FILEPATH = os.environ['SX1302_LORA_PKT_FWD_FILEPATH']
SX1301_LORA_PKT_FWD_DIR = os.environ['SX1301_LORA_PKT_FWD_DIR']

#
# Defaults
#

# File where hm-miner outputs region info
# https://github.com/NebraLtd/hm-miner/blob/98107f50257de420a42dec50cca6e2f667f899ad/gen-region.sh#L9
REGION_FILEPATH = os.getenv('REGION_FILEPATH', '/var/pktfwd/region')

# File that pktfwd outputs diagnostic info to. This is different than diagnostics
# managed by hm-diag. Currently this file only contains "true" or "false"
# corresponding to whether pktfwd is actively running.
DIAGNOSTICS_FILEPATH = os.getenv('DIAGNOSTICS_FILEPATH', '/var/pktfwd/diagnostics')

# Sleep time before attempting to start concentrator.
# TODO more details about why necessary
AWAIT_SYSTEM_SLEEP_SECONDS = int(os.getenv('AWAIT_SYSTEM_SLEEP_SECONDS', '5'))

# If False, Sentry will not be enabled
SENTRY_KEY = os.getenv('SENTRY_PKTFWD', False)

#
# Optional
#

# Overrides the region detected in $REGION_FILEPATH, if defined
REGION_OVERRIDE = os.getenv('REGION_OVERRIDE')

# Balena vars used with Sentry
BALENA_ID = os.getenv('BALENA_DEVICE_UUID')
BALENA_APP = os.getenv('BALENA_APP_NAME')


def main():
    validate_env()
    start()

def validate_env():
    LOGGER.debug("Starting with the following ENV:\n\
        VARIANT=%s\n\
        REGION_OVERRIDE=%s\n\
        REGION_FILEPATH=%s\n\
        SX1301_REGION_CONFIGS_DIR=%s\n\
        SX1302_REGION_CONFIGS_DIR=%s\n\
        SENTRY_KEY=%s\n\
        BALENA_ID=%s\n\
        BALENA_APP=%s\n\
        DIAGNOSTICS_FILEPATH=%s\n\
        AWAIT_SYSTEM_SLEEP_SECONDS=%s\n\
        RESET_LGW_FILEPATH=%s\n\
        UTIL_CHIP_ID_FILEPATH=%s\n\
        ROOT_DIR=%s\n\
        SX1302_LORA_PKT_FWD_FILEPATH=%s\n\
        SX1301_LORA_PKT_FWD_DIR=%s\n" % 
        (VARIANT, REGION_OVERRIDE, REGION_FILEPATH, SX1301_REGION_CONFIGS_DIR, SX1302_REGION_CONFIGS_DIR, SENTRY_KEY, 
            BALENA_ID, BALENA_APP, DIAGNOSTICS_FILEPATH, AWAIT_SYSTEM_SLEEP_SECONDS,
            RESET_LGW_FILEPATH, UTIL_CHIP_ID_FILEPATH, ROOT_DIR,
            SX1302_LORA_PKT_FWD_FILEPATH, SX1301_LORA_PKT_FWD_DIR))


def start():
    pktfwd_app = PktfwdApp(VARIANT, REGION_OVERRIDE, REGION_FILEPATH, SX1301_REGION_CONFIGS_DIR, SX1302_REGION_CONFIGS_DIR, 
                    SENTRY_KEY, BALENA_ID, BALENA_APP, DIAGNOSTICS_FILEPATH, AWAIT_SYSTEM_SLEEP_SECONDS,
                    RESET_LGW_FILEPATH, UTIL_CHIP_ID_FILEPATH, ROOT_DIR,
                    SX1302_LORA_PKT_FWD_FILEPATH, SX1301_LORA_PKT_FWD_DIR)
    try:
        pktfwd_app.start()
    except Exception:
        LOGGER.exception('__main__ failed for unknown reason')
        pktfwd_app.stop()


if __name__ == "__main__":
    main()