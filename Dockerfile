# Packet Forwarder Docker File
# (C) Nebra Ltd 2019
# Licensed under the MIT License.

####################################################################################################
################################## Stage: SX1301 Builder ###########################################
FROM balenalib/raspberry-pi-debian:buster-build as sx1301-builder

ENV INPUTS_PATH=/opt/inputs
ENV INPUT_UPSTREAM_LORA_GATEWAY_PATH="$INPUTS_PATH/lora_gateway"
ENV INPUT_UPSTREAM_PACKET_FORWARDER_PATH="$INPUTS_PATH/packet_forwarder"

##
ENV OUTPUTS_PATH=/opt/outputs/packet_forwarder
ENV OUTPUT_SX1301_PATH="$OUTPUTS_PATH/sx1301"
##

WORKDIR "$INPUTS_PATH"
RUN echo "Switched to ${INPUTS_PATH}"

COPY build/ "$INPUTS_PATH/"

RUN . "$INPUTS_PATH/build_for_sx1301.sh"

####################################################################################################
################################## Stage: SX1301 Builder ###########################################
FROM balenalib/raspberry-pi-debian:buster-build as python-builder

ENV INPUTS_PATH=/opt/inputs
ENV OUTPUTS_PATH=/opt/outputs/pktfwd
WORKDIR "$INPUTS_PATH"

# Install build tools
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        python3 \
        python3-pip

# Copy python dependencies for `pip install` later
COPY requirements.txt requirements.txt
RUN pip3 install --target="$OUTPUTS_PATH" --no-cache-dir -r requirements.txt

###################################################################################################
################################## Stage: runner ##################################################
FROM balenalib/raspberry-pi-debian:buster-build as runner

ENV BUILD_OUTPUTS_PATH=/opt/outputs/packet_forwarder
ENV OUTPUT_SX1301_PATH="$OUTPUTS_PATH/sx1301"

##
# ENV OUTPUTS_PATH=/opt/outputs/packet_forwarder
# ENV OUTPUT_SX1301_PATH="$OUTPUTS_PATH/sx1301"
# VARIANT = os.environ['VARIANT']
ENV SX1301_REGION_CONFIGS_PATH=/opt/pktfwd/config/lora_templates_sx1301
ENV SX1302_REGION_CONFIGS_PATH=/opt/pktfwd/config/lora_templates_sx1302
# UTIL_CHIP_ID_FILEPATH = os.environ['UTIL_CHIP_ID_FILEPATH'] # '/opt/iotloragateway/packet_forwarder/sx1302/util_chip_id/chip_id')
# RESET_LGW_FILEPATH = os.environ['RESET_LGW_FILEPATH']
# SX1302_LORA_PKT_FWD_FILEPATH = os.environ['SX1302_LORA_PKT_FWD_FILEPATH']
# SX1301_LORA_PKT_FWD_DIR = os.environ['SX1301_LORA_PKT_FWD_DIR']
##

# ENV BUILD_OUTPUT_PATH=/opt/packet_forwarder
WORKDIR /opt/

# Copy python app
COPY pktfwd/* pktfwd/

# Copy reset_lgw and util_chip_id scripts
COPY --from=sx1301-builder "$BUILD_OUTPUT_PATH" "$BUILD_OUTPUT_PATH"

# # hadolint ignore=DL3008
# RUN apt update && \
#     apt install python3 && \
#     apt-get autoremove -y && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*


# # Copy sx1301 & sx1302 packet_forwader from builder
# COPY --from=builder "$BUILD_OUTPUT_PATH" "$BUILD_OUTPUT_PATH"

# # TODO COPY PYTHON SITE-PACKAGES

# # Run run_pkt script
# # ENTRYPOINT ["python3", "/opt/pktfwd"]
# # ENTRYPOINT ["/bin/bash"]
# CMD while true; do sleep 1000; done

# ENV BUILD_INPUT_PKTFWD_APP_PATH="$BUILD_INPUTS_PATH/pktfwd"
# ENV BUILD_INPUT_SX1301_CONFIG_PATH="$BUILD_INPUTS_PATH/pktfwd/config/lora_templates_sx1301"
# # TODO switch back to EU default
# ENV BUILD_INPUT_SX1301_GLOBAL_CONFIG_FILENAME="US-global_conf.json"


# # Script that reads from $BUILD_INPUTS_PATH and exports to BUILD_OUTPUT_PATH
# ENV BUILD_SCRIPT_PATH="$BUILD_INPUTS_PATH/build_all_sx130x_variants.sh"

# # Move to correct working directory


# RUN pip3 install --no-cache-dir -r requirements.txt

# # Copy the upstream code, build files, and sx1302 fixes
# COPY build/ "$BUILD_INPUTS_PATH/"
# COPY pktfwd/ "$BUILD_INPUT_PKTFWD_APP_PATH/"

# # Installs to /opt/packet_forwarder
# RUN "$BUILD_SCRIPT_PATH"

# # No need to cleanup the builder

