#! /bin/bash

mkdir -p /opt/iotloragateway
mkdir -p /opt/iotloragateway/dev
cd /opt/iotloragateway/dev || exit

git clone https://github.com/NebraLtd/lora_gateway.git
git clone https://github.com/NebraLtd/packet_forwarder.git

echo "Compiling for $1"

cd /opt/iotloragateway/dev/lora_gateway/libloragw || exit
sed -i 's/spidev0.0/$1/g' src/loragw_spi.native.c
make clean
make -j 4


cd /opt/iotloragateway/dev/packet_forwarder/ || exit
make clean
make -j 4

cp -R /opt/iotloragateway/dev/packet_forwarder/lora_pkt_fwd/lora_pkt_fwd /opt/iotloragateway/packetforwarder/lora_pkt_fwd_$1
