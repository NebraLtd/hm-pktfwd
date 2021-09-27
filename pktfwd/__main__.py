import os
import logging
# TODO import from pyhelper instead
logging.basicConfig(level=os.environ.get("LOGLEVEL", "DEBUG"))

from pktfwd.pktfwd_app import PktfwdApp

VARIANT = os.environ['VARIANT']
REGION_CONFIGS_PATH = os.environ['REGION_CONFIGS_PATH']
REGION_OVERRIDE = os.getenv('REGION_OVERRIDE')

def main():
    validate_env()
    start()


def validate_env():
    logging.debug("Starting with the following ENV:\n\
        VARIANT=%s\n\
        REGION_CONFIGS_PATH=%s\n\
        REGION_OVERRIDE=%s\n" % 
        (VARIANT, REGION_CONFIGS_PATH, REGION_OVERRIDE))


def start():
    pktfwd_app = PktfwdApp(VARIANT, REGION_OVERRIDE)
    try:
        pktfwd_app.start()
    except Exception:
        logging.exception('__main__ failed for unknown reason')
        pktfwd_app.stop()


if __name__ == "__main__":
    main()