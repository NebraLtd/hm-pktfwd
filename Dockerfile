#Packet Forwarder Docker File
#(C) Pi Supply 2019
#Licensed under the GNU GPL V3 License.
FROM arm32v5/debian:buster-slim AS buildstep
WORKDIR /opt/iotloragateway/dev

RUN apt-get update && apt-get -y install \
  automake=1:1.16.1-4 \
  libtool=2.4.6-9 \
  autoconf=2.69-11 \
  git=1:2.20.1-2+deb10u3 \
  ca-certificates=20200601~deb10u2 \
  pkg-config=0.29-6 \
  build-essential=12.6 \
  wget=1.20.1-1.1 \
  --no-install-recommends

COPY buildfiles buildfiles
COPY sx1302fixes sx1302fixes

ARG moo=2


RUN mkdir -p /opt/iotloragateway
RUN mkdir -p /opt/iotloragateway/dev
RUN mkdir -p /opt/iotloragateway/packetforwarder
RUN cd /opt/iotloragateway/dev || exit

RUN git clone https://github.com/NebraLtd/lora_gateway.git
RUN git clone https://github.com/NebraLtd/packet_forwarder.git

RUN chmod +x ./buildfiles/compileSX1301.sh
RUN ./buildfiles/compileSX1301.sh spidev0.0
RUN ./buildfiles/compileSX1301.sh spidev0.1
RUN ./buildfiles/compileSX1301.sh spidev1.0
RUN ./buildfiles/compileSX1301.sh spidev1.1
RUN ./buildfiles/compileSX1301.sh spidev1.2
RUN ./buildfiles/compileSX1301.sh spidev2.0
RUN ./buildfiles/compileSX1301.sh spidev2.1
RUN ./buildfiles/compileSX1301.sh spidev32766.0
RUN ls /opt/iotloragateway/packetforwarder/


RUN chmod +x ./buildfiles/compileSX1302.sh
RUN ./buildfiles/compileSX1302.sh

FROM arm32v5/debian:buster-slim

WORKDIR /opt/iotloragateway/packet_forwarder/sx1301

RUN apt-get update && \
apt-get -y install \
python3=3.7.3-1 \
python3-rpi.gpio=0.6.5-1 \
python3-pip=18.1-5 \
--no-install-recommends && \
pip3 install sentry-sdk==1.0.0 &&\
apt-get purge python3-pip -y &&\
apt-get autoremove -y &&\
apt-get clean && \
rm -rf /var/lib/apt/lists/*



COPY --from=buildstep /opt/iotloragateway/packetforwarder .

COPY lora_templates_sx1301 lora_templates_sx1301/


RUN cp lora_templates_sx1301/local_conf.json local_conf.json
RUN cp lora_templates_sx1301/EU-global_conf.json global_conf.json

RUN chmod 777 ./local_conf.json
#RUN chmod +x ./packet_forwarder

WORKDIR /opt/iotloragateway/packet_forwarder/sx1302

COPY --from=buildstep /opt/iotloragateway/dev/sx1302_hal-1.0.5 .
WORKDIR /opt/iotloragateway/packet_forwarder/sx1302/util_chip_id
COPY files/reset_lgw.sh .
RUN chmod +x reset_lgw.sh

WORKDIR /opt/iotloragateway/packet_forwarder/sx1302/
COPY lora_templates_sx1302 lora_templates_sx1302/

RUN cp lora_templates_sx1302/local_conf.json packet_forwarder/local_conf.json
RUN cp lora_templates_sx1302/EU-global_conf.json packet_forwarder/global_conf.json


WORKDIR /opt/iotloragateway/packet_forwarder

COPY files/run_pkt.sh .
COPY files/configurePktFwd.py .
COPY files/reset-v2.sh .
RUN chmod +x reset-v2.sh
RUN chmod +x run_pkt.sh
RUN chmod +x configurePktFwd.py
COPY files/reset_lgw.sh .
RUN chmod +x reset_lgw.sh


ENTRYPOINT ["sh", "/opt/iotloragateway/packet_forwarder/run_pkt.sh"]
