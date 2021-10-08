import os
import logging
# TODO import from pyhelper instead
logging.basicConfig(level=os.environ.get("LOGLEVEL", "DEBUG"))

from pktfwd.pktfwd_app import PktfwdApp

# Mandatory
VARIANT = os.environ['VARIANT']
SX1301_REGION_CONFIGS_PATH = os.environ['SX1301_REGION_CONFIGS_PATH']
SX1302_REGION_CONFIGS_PATH = os.environ['SX1302_REGION_CONFIGS_PATH']
UTIL_CHIP_ID_FILEPATH = os.environ['UTIL_CHIP_ID_FILEPATH'] # '/opt/iotloragateway/packet_forwarder/sx1302/util_chip_id/chip_id')
RESET_LGW_FILEPATH = os.environ['RESET_LGW_FILEPATH']
SX1302_LORA_PKT_FWD_FILEPATH = os.environ['SX1302_LORA_PKT_FWD_FILEPATH']
SX1301_LORA_PKT_FWD_DIR = os.environ['SX1301_LORA_PKT_FWD_DIR']

# Defaults
REGION_FILEPATH = os.getenv('REGION_FILEPATH', '/var/pktfwd/region')
DIAGNOSTICS_FILEPATH = os.getenv('DIAGNOSTICS_FILEPATH', '/var/pktfwd/diagnostics')
AWAIT_SYSTEM_SLEEP_SECONDS = int(os.getenv('AWAIT_SYSTEM_SLEEP_SECONDS', '5'))
RESET_LGW_PIN_ENVVAR = os.getenv('RESET_LGW_PIN_ENVVAR', 'IOT_SK_SX1301_RESET_PIN')

# Optional
REGION_OVERRIDE = os.getenv('REGION_OVERRIDE')
SENTRY_KEY = os.getenv('SENTRY_PKTFWD', False)
BALENA_ID = os.getenv('BALENA_DEVICE_UUID')
BALENA_APP = os.getenv('BALENA_APP_NAME')




def main():
    validate_env()
    start()

def validate_env():
    logging.debug("Starting with the following ENV:\n\
        VARIANT=%s\n\
        REGION_OVERRIDE=%s\n\
        REGION_FILEPATH=%s\n\
        SX1301_REGION_CONFIGS_PATH=%s\n\
        SX1302_REGION_CONFIGS_PATH=%s\n\
        SENTRY_KEY=%s\n\
        BALENA_ID=%s\n\
        BALENA_APP=%s\n\
        DIAGNOSTICS_FILEPATH=%s\n\
        AWAIT_SYSTEM_SLEEP_SECONDS=%s\n\
        RESET_LGW_FILEPATH=%s\n\
        RESET_LGW_PIN_ENVVAR=%s\n\
        UTIL_CHIP_ID_FILEPATH=%s\n\
        SX1302_LORA_PKT_FWD_FILEPATH=%s\n\
        SX1301_LORA_PKT_FWD_DIR=%s\n" % 
        (VARIANT, REGION_OVERRIDE, REGION_FILEPATH, SX1301_REGION_CONFIGS_PATH, SX1302_REGION_CONFIGS_PATH, SENTRY_KEY, 
            BALENA_ID, BALENA_APP, DIAGNOSTICS_FILEPATH, AWAIT_SYSTEM_SLEEP_SECONDS,
            RESET_LGW_FILEPATH, RESET_LGW_PIN_ENVVAR, UTIL_CHIP_ID_FILEPATH, 
            SX1302_LORA_PKT_FWD_FILEPATH, SX1301_LORA_PKT_FWD_DIR))


def start():
    pktfwd_app = PktfwdApp(VARIANT, REGION_OVERRIDE, REGION_FILEPATH, SX1301_REGION_CONFIGS_PATH, SX1302_REGION_CONFIGS_PATH, 
                    SENTRY_KEY, BALENA_ID, BALENA_APP, DIAGNOSTICS_FILEPATH, AWAIT_SYSTEM_SLEEP_SECONDS,
                    RESET_LGW_FILEPATH, RESET_LGW_PIN_ENVVAR, UTIL_CHIP_ID_FILEPATH,
                    SX1302_LORA_PKT_FWD_FILEPATH, SX1301_LORA_PKT_FWD_DIR)
    try:
        pktfwd_app.start()
    except Exception:
        logging.exception('__main__ failed for unknown reason')
        pktfwd_app.stop()


if __name__ == "__main__":
    main()