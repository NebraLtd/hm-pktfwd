# Packet Forwarder Docker File
# (C) Nebra Ltd 2021
# Licensed under the MIT License.

####################################################################################################
################################## Stage: SX1301 Builder ###########################################
FROM balenalib/raspberry-pi-debian:buster-build as sx1301-builder

# Variables used internally to this stage
ENV INPUTS_DIR=/opt/inputs
ENV INPUT_UPSTREAM_LORA_GATEWAY_DIR="$INPUTS_DIR/lora_gateway"
ENV INPUT_UPSTREAM_PACKET_FORWARDER_DIR="$INPUTS_DIR/packet_forwarder"
ENV SPI_SPEED=2000000

# Variables to be referenced pktfwd-runner stage
ENV OUTPUTS_DIR=/opt/outputs
ENV OUTPUT_SX1301_DIR="$OUTPUTS_DIR/sx1301"
ENV OUTPUT_SX1301_RESET_LGW_FILEPATH="$OUTPUT_SX1301_DIR/reset_lgw.sh"

WORKDIR "$INPUTS_DIR"

# Copy upstream source into expected location
COPY build/ "$INPUTS_DIR/"

RUN . "$INPUTS_DIR/build_for_sx1301.sh"

####################################################################################################
########################### Stage: PktFwd Python App Builder #######################################
FROM balenalib/raspberry-pi-debian:buster-build as pktfwd-builder

# Variables used internally to this stage
ENV INPUTS_DIR=/opt/inputs

# Variables to be referenced pktfwd-runner stage
ENV OUTPUTS_DIR=/opt/outputs/pktfwd-dependencies

WORKDIR "$INPUTS_DIR"

# Install python3 and pip3
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        python3 \
        python3-pip

# Copy python dependencies for `pip3 install` later
COPY requirements.txt requirements.txt

RUN pip3 install --target="$OUTPUTS_DIR" -r requirements.txt
# TODO remove once published
RUN pip3 install setuptools wheel
RUN pip3 install --target="$OUTPUTS_DIR" git+https://github.com/NebraLtd/hm-pyhelper@marvinmarnold/releases

###################################################################################################
################################## Stage: runner ##################################################
FROM balenalib/raspberry-pi-debian:buster-run as pktfwd-runner

ENV ROOT_DIR=/opt

# Copy from: Locations of build assets within images of earlier stages
ENV SX1301_BUILDER_OUTPUTS_DIR=/opt/outputs/sx1301
ENV SX1301_BUILDER_OUTPUT_RESET_LGW_FILEPATH="$SX1301_BUILDER_OUTPUTS_DIR/reset_lgw.sh"
ENV PKTFWD_BUILDER_OUTPUTS_DIR=/opt/outputs/pktfwd-dependencies

# Copy to: Locations build assets from earlier stages/source are copied into
ENV PYTHON_APP_DIR="$ROOT_DIR/pktfwd"
ENV PYTHON_DEPENDENCIES_DIR="$ROOT_DIR/pktfwd-dependencies"
ENV SX1301_FROM_UPSTREAM_DIR="$ROOT_DIR/sx1301"

# Variables required for pktfwd python app
ENV SX1301_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1301"
ENV SX1302_REGION_CONFIGS_DIR="$PYTHON_APP_DIR/config/lora_templates_sx1302"
# os.environ['UTIL_CHIP_ID_FILEPATH'] # '/opt/iotloragateway/packet_forwarder/sx1302/util_chip_id/chip_id')
ENV UTIL_CHIP_ID_FILEPATH=TODO
# os.environ['SX1302_LORA_PKT_FWD_FILEPATH']
ENV SX1302_LORA_PKT_FWD_FILEPATH=TODO
ENV SX1301_LORA_PKT_FWD_DIR="$SX1301_FROM_UPSTREAM_DIR"
ENV RESET_LGW_FILEPATH="$SX1301_LORA_PKT_FWD_DIR/reset_lgw.sh"

WORKDIR "$ROOT_DIR"

# Copy python app
COPY pktfwd/ "$PYTHON_APP_DIR"

# Copy upstream lora_pkt_fwd, reset_lgw, and util_chip_id scripts
COPY --from=sx1301-builder "$SX1301_BUILDER_OUTPUTS_DIR" "$SX1301_FROM_UPSTREAM_DIR"

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
ENV PYTHONPATH="${PYTHONPATH}:$PYTHON_DEPENDENCIES_DIR"

# Run pktfwd/__main__.py
ENTRYPOINT ["python3", "pktfwd"]
