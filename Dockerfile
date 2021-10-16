# Packet Forwarder Docker File
# (C) Nebra Ltd 2021
# Licensed under the MIT License.

####################################################################################################
########################### Stage: PktFwd Python App Builder #######################################
FROM balenalib/raspberry-pi-debian:buster-build as pktfwd-builder

# Variables used internally to this stage
ENV INPUT_DIR=/opt/input

# Variables to be referenced pktfwd-runner stage
ENV OUTPUT_DIR=/opt/output/pktfwd-dependencies

WORKDIR "$INPUT_DIR"

# Install python3 and pip3
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        python3 \
        python3-pip

# Copy python dependencies for `pip3 install` later
COPY requirements.txt requirements.txt

RUN pip3 install --target="$OUTPUT_DIR" -r requirements.txt
# TODO remove once published
RUN pip3 install setuptools wheel
RUN pip3 install --target="$OUTPUT_DIR" git+https://github.com/NebraLtd/hm-pyhelper@marvinmarnold/releases

###################################################################################################
################################## Stage: runner ##################################################
FROM balenalib/raspberry-pi-debian:buster-run as pktfwd-runner

ENV ROOT_DIR=/opt

# Copy from: Locations of build assets within images of earlier stages
ENV SX1301_LORA_GATEWAY_OUTPUT_RESET_LGW_FILEPATH=/opt/output/reset_lgw.sh
ENV SX1301_PACKET_FORWARDER_OUTPUT_DIR=/opt/output
# ENV SX1301_BUILDER_OUTPUTS_DIR=/opt/outputs/sx1301
# ENV SX1301_BUILDER_OUTPUT_RESET_LGW_FILEPATH="$SX1301_BUILDER_OUTPUTS_DIR/reset_lgw.sh"
ENV PKTFWD_BUILDER_OUTPUT_DIR=/opt/outputs/pktfwd-dependencies

# Copy to: Locations build assets from earlier stages/source are copied into
ENV PYTHON_APP_DIR="$ROOT_DIR/pktfwd"
ENV PYTHON_DEPENDENCIES_DIR="$ROOT_DIR/pktfwd-dependencies"

# Variables required for pktfwd python app
ENV SX1301_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1301"
ENV SX1302_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1302"
# os.environ['UTIL_CHIP_ID_FILEPATH'] # '/opt/iotloragateway/packet_forwarder/sx1302/util_chip_id/chip_id')
ENV UTIL_CHIP_ID_FILEPATH=TODO
# os.environ['SX1302_LORA_PKT_FWD_FILEPATH']
ENV SX1301_DIR="$ROOT_DIR/sx1301"
ENV SX1302_LORA_PKT_FWD_FILEPATH=TODO
ENV SX1301_RESET_LGW_FILEPATH="$SX1301_DIR/reset_lgw.sh"

WORKDIR "$ROOT_DIR"

# Copy python app
COPY pktfwd/ "$PYTHON_APP_DIR"

# Copy sx1301 lora_pkt_fwd_SPI_BUS
COPY --from=marvinnebra/packet_forwarder "$SX1301_PACKET_FORWARDER_OUTPUT_DIR" "$SX1301_DIR"

# Copy sx1301 reset_lgw.sh
COPY --from=marvinnebra/lora_gateway "$SX1301_LORA_GATEWAY_OUTPUT_RESET_LGW_FILEPATH" "$SX1301_RESET_LGW_FILEPATH"

# TODO: Copy HAL and chip ID

# Copy pktfwd python app dependencies
COPY --from=pktfwd-builder "$PKTFWD_BUILDER_OUTPUTS_DIR" "$PYTHON_DEPENDENCIES_DIR"

# hadolint ignore=DL3008
# Install python3 then cleanup
RUN apt update && \
    apt install python3 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add python dependencies to PYTHONPATH
ENV PYTHONPATH="${PYTHONPATH}:${PYTHON_DEPENDENCIES_DIR}"

# Run pktfwd/__main__.py
ENTRYPOINT ["python3", "pktfwd"]
