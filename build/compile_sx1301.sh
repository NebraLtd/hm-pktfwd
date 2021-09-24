#!/usr/bin/env sh

# cd "$BUILD_INPUTS_PATH/lora_gateway/libloragw" || exit
# rm src/loragw_spi.native.c
# cp src/loragw_spi.native.c.template src/loragw_spi.native.c
# sed -i "s/spidev0.0/$1/g" src/loragw_spi.native.c
# make clean
# make -j 4


cd "$BUILD_INPUTS_PATH/packet_forwarder/" || exit
make clean
make -j 4

cp -R "$BUILD_INPUTS_PATH/packet_forwarder/lora_pkt_fwd/lora_pkt_fwd" "$BUILD_OUTPUT_PATH/lora_pkt_fwd_$1"
