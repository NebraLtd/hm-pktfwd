#!/usr/bin/env bash

if [ ! -d "/sys/class/gpio/gpio$1" ]; then
    echo "$1" > /sys/class/gpio/export
fi
echo "out" > "/sys/class/gpio/gpio$1/direction"
sleep 2
echo "1" > "/sys/class/gpio/gpio$1/value"
sleep 2
echo "0" > "/sys/class/gpio/gpio$1/value"
