# Packet Forwarder Docker File
# (C) Nebra Ltd 2021
# Licensed under the MIT License.

ARG BUILD_BOARD
ARG BUILD_ARCH

# Set up correct image paths
ARG PKTFWD_PATH=nebraltd/packet_forwarder:$BUILD_ARCH-e1aca266845203824889cfcd869ea64de3129113
ARG SX1302_PATH=nebraltd/sx1302_hal:$BUILD_ARCH-3760434a18e6ba47b695c22786195e57cc6b4c1c

# Pull the builds for later use
# hadolint ignore=DL3006
FROM $SX1302_PATH AS sx1302_hal
# hadolint ignore=DL3006
FROM $PKTFWD_PATH AS packet_forwarder

####################################################################################################
########################### Stage: PktFwd Python App Builder #######################################
FROM balenalib/"$BUILD_BOARD"-debian-python:bullseye-build-20221215 AS pktfwd-builder

# Variables used internally to this stage
ENV INPUT_DIR=/opt/input

# Variables to be referenced pktfwd-runner stage
ENV OUTPUT_DIR=/opt/output/pktfwd-dependencies

WORKDIR "$INPUT_DIR"

# Copy python dependencies for `pip3 install` later
COPY requirements.txt requirements.txt

RUN pip3 install --target="$OUTPUT_DIR" --no-cache-dir -r requirements.txt

###################################################################################################
################################## Stage: runner ##################################################
FROM balenalib/"$BUILD_BOARD"-debian-python:bullseye-run-20221215 AS pktfwd-runner

ENV ROOT_DIR=/opt

# Copy from: Locations of build assets within images of earlier stages
ENV SX1301_PACKET_FORWARDER_OUTPUT_DIR=/opt/output
ENV SX1302_HAL_OUTPUT_DIR=/opt/output
ENV PKTFWD_BUILDER_OUTPUT_DIR=/opt/output/pktfwd-dependencies

# Copy to: Locations build assets from earlier stages/source are copied into
ENV SX1301_DIR="$ROOT_DIR/sx1301"
ENV SX1302_DIR="$ROOT_DIR/sx1302"
ENV PYTHON_APP_DIR="$ROOT_DIR/pktfwd"
ENV PYTHON_DEPENDENCIES_DIR="$ROOT_DIR/pktfwd-dependencies"
ENV SX1301_RESET_LGW_FILEPATH="$SX1301_DIR/reset_lgw.sh"

# Variables required for pktfwd python app
ENV SX1301_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1301"
ENV SX1302_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1302"
ENV SX1302_LORA_PKT_FWD_FILEPATH="$SX1302_DIR/lora_pkt_fwd"
ENV UTIL_CHIP_ID_FILEPATH="$SX1302_DIR/chip_id"
# The sx1302_hal concentrator script requires reset_lgw to be in this location
ENV RESET_LGW_FILEPATH="$ROOT_DIR/reset_lgw.sh"

WORKDIR "$ROOT_DIR"

# Copy python app
COPY pktfwd/ "$PYTHON_APP_DIR"

# Copy reset script
COPY reset_lgw.sh "$RESET_LGW_FILEPATH"

# Copy sx1301 lora_pkt_fwd_SPI_BUS
# hadolint ignore=DL3022
COPY --from=packet_forwarder "$SX1301_PACKET_FORWARDER_OUTPUT_DIR" "$SX1301_DIR"

# Copy sx1302 chip_id, reset_lgw, and lora_pkt_fwd
# hadolint ignore=DL3022
COPY --from=sx1302_hal "$SX1302_HAL_OUTPUT_DIR" "$SX1302_DIR"

# Copy pktfwd python app dependencies
COPY --from=pktfwd-builder "$PKTFWD_BUILDER_OUTPUT_DIR" "$PYTHON_DEPENDENCIES_DIR"

# Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/nebra

# Add python dependencies to PYTHONPATH
ENV PYTHONPATH="${PYTHONPATH}:${PYTHON_DEPENDENCIES_DIR}"

# Copy startup scripts
COPY start_pktfwd.sh /opt/start_pktfwd.sh
COPY setenv_pktfwd.sh /opt/nebra/setenv_pktfwd.sh

# Run pktfwd/__main__.py
ENTRYPOINT ["./start_pktfwd.sh"]
