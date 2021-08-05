# Packet Forwarder Docker File
# (C) Nebra Ltd 2019
# Licensed under the MIT License.

####################################################################################################
################################## Stage: builder ##################################################

FROM balenalib/raspberry-pi-debian:buster-build as builder

# Move to correct working directory
WORKDIR /opt/iotloragateway/dev

# This will be the path that venv uses for installation below
ENV PATH="/opt/iotloragateway/dev/venv/bin:$PATH"

# Install build tools
RUN \
    apt-get update && \
        apt-get -y install \
            automake=1:1.16.1-4 \
            libtool=2.4.6-9 \
            autoconf=2.69-11 \
            git=1:2.20.1-2+deb10u3 \
            ca-certificates=20200601~deb10u2 \
            pkg-config=0.29-6 \
            build-essential=12.6 \
            python3=3.7.3-1 \
            python3-pip=18.1-5+rpt1 \
            python3-venv=3.7.3-1 \
            --no-install-recommends && \
    # Because the PATH is already updated above, this command creates a new venv AND activates it
    python3 -m venv /opt/iotloragateway/dev/venv && \
    # Given venv is active, this `pip` refers to the python3 variant
    pip install --no-cache-dir sentry-sdk==1.1.0

# Copy the buildfiles and sx1302 concentrator fixes
COPY buildfiles buildfiles
COPY sx1302fixes sx1302fixes

# Clone the lora gateway and packet forwarder repos
RUN git clone https://github.com/NebraLtd/lora_gateway.git
RUN git clone https://github.com/NebraLtd/packet_forwarder.git

# Create folder needed by packetforwarder compiler
RUN mkdir -p /opt/iotloragateway/packetforwarder

# Compile for sx1301 concentrator on all the necessary SPI buses
RUN ./buildfiles/compileSX1301.sh spidev0.0
RUN ./buildfiles/compileSX1301.sh spidev0.1
RUN ./buildfiles/compileSX1301.sh spidev1.0
RUN ./buildfiles/compileSX1301.sh spidev1.1
RUN ./buildfiles/compileSX1301.sh spidev1.2
RUN ./buildfiles/compileSX1301.sh spidev2.0
RUN ./buildfiles/compileSX1301.sh spidev2.1
RUN ./buildfiles/compileSX1301.sh spidev32766.0

# Compile for sx1302 concentrator
RUN ./buildfiles/compileSX1302.sh

# No need to cleanup the builder

####################################################################################################
################################### Stage: runner ##################################################

FROM balenalib/raspberry-pi-debian:buster-run as runner

# Start in sx1301 directory
WORKDIR /opt/iotloragateway/packet_forwarder/sx1301

# Install python3-venv and python3-rpi.gpio
RUN \
    apt-get update && \
        apt-get -y install \
            python3-venv=3.7.3-1 \
            python3-rpi.gpio=0.7.0-0.1~bpo10+4

# Copy sx1301 packetforwader from builder
COPY --from=builder /opt/iotloragateway/packetforwarder .

# Copy sx1301 regional config templates
COPY lora_templates_sx1301 lora_templates_sx1301/

# Use EU config as initial default
COPY lora_templates_sx1301/local_conf.json local_conf.json
COPY lora_templates_sx1301/EU-global_conf.json global_conf.json

# Move to sx1302 directory
WORKDIR /opt/iotloragateway/packet_forwarder/sx1302

# Copy sx1302 hal from builder
COPY --from=builder /opt/iotloragateway/dev/sx1302_hal-1.0.5 .

# Copy sx1302 regional config templates
COPY lora_templates_sx1302 lora_templates_sx1302/

# Use EU config as initial default
COPY lora_templates_sx1302/local_conf.json packet_forwarder/local_conf.json
COPY lora_templates_sx1302/EU-global_conf.json packet_forwarder/global_conf.json

# Move to main packet forwarder directory and copy source code
WORKDIR /opt/iotloragateway/packet_forwarder
COPY files/* .

# Copy lib folder
COPY lib lib

# Copy venv from builder and update PATH to activate it
COPY --from=builder /opt/iotloragateway/dev/venv /opt/iotloragateway/dev/venv
ENV PATH="/opt/iotloragateway/dev/venv/bin:$PATH"

# Cleanup
RUN apt-get autoremove -y &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Run run_pkt script
ENTRYPOINT ["sh", "/opt/iotloragateway/packet_forwarder/run_pkt.sh"]
