# hm-pktfwd
Helium Miner Packet Forwarder

This compiles the packet forwarder container on the Nebra Miners.

# Supported Region Plans

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

## Pre built containers

This repo automatically builds docker containers and uploads them to two repositories for easy access:
- [hm-pktfwd on DockerHub](https://hub.docker.com/r/nebraltd/hm-pktfwd)
- [hm-pktfwd on GitHub Packages](https://github.com/NebraLtd/hm-pktfwd/pkgs/container/hm-pktfwd)

The images are tagged using the docker long and short commit SHAs for that release. The current version deployed to miners can be found in the [helium-miner-software repo](https://github.com/NebraLtd/helium-miner-software/blob/production/docker-compose.yml).
