# Packet Forwarder Docker File
# (C) Nebra Ltd 2019
# Licensed under the MIT License.

####################################################################################################
################################## Stage: builder ##################################################
FROM balenalib/raspberry-pi-debian:buster-build as builder

ENV BUILD_INPUTS_PATH=/opt/build
ENV BUILD_INPUT_PKTFWD_APP_PATH="$BUILD_INPUTS_PATH/pktfwd"
ENV BUILD_INPUT_SX1301_CONFIG_PATH="$BUILD_INPUTS_PATH/pktfwd/config/lora_templates_sx1301"
# TODO switch back to EU default
ENV BUILD_INPUT_SX1301_GLOBAL_CONFIG_FILENAME="US-global_conf.json"
ENV BUILD_INPUT_UPSTREAM_LORA_GATEWAY_PATH="$BUILD_INPUTS_PATH/lora_gateway"
ENV BUILD_INPUT_UPSTREAM_PACKET_FORWARDER_PATH="$BUILD_INPUTS_PATH/packet_forwarder"

ENV BUILD_OUTPUTS_PATH=/opt/packet_forwarder
ENV BUILD_OUTPUT_SX1301_PATH="$BUILD_OUTPUTS_PATH/sx1301"

# Script that reads from $BUILD_INPUTS_PATH and exports to BUILD_OUTPUT_PATH
ENV BUILD_SCRIPT_PATH="$BUILD_INPUTS_PATH/build_all_sx130x_variants.sh"

ENV DEBUG_HAL=1

# Move to correct working directory
WORKDIR "$BUILD_INPUTS_PATH"

# Copy python dependencies for `pip install` later
COPY requirements.txt requirements.txt

# Install build tools
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        automake \
        libtool \
        autoconf \
        git \
        ca-certificates \
        pkg-config \
        build-essential \
        python3 \
        python3-pip

RUN pip3 install --no-cache-dir -r requirements.txt

# Copy the upstream code, build files, and sx1302 fixes
COPY build/ "$BUILD_INPUTS_PATH/"
COPY pktfwd/ "$BUILD_INPUT_PKTFWD_APP_PATH/"

# Installs to /opt/packet_forwarder
RUN "$BUILD_SCRIPT_PATH"

# No need to cleanup the builder

####################################################################################################
################################### Stage: runner ##################################################

FROM balenalib/raspberry-pi-debian:buster-run as runner

ENV BUILD_OUTPUT_PATH=/opt/packet_forwarder
WORKDIR /opt/

# hadolint ignore=DL3008
RUN apt update && \
    apt install python3 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY pktfwd/* pktfwd/

# Copy sx1301 packetforwader from builder
COPY --from=builder "$BUILD_OUTPUT_PATH" "$BUILD_OUTPUT_PATH"

# TODO COPY PYTHON SITE-PACKAGES

# Run run_pkt script
# ENTRYPOINT ["python3", "/opt/pktfwd"]
# ENTRYPOINT ["/bin/bash"]
CMD while true; do sleep 1000; done