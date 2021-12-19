# Packet Forwarder Docker File
# (C) Nebra Ltd 2021
# Licensed under the MIT License.

####################################################################################################
########################### Stage: PktFwd Python App Builder #######################################
FROM balenalib/raspberry-pi-debian-python:buster-build-20211014 as pktfwd-builder

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
FROM balenalib/raspberry-pi-debian-python:buster-run-20211014 as pktfwd-runner

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
COPY --from=nebraltd/packet_forwarder:b0e1c24414e1564a1d01328b2109e1accb181f97 "$SX1301_PACKET_FORWARDER_OUTPUT_DIR" "$SX1301_DIR"

# Copy sx1302 chip_id, reset_lgw, and lora_pkt_fwd
# hadolint ignore=DL3022
COPY --from=nebraltd/sx1302_hal:9a72ce59c22b0434bdbaf9091542a7d8419bddee "$SX1302_HAL_OUTPUT_DIR" "$SX1302_DIR"

# Copy pktfwd python app dependencies
COPY --from=pktfwd-builder "$PKTFWD_BUILDER_OUTPUT_DIR" "$PYTHON_DEPENDENCIES_DIR"

# Cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add python dependencies to PYTHONPATH
ENV PYTHONPATH="${PYTHONPATH}:${PYTHON_DEPENDENCIES_DIR}"

# Run pktfwd/__main__.py
ENTRYPOINT ["python3", "pktfwd"]
