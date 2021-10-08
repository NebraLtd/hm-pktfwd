#!/usr/bin/env sh

# BUILD_INPUT_SX1301_CONFIG_PATH
# BUILD_INPUT_UPSTREAM_LORA_GATEWAY_PATH
# BUILD_INPUT_UPSTREAM_PACKET_FORWARDER_PATH
# BUILD_OUTPUT_SX1301_PATH

# lora_pkt_fwd references lora_gateway
# https://github.com/Lora-net/packet_forwarder/blob/d0226eae6e7b6bbaec6117d0d2372bf17819c438/lora_pkt_fwd/Makefile#L7
compile_sx1301() {
    spi_bus="$1"
    echo "Compiling upstream lora_gateway/libloragw for $spi_bus"

    cd "$INPUT_UPSTREAM_LORA_GATEWAY_PATH/libloragw" || exit
    export SPI_DEV_PATH="/dev/$spi_bus"
    # sed -i "s|spidev0.0|$spi_bus|g" src/loragw_spi.native.c
    make clean
    make -j 4

    echo "Compiling upstream packet_forwarder/lora_pkt_fwd for $spi_bus"
    cd "$INPUT_UPSTREAM_PACKET_FORWARDER_PATH" || exit
    # Point the configs to the output path
    # sed -i "s|/opt/iotloragateway/packet_forwarder/sx1301|$OUTPUT_SX1301_PATH|g" lora_pkt_fwd/src/lora_pkt_fwd.c
   
    make clean
    make -j 4

    cp -R "$INPUT_UPSTREAM_PACKET_FORWARDER_PATH/lora_pkt_fwd/lora_pkt_fwd" "$OUTPUT_SX1301_PATH/lora_pkt_fwd_$spi_bus"
    echo "Finished building sx1301 for $spi_bus to $OUTPUT_SX1301_PATH"
}

# Build the upstream packet_frowarder for all spi interfaces on sx1301
compile_upstream_libs() {
    echo "Compiling for sx1301 concentrator on all the necessary SPI buses to $OUTPUT_SX1301_PATH"
    spi_buses=(spidev0.0 spidev0.1 spidev1.0 spidev1.1 spidev1.2 spidev2.0 spidev2.1 spidev032766.0)

    for spi_bus in "${spi_buses[@]}"
    do
    : 
        compile_sx1301 "$spi_bus"
    done
    # compile_sx1301 spidev0.0
    # compile_sx1301 spidev0.1
    # compile_sx1301 spidev1.0
    # compile_sx1301 spidev1.1
    # compile_sx1301 spidev1.2
    # compile_sx1301 spidev2.0
    # compile_sx1301 spidev2.1
    # compile_sx1301 spidev32766.0

    # Compile for sx1302 concentrator
    # RUN ./buildfiles/compile_sx1302.sh

    # COPY --from=builder /opt/packet_forwarder/sx1302_hal-1.0.5 ./sx1302
}

# Copy:
#   - $BUILD_INPUT_SX1301_CONFIG_PATH/local_conf.json => $BUILD_OUTPUT_SX1301_PATH/local_conf.json"
#   - $BUILD_INPUT_SX1301_CONFIG_PATH/$BUILD_INPUT_SX1301_GLOBAL_CONFIG_FILENAME => $BUILD_OUTPUT_SX1301_PATH/global_conf.json
copy_default_configs() {
    # Place default configs and use EU as initial default
    echo "Copying configs:\\n\\tFrom: $BUILD_INPUT_SX1301_CONFIG_PATH\\n\\tTo: $BUILD_OUTPUT_SX1301_PATH"

    cp "$BUILD_INPUT_SX1301_CONFIG_PATH/local_conf.json" "$BUILD_OUTPUT_SX1301_PATH/local_conf.json"
    cp "$BUILD_INPUT_SX1301_CONFIG_PATH/$BUILD_INPUT_SX1301_GLOBAL_CONFIG_FILENAME" "$BUILD_OUTPUT_SX1301_PATH/global_conf.json"

    # Copy sx1302 hal from builder

    # Use EU config as initial default
    # COPY lora_templates_sx1302/local_conf.json ./sx1302/local_conf.json
    # COPY lora_templates_sx1302/EU-global_conf.json ./sx1302/global_conf.json
}

perform_build() {
    echo "Starting to build from $BUILD_INPUTS_PATH. Will output result to $BUILD_OUTPUTS_PATH"
   
    # Create folder needed for build output
    mkdir -p "$BUILD_OUTPUT_SX1301_PATH"

    echo "Compiling upstream libraries"
    compile_upstream_libs

    echo "Copying default configuration files"
    copy_default_configs

    echo "Build finished"
}


# perform_build
