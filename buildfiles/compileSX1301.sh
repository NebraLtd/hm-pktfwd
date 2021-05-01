#! /bin/bash

mkdir -p /opt/iotloragateway
mkdir -p /opt/iotloragateway/dev
cd /opt/iotloragateway/dev || exit

git clone https://github.com/NebraLtd/lora_gateway.git
git clone https://github.com/NebraLtd/packet_forwarder.git

cd /opt/iotloragateway/dev/lora_gateway/libloragw || exit
make clean
make -j 4

echo "Packet Forwarder"
cd /opt/iotloragateway/dev/packet_forwarder/ || exit
make clean
make -j 4

cp -R /opt/iotloragateway/dev/packet_forwarder/lora_pkt_fwd/ /opt/iotloragateway/packetforwarder/
