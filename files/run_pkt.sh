#!/usr/bin/env bash

#Run Packetforward
#This script runs on the boot of the container

#Run python to do configuration and run the induvidual forwarders
python3 -u configurePktFwd.py
