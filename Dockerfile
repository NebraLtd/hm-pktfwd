# Packet Forwarder Docker File
# (C) Nebra Ltd 2021
# Licensed under the MIT License.

####################################################################################################
################################## Stage: SX1301 Builder ###########################################
FROM balenalib/raspberry-pi-debian:buster-build as sx1301-builder

ENV INPUTS_DIR=/opt/inputs
ENV INPUT_UPSTREAM_LORA_GATEWAY_DIR="$INPUTS_DIR/lora_gateway"
ENV INPUT_UPSTREAM_PACKET_FORWARDER_DIR="$INPUTS_DIR/packet_forwarder"

##
ENV OUTPUTS_DIR=/opt/outputs
ENV OUTPUT_SX1301_DIR="$OUTPUTS_DIR/sx1301"
ENV OUTPUT_SX1301_RESET_LGW_FILEPATH="$OUTPUT_SX1301_DIR/reset_lgw.sh"
##

WORKDIR "$INPUTS_DIR"
RUN echo "Switched to ${INPUTS_DIR}"

COPY build/ "$INPUTS_DIR/"

RUN . "$INPUTS_DIR/build_for_sx1301.sh"

COPY sleep.sh sleep.sh
ENTRYPOINT ["sh", "sleep.sh"]

####################################################################################################
################################## Stage: SX1301 Builder ###########################################
FROM balenalib/raspberry-pi-debian:buster-build as pktfwd-builder

ENV INPUTS_DIR=/opt/inputs
ENV OUTPUTS_DIR=/opt/outputs/pktfwd-dependencies
WORKDIR "$INPUTS_DIR"

# Install build tools
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        python3 \
        python3-pip

# Copy python dependencies for `pip install` later
COPY requirements.txt requirements.txt

RUN pip3 install --target="$OUTPUTS_DIR" -r requirements.txt
# TODO remove once published
RUN pip3 install setuptools wheel
RUN pip3 install --target="$OUTPUTS_DIR" git+https://github.com/NebraLtd/hm-pyhelper@marvinmarnold/releases

COPY sleep.sh sleep.sh
ENTRYPOINT ["sh", "sleep.sh"]

###################################################################################################
################################## Stage: runner ##################################################
FROM balenalib/raspberry-pi-debian:buster-run as pktfwd-runner

ENV ROOT_DIR=/opt
ENV PYTHON_APP_DIR="$ROOT_DIR/pktfwd"

# ENV SX1301_BUILDER_OUTPUTS_DIR=/opt/outputs/packet_forwarder
ENV SX1301_BUILDER_OUTPUTS_DIR=/opt/outputs/sx1301
ENV SX1301_BUILDER_OUTPUT_RESET_LGW_FILEPATH="$SX1301_BUILDER_OUTPUTS_DIR/reset_lgw.sh"
ENV PKTFWD_BUILDER_OUTPUTS_DIR=/opt/outputs/pktfwd-dependencies

##
# VARIANT = os.environ['VARIANT']
ENV SX1301_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1301"
ENV SX1302_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1302"
# os.environ['UTIL_CHIP_ID_FILEPATH'] # '/opt/iotloragateway/packet_forwarder/sx1302/util_chip_id/chip_id')
ENV UTIL_CHIP_ID_FILEPATH=TODO
# os.environ['SX1302_LORA_PKT_FWD_FILEPATH']
ENV SX1302_LORA_PKT_FWD_FILEPATH=TODO
ENV SX1301_LORA_PKT_FWD_DIR="$ROOT_DIR/sx1301"
ENV RESET_LGW_FILEPATH="$SX1301_LORA_PKT_FWD_DIR/reset_lgw.sh"
##

WORKDIR "$ROOT_DIR"

# Copy python app
COPY pktfwd/ "$PYTHON_APP_DIR"

# Copy upstream lora_pkt_fwd, reset_lgw, and util_chip_id scripts
COPY --from=sx1301-builder "$SX1301_BUILDER_OUTPUTS_DIR" "$ROOT_DIR/sx1301"

# Copy pktfwd python app dependencies
COPY --from=pktfwd-builder "$PKTFWD_BUILDER_OUTPUTS_DIR" "$ROOT_DIR/pktfwd-dependencies"

# # hadolint ignore=DL3008
RUN apt update && \
    apt install python3 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PYTHONPATH="${PYTHONPATH}:$ROOT_DIR/pktfwd-dependencies"
# ENTRYPOINT ["python3", "pktfwd"]
CMD while true; do sleep 1000; done

# # Copy sx1301 & sx1302 packet_forwader from builder
# COPY --from=builder "$BUILD_OUTPUT_DIR" "$BUILD_OUTPUT_DIR"


# # Run run_pkt script
# # ENTRYPOINT ["python3", "/opt/pktfwd"]
# # ENTRYPOINT ["/bin/bash"]

# ENV BUILD_INPUT_PKTFWD_APP_DIR="$BUILD_INPUTS_DIR/pktfwd"
# ENV BUILD_INPUT_SX1301_CONFIG_DIR="$BUILD_INPUTS_DIR/pktfwd/config/lora_templates_sx1301"
# # TODO switch back to EU default
# ENV BUILD_INPUT_SX1301_GLOBAL_CONFIG_FILENAME="US-global_conf.json"


# # Script that reads from $BUILD_INPUTS_DIR and exports to BUILD_OUTPUT_DIR
# ENV BUILD_SCRIPT_DIR="$BUILD_INPUTS_DIR/build_all_sx130x_variants.sh"

# # Move to correct working directory


# RUN pip3 install --no-cache-dir -r requirements.txt

# # Copy the upstream code, build files, and sx1302 fixes
# COPY build/ "$BUILD_INPUTS_DIR/"
# COPY pktfwd/ "$BUILD_INPUT_PKTFWD_APP_DIR/"

# # Installs to /opt/packet_forwarder
# RUN "$BUILD_SCRIPT_DIR"

# # No need to cleanup the builder

