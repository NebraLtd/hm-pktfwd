#! /bin/bash
echo "Compiling for $1"

cd /opt/iotloragateway/dev/lora_gateway/libloragw || exit
rm src/loragw_spi.native.c
cp src/loragw_spi.native.c.template src/loragw_spi.native.c
sed -i "s/spidev0.0/$1/g" src/loragw_spi.native.c
make clean
make -j 4


cd /opt/iotloragateway/dev/packet_forwarder/ || exit
make clean
make -j 4

cp -R "/opt/iotloragateway/dev/packet_forwarder/lora_pkt_fwd/lora_pkt_fwd" "/opt/iotloragateway/packetforwarder/lora_pkt_fwd_$1"
