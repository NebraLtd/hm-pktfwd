#! /bin/bash

set -euo pipefail

# shellcheck source=/dev/null
source /opt/nebra/setenv_pktfwd.sh

python3 pktfwd
