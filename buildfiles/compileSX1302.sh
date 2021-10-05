#! /bin/bash

cd /opt/iotloragateway/dev || exit

wget https://github.com/NebraLtd/sx1302_hal/archive/V2.1.0.tar.gz
tar -xzvf V2.1.0.tar.gz

cd /opt/iotloragateway/dev/sx1302_hal-2.1.0 || exit

#Remove old files

rm libloragw/inc/loragw_stts751.h -f
rm libloragw/src/loragw_stts751.c -f
rm libloragw/inc/loragw_ad5338r.h -f
rm libloragw/src/loragw_ad5338r.c -f

#Copy new files
cp ../sx1302fixes/loragw_hal.c libloragw/src/loragw_hal.c -f
cp ../sx1302fixes/Makefile libloragw/Makefile -f
cp  ../sx1302fixes/lora_pkt_fwd.c packet_forwarder/src/lora_pkt_fwd.c
cp ../sx1302fixes/test_loragw_gps_uart.c libloragw/tst/test_loragw_gps.c -f
cp ../sx1302fixes/test_loragw_gps_i2c.c libloragw/tst/test_loragw_gps_i2c.c -f

make clean
make -j 4
