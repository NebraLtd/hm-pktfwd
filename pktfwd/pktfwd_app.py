print("TODO")

def start():
    print("STARTING")

def stop():
    print("STOPPING")
    
# Configure Packet Forwarder Program
# Configures the packet forwarder based on the YAML File and Env Variables
# import sentry_sdk
# import subprocess  # nosec (B404)
# import os
# import json
# from hm_hardware_defs.variant import variant_definitions

# from time import sleep

# variant = os.getenv('VARIANT')
# variant_variables = variant_definitions[variant]
# # Reset pin is on this GPIO
# reset_pin = variant_variables['RESET']
# # And SPI on this bus
# spi_bus = variant_variables['SPIBUS']
# print("Hardware Variant {} detected".format(variant))
# print("RESET: {}".format(reset_pin))
# print("SPI: {}".format(spi_bus))

# # Check for SPI bus availability
# if os.path.exists('/dev/{}'.format(spi_bus)):
#     print("SPI bus Configured Correctly")
# else:
#     print("ERROR: SPI bus not found!")

# print("Starting Packet Forwarder Container")

# # Sentry Diagnostics Code
# sentry_key = os.getenv('SENTRY_PKTFWD')
# if(sentry_key):
#     balena_id = os.getenv('BALENA_DEVICE_UUID')
#     balena_app = os.getenv('BALENA_APP_NAME')
#     sentry_sdk.init(sentry_key, environment=balena_app)
#     sentry_sdk.set_user({"id": balena_id})


# with open("/var/pktfwd/diagnostics", 'w') as diagOut:
#     diagOut.write("true")

# print("Frequency Checking")

# regionID = None
# while(regionID is None):
#     # While no region specified

#     # Check to see if there is a region override
#     try:
#         regionOverride = str(os.environ['REGION_OVERRIDE'])
#         if(regionOverride):
#             regionID = regionOverride
#             break
#     except KeyError:
#         print("No Region Override Specified")

#     # Otherwise get region from miner
#     try:
#         with open("/var/pktfwd/region", 'r') as regionOut:
#             regionFile = regionOut.read()

#             if(len(regionFile) > 3):
#                 print("Frequency: " + str(regionFile))
#                 regionID = str(regionFile).rstrip('\n')
#                 break
#         print("Invalid Contents")
#         sleep(30)
#         print("Try loop again")
#     except FileNotFoundError:
#         print("File Not Detected, Sleeping")
#         sleep(60)


# # Start the Module

# print("Starting Module")
# print("Sleeping 5 seconds")
# sleep(5)

# # Region dictionary
# regionList = {
#     "AS923_1": "AS923-1-global_conf.json",
#     "AS923_2": "AS923-2-global_conf.json",
#     "AS923_3": "AS923-3-global_conf.json",
#     "AS923_4": "AS923-4-global_conf.json",
#     "AU915": "AU-global_conf.json",
#     "CN470": "CN-global_conf.json",
#     "EU868": "EU-global_conf.json",
#     "IN865": "IN-global_conf.json",
#     "KR920": "KR-global_conf.json",
#     "RU864": "RU-global_conf.json",
#     "US915": "US-global_conf.json"
# }

# # Configuration function


# def writeRegionConfSx1301(regionId):
#     regionconfFile = "/opt/iotloragateway/packet_forwarder/sx1301/lora_templates_sx1301/"+regionList[regionId]
#     with open(regionconfFile) as regionconfJFile:
#         newGlobal = json.load(regionconfJFile)
#     globalPath = "/opt/iotloragateway/packet_forwarder/sx1301/global_conf.json"

#     with open(globalPath, 'w') as jsonOut:
#         json.dump(newGlobal, jsonOut)


# def writeRegionConfSx1302(regionId, spi_bus):
#     # Writes the configuration files
#     regionconfFile = "/opt/iotloragateway/packet_forwarder/sx1302/lora_templates_sx1302/"+regionList[regionId]
#     with open(regionconfFile) as regionconfJFile:
#         newGlobal = json.load(regionconfJFile)

#     # Inject SPI Bus
#     newGlobal['SX130x_conf']['spidev_path'] = "/dev/%s" % spi_bus

#     globalPath = "/opt/iotloragateway/packet_forwarder/sx1302/packet_forwarder/global_conf.json"

#     with open(globalPath, 'w') as jsonOut:
#         json.dump(newGlobal, jsonOut)


# # Log the amount of times it has failed starting
# failTimes = 0

# # Write the correct reset pin to sx1302 reset

# gpioResetSED = "s/SX1302_RESET_PIN=../SX1302_RESET_PIN={}/g".format(reset_pin)
# subprocess.run(["/bin/sed", "-i", gpioResetSED, "/opt/iotloragateway/packet_forwarder/reset_lgw.sh"])  # nosec (B603)

# while True:

#     euiPATH = ["/opt/iotloragateway/packet_forwarder/sx1302/util_chip_id/chip_id", "-d", "/dev/{}".format(spi_bus)]
#     euiTest = subprocess.run(euiPATH, capture_output=True, text=True).stdout  # nosec (B603)

#     print("Starting")

#     sleep(2)

#     if "concentrator EUI:" in euiTest:
#         print("SX1302")
#         print("Frequency " + regionID)
#         writeRegionConfSx1302(regionID, spi_bus)
#         subprocess.run("/opt/iotloragateway/packet_forwarder/sx1302/packet_forwarder/lora_pkt_fwd")  # nosec (B603)
#         print("Software crashed, restarting")
#         failTimes += 1

#     else:
#         print("SX1301")
#         print("Frequency " + regionID)
#         writeRegionConfSx1301(regionID)
#         subprocess.run("/opt/iotloragateway/packet_forwarder/sx1301/lora_pkt_fwd_{}".format(spi_bus))  # nosec (B603)
#         print("Software crashed, restarting")
#         failTimes += 1

#     if(failTimes == 5):
#         with open("/var/pktfwd/diagnostics", 'w') as diagOut:
#             diagOut.write("false")

# Sleep forever
