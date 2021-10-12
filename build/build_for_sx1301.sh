#!/usr/bin/env sh

# lora_pkt_fwd references lora_gateway so both libraries must be built
# https://github.com/Lora-net/packet_forwarder/blob/d0226eae6e7b6bbaec6117d0d2372bf17819c438/lora_pkt_fwd/Makefile#L7
compile_sx1301() {
    spi_bus="$1"
    echo "Compiling upstream lora_gateway/libloragw for $spi_bus"

    cd "$INPUT_UPSTREAM_LORA_GATEWAY_DIR/libloragw" || exit
    export SPI_DEV_DIR="/dev/$spi_bus"
    make clean
    make -j 4

    echo "Compiling upstream packet_forwarder/lora_pkt_fwd for $spi_bus"
    cd "$INPUT_UPSTREAM_PACKET_FORWARDER_DIR" || exit
    make clean
    make -j 4

    cp -R "$INPUT_UPSTREAM_PACKET_FORWARDER_DIR/lora_pkt_fwd/lora_pkt_fwd" "$OUTPUT_SX1301_DIR/lora_pkt_fwd_$spi_bus"
    echo "Finished building sx1301 for $spi_bus to $OUTPUT_SX1301_DIR"
}

# Build the upstream packet_frowarder for all spi interfaces on sx1301
compile_upstream_libs() {
    echo "Compiling for sx1301 concentrator on all the necessary SPI buses to $OUTPUT_SX1301_DIR"
    
    # Built outputs will be copied to this directory
    mkdir -p "$OUTPUT_SX1301_DIR"
    
    # In order to be more portable, intentionally not interating over an array
    # TODO uncomment
    # compile_sx1301 spidev0.0
    # compile_sx1301 spidev0.1
    # compile_sx1301 spidev1.0
    # compile_sx1301 spidev1.1
    # compile_sx1301 spidev1.2
    # compile_sx1301 spidev2.0
    # compile_sx1301 spidev2.1
    compile_sx1301 spidev32766.0
}

copy_reset_script() {
    cp "$INPUT_UPSTREAM_LORA_GATEWAY_DIR/reset_lgw.sh" "$OUTPUT_SX1301_RESET_LGW_FILEPATH"
}

compile_upstream_libs
copy_reset_script