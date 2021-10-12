# hm-pktfwd
Helium Miner Packet Forwarder

This compiles the packet forwarder container on the Nebra Miners.

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
| IN865 | India and Pakistan |
| KR920 | South Korea |
| RU864 | Russia |
| US915 | North America |

Please note:
| Region Plan | Region |
| --- | --- |
| EU433 | NOT YET SUPPORTED |


Upstream:
https://github.com/Lora-net/lora_gateway/tree/master/libloragw
https://github.com/Lora-net/packet_forwarder

git clone --recurse-submodules

## Development

### Building

`docker buildx build --platform linux/arm64/v8 --progress=plain -t DOCKERHUB_USER/hm-pktfwd-runner .`

To stop at an intermediary stage
`docker buildx build --platform linux/arm64/v8 --progress=plain --target pktfwd-builder -t pktfwd-builder .`

docker run --platform linux/arm64/v8

docker push DOCKERHUB_USER/pktfwd-runner