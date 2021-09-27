#!/usr/bin/env sh

compile_upstream_libs() {
    # Compile for sx1301 concentrator on all the necessary SPI buses
    # RUN ./buildfiles/compile_sx1301.sh spidev0.0
    # RUN ./buildfiles/compile_sx1301.sh spidev0.1
    # RUN ./buildfiles/compile_sx1301.sh spidev1.0
    # RUN ./buildfiles/compile_sx1301.sh spidev1.1
    # RUN ./buildfiles/compile_sx1301.sh spidev1.2
    # RUN ./buildfiles/compile_sx1301.sh spidev2.0
    # RUN ./buildfiles/compile_sx1301.sh spidev2.1
    ./buildfiles/compile_sx1301.sh spidev32766.0

    # Compile for sx1302 concentrator
    # RUN ./buildfiles/compile_sx1302.sh

    # COPY --from=builder /opt/packet_forwarder/sx1302_hal-1.0.5 ./sx1302
}

copy_default_configs() {
    # Place default configs and use EU as initial default
    output_path_sx1301="$BUILD_OUTPUT_PATH/sx1301"
    echo "Copying configs from $BUILD_INPUTS_PATH/pktfwd/config/lora_templates_sx1301/"
    echo "To $output_path_sx1301"
    mkdir -p "$output_path_sx1301"
    cp "$BUILD_INPUTS_PATH/pktfwd/config/lora_templates_sx1301/local_conf.json" "$output_path_sx1301/local_conf.json"
    cp "$BUILD_INPUTS_PATH/pktfwd/config/lora_templates_sx1301/EU-global_conf.json" "$output_path_sx1301/global_conf.json"

    # Copy sx1302 hal from builder

    # Use EU config as initial default
    # COPY lora_templates_sx1302/local_conf.json ./sx1302/local_conf.json
    # COPY lora_templates_sx1302/EU-global_conf.json ./sx1302/global_conf.json
}

perform_build() {
    echo "Starting to build from $BUILD_INPUTS_PATH. Will output result to $BUILD_OUTPUT_PATH"

    # Create folder needed for build output
    mkdir -p "$BUILD_OUTPUT_PATH"

    echo "Compiling upstream libraries"
    compile_upstream_libs

    echo "Copying default configuration files"
    copy_default_configs

    echo "Build finished"
}


perform_build


