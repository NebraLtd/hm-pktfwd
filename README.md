# hm-pktfwd
Helium Miner Packet Forwarder

This is a Python app that uses prebuilt utilities to detect the correct concentrator chip and region, then start the concentrator accordingly.

hm-pktfwd builds off three other repos which each built a portion of the code required to run the packet forwarder.

- [lora_gateway](https://github.com/NebraLtd/lora_gateway)
- [packet_forwarder](https://github.com/NebraLtd/packet_forwarder)
- [sx1302_hal](https://github.com/NebraLtd/sx1302_hal)

## reset_lgw.sh
`reset_lgw.sh` is a shared tool that is used on all concentrator chip versions.
On sx1301 chips, [its is recommended](https://github.com/NebraLtd/lora_gateway#31-reset_lgwsh) that the script is run before each time the concentrator is started.
On chips that use sx1302_hal, the reset script is [run automatically](https://github.com/NebraLtd/sx1302_hal/blob/3d73e6af43535f700ff7b6c2b49cc79d388cd70f/packet_forwarder/src/lora_pkt_fwd.c#L1656-L1662) when the concentrator starts and is expected to be located in the same directory as the `lora_pkt_fwd` module.

reset_lgw is used by all concentrators, and inspired by the [upstream](https://github.com/NebraLtd/lora_gateway/blob/971c52e3e0f953102c0b057c9fff9b1df8a84d66/reset_lgw.sh)
[versions](https://github.com/NebraLtd/sx1302_hal/blob/6324b7a568ee24dbd9c4da64df69169a22615311/tools/reset_lgw.sh).
That said, it is different from the originals, context specific to hm-pktfwd, and moved to this repo to avoid confusion about its intention.
Additional context [here](https://github.com/NebraLtd/sx1302_hal/pull/1#discussion_r733253225).

## Supported Region Plans

You can typically find the exact region plan you need to use at [What Helium Region](https://whatheliumregion.xyz/) or on the [Helium Miner GitHub repo](https://github.com/helium/miner/blob/master/priv/countries_reg_domains.csv) however the table below provides a rough guide...

| Region Plan | Region |
| --- | --- |
| AS923_1 | Most of Asia |
| AS923_2 | Vietnam and Indonesia |
| AS923_3 | Phillipines and Cuba |
| AS923_4 | Israel |
| AU915 | Australia, New Zealand and South America|
| CN470 | China |
| EU868 | Europe, Middle East and some of Africa |
| EU433 | Parts of Africa and Asia|
| IN865 | India and Pakistan |
| KR920 | South Korea |
| RU864 | Russia |
| US915 | North America |

Please note:
| Region Plan | Region |
| --- | --- |
| CN779 | NOT YET SUPPORTED |

## Customization

The following environment variables control various aspects of the program's operation.

|Variable|Default|Required|Description|
| --- | --- | --- | --- |
| VARIANT| - | Yes | [See variants](https://github.com/NebraLtd/hm-pyhelper/blob/f8b2d8ceb90cfcd1da658a73e3741cc6de2ff1ff/hm_pyhelper/hardware_definitions.py#L1) |
| SX1301_REGION_CONFIGS_DIR | - | Yes | Path to [sx1301 configs](https://github.com/NebraLtd/hm-pktfwd/tree/900925b5bb3eab6c51cdabe24a59fede3fc85fe5/pktfwd/config/lora_templates_sx1301) |
| SX1302_REGION_CONFIGS_DIR | - | Yes | Path to [sx1302 configs](https://github.com/NebraLtd/hm-pktfwd/tree/900925b5bb3eab6c51cdabe24a59fede3fc85fe5/pktfwd/config/lora_templates_sx1302) |
| UTIL_CHIP_ID_FILEPATH | - | Yes | Path to [chip_id](https://github.com/NebraLtd/sx1302_hal/tree/69811057222f6f9cf8929ebfdb7fc6e36cc2618d/util_chip_id |
| RESET_LGW_FILEPATH | - | Yes | Path to [reset.sh](https://github.com/NebraLtd/hm-pktfwd/blob/900925b5bb3eab6c51cdabe24a59fede3fc85fe5/reset_lgw.sh). The same file is used for all sx130x versions. |
| ROOT_DIR | - | Yes | Directory the app will be run from. Should be the same location. `global_conf.json` will also be copied here. |
| SX1302_LORA_PKT_FWD_FILEPATH | - | Yes | Path to built [sx1302 lora_pkt_fwd](https://github.com/NebraLtd/sx1302_hal/blob/69811057222f6f9cf8929ebfdb7fc6e36cc2618d/packet_forwarder/src/lora_pkt_fwd.c) executable. |
| SX1301_LORA_PKT_FWD_DIR | - | Yes | Directory that contains [sx1301 lora_pkt_fwd](https://github.com/NebraLtd/packet_forwarder/tree/e8f24fe37ba555e5ad1ddf8eed26d0136f30f8de/lora_pkt_fwd) executables for all SPI buses. |
| LORA_PKT_FWD_BEFORE_CHECK_SLEEP_SECONDS | 5 | No | Duration after starting lora_pkt_fwd before establishing if it started successfully. |
| LORA_PKT_FWD_AFTER_SUCCESS_SLEEP_SECONDS | 30 | No | Duration to poll status after concentrator starts successfully. |
| LORA_PKT_FWD_AFTER_FAILURE_SLEEP_SECONDS | 2 | No | Duration to wait before restarting when concentrator exits with 0. If it exits with code greater than 0, program exits and container restarts. |
| LOGLEVEL | DEBUG | No | TRACE, DEBUG, INFO, WARN, etc. |
| REGION_FILEPATH | /var/pktfwd/region | No | Path where hm-miner [writes the region](https://github.com/NebraLtd/hm-miner/blob/8819d5439dc23b45a905ff126078aa59c5be3de8/gen-region.sh#L9). |
| DIAGNOSTICS_FILEPATH | /var/pktfwd/diagnostics | No | File containing "true" or "false" for whether lora_pkt_fwd is successfully running or not. |
| AWAIT_SYSTEM_SLEEP_SECONDS | 5 | No | How long [app sleeps](https://github.com/NebraLtd/hm-pktfwd/issues/63) before starting concentrator. |
| SENTRY_KEY | False | No | Key for Sentry. Sentry inactive if key is False. |
| REGION_OVERRIDE | False | No | Region override. eg `US915`. |
| BALENA_ID | From Balena | No | Only used with Sentry. |
| BALENA_APP_NAME | From Balena | No | Only used with Sentry. |


## Building

### Pre built containers

This repo automatically builds docker containers and uploads them to two repositories for easy access:
- [hm-pktfwd on DockerHub](https://hub.docker.com/r/nebraltd/hm-pktfwd)
- [hm-pktfwd on GitHub Packages](https://github.com/NebraLtd/hm-pktfwd/pkgs/container/hm-pktfwd)

The images are tagged using the docker long and short commit SHAs for that release. The current version deployed to miners can be found in the [helium-miner-software repo](https://github.com/NebraLtd/helium-miner-software/blob/production/docker-compose.yml).

### Manual build

When developing, it is faster to build locally instead of relying on the pre-built container to generate.

```bash
# Cross-compile
docker buildx build --platform linux/arm64/v8 --progress=plain -t DOCKERHUB_USER/hm-pktfwd .

# To stop at an intermediary stage
docker buildx build --platform linux/arm64/v8 --progress=plain --target pktfwd-builder -t pktfwd-builder .

# Tag and push image
docker image tag docker.io/DOCKERHUB_USER/hm-pktfwd DOCKERHUB_USER/hm-pktfwd:0.0.X
docker push DOCKERHUB_USER/hm-pktfwd:0.0.X
```

### Testing

**Hardware Requirements:** An ARM64 based device.

**Software Requirements:**

* Docker ([instructions](https://docs.docker.com/engine/install/debian/))
* Docker Compose ([instructions](https://docs.docker.com/compose/install/))
* `git`

With the dependencies installed, do the following:

```
$ git clone https://github.com/NebraLtd/hm-pktfwd.git
$ cd hm-pktfwd
$ docker build . -t hm-pktfwd
```

Once you've built the image, we need to do a bit of prep work to mock the environment:

```
$ mkdir -p /var/pktfwd
$ echo region_eu868 | sudo tee -a /var/pktfwd/region
```

We're now finally ready to start up the containers using:

```
$ docker-compose up
```
