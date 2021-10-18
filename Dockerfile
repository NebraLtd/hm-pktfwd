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
        python3=3.7.3-1 \
        python3-pip=18.1-5+rpt1 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy python dependencies for `pip3 install` later
COPY requirements.txt requirements.txt

RUN pip3 install --target="$OUTPUT_DIR" --no-cache-dir -r requirements.txt
# TODO remove once published
RUN pip3 install setuptools wheel
RUN pip3 install --target="$OUTPUT_DIR" git+https://github.com/NebraLtd/hm-pyhelper@marvinmarnold/fix-logger-packaging --upgrade --no-cache-dir

###################################################################################################
################################## Stage: runner ##################################################
FROM balenalib/raspberry-pi-debian:buster-run as pktfwd-runner

ENV ROOT_DIR=/opt

# Copy from: Locations of build assets within images of earlier stages
ENV SX1301_LORA_GATEWAY_OUTPUT_RESET_LGW_FILEPATH=/opt/output/reset_lgw.sh
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

WORKDIR "$ROOT_DIR"

# Copy python app
COPY pktfwd/ "$PYTHON_APP_DIR"

# Copy sx1301 lora_pkt_fwd_SPI_BUS
COPY --from=nebraltd/packet_forwarder:83fd72d2db4c69faffd387d757452cbe9d594a08 "$SX1301_PACKET_FORWARDER_OUTPUT_DIR" "$SX1301_DIR"

# Copy sx1301 reset_lgw.sh
COPY --from=nebraltd/lora_gateway:9c4b1d0c79645c3065aa4c2f3019c14da6cb2675 "$SX1301_LORA_GATEWAY_OUTPUT_RESET_LGW_FILEPATH" "$SX1301_RESET_LGW_FILEPATH"

# Copy sx1302 chip_id, reset_lgw, and lora_pkt_fwd
COPY --from=nebraltd/sx1302_hal:3d73e6af43535f700ff7b6c2b49cc79d388cd70f "$SX1302_HAL_OUTPUT_DIR" "$SX1302_DIR"

# Copy pktfwd python app dependencies
COPY --from=pktfwd-builder "$PKTFWD_BUILDER_OUTPUT_DIR" "$PYTHON_DEPENDENCIES_DIR"

# hadolint ignore=DL3008
# Install python3 then cleanup
RUN apt-get update && \
    apt-get -y install --no-install-recommends python3=3.7.3-1 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add python dependencies to PYTHONPATH
ENV PYTHONPATH="${PYTHONPATH}:${PYTHON_DEPENDENCIES_DIR}"

# Run pktfwd/__main__.py
ENTRYPOINT ["python3", "pktfwd"]
