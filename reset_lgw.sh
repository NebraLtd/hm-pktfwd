#!/bin/sh

# This script is intended to be used on all sx130x platforms. It performs
# the following actions:
#       - export/unpexort GPIO pin ${CONCENTRATOR_RESET_PIN} used to reset the SX130x chip and to enable the LDOs
#       - can also be used to reset other functions like the optional SX1261 radio used for LBT/Spectral Scan, SX1302 power enable,
#           or AD5338R reset, by changing the value of CONCENTRATOR_RESET_PIN
#
# Usage examples:
#       CONCENTRATOR_RESET_PIN=23 ./reset_lgw.sh stop
#       CONCENTRATOR_RESET_PIN=23 ./reset_lgw.sh start
#
# CONCENTRATOR_RESET_PIN can also be set by passing it in as the second parameter. Eg:
#       ./reset_lgw.sh stop 23
#       ./reset_lgw.sh start 23
# 
# This script is inspired by the original upstream versions:
#   - https://github.com/NebraLtd/lora_gateway/blob/971c52e3e0f953102c0b057c9fff9b1df8a84d66/reset_lgw.sh
#   - https://github.com/NebraLtd/sx1302_hal/blob/6324b7a568ee24dbd9c4da64df69169a22615311/tools/reset_lgw.sh

if [ -z "$2" ]; then 
    echo "CONCENTRATOR_RESET_PIN parameter not passed in, using value from the environment (val=${CONCENTRATOR_RESET_PIN})"
else
    CONCENTRATOR_RESET_PIN=$2
fi

WAIT_GPIO() {
    sleep 0.1
}

init() {
    # setup GPIOs
    echo "${CONCENTRATOR_RESET_PIN}" > /sys/class/gpio/export; WAIT_GPIO

    # set GPIOs as output
    echo "out" > "/sys/class/gpio/gpio${CONCENTRATOR_RESET_PIN}/direction"; WAIT_GPIO
}

reset() {
    echo "CoreCell reset through GPIO${CONCENTRATOR_RESET_PIN}..."

    # If #reset is called before #init, gpio may not be available
    # This prevents file not found errors from showing in the logs
    if [ -d "/sys/class/gpio/gpio${CONCENTRATOR_RESET_PIN}" ]
    then
        echo "1" > "/sys/class/gpio/gpio${CONCENTRATOR_RESET_PIN}/value"; WAIT_GPIO
        echo "0" > "/sys/class/gpio/gpio${CONCENTRATOR_RESET_PIN}/value"; WAIT_GPIO
    fi
}

term() {
    # cleanup all GPIOs
    if [ -d "/sys/class/gpio/gpio${CONCENTRATOR_RESET_PIN}" ]
    then
        echo "${CONCENTRATOR_RESET_PIN}" > /sys/class/gpio/unexport; WAIT_GPIO
    fi
}

case "$1" in
    start)
    term # just in case
    init
    reset
    ;;
    stop)
    reset
    term
    ;;
    *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

exit 0