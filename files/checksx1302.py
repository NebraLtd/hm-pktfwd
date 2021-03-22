# This program checks if the lora module is an SX1301 or SX1302/3

import os

euiTest = os.popen('./chip_id -d /dev/spidev1.2').read()

#pprint(euiTest)

if "concentrator EUI:" in euiTest:
    print("SX1302")
else:
    print("SX1301")
