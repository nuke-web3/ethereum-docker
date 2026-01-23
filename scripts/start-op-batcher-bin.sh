#!/usr/bin/env bash
set -euo pipefail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source ${SCRIPT_DIR}/../.env
ROLLUP_FILE="${SCRIPT_DIR}/../config/${L2_CHAIN_ID}-rollup.json"
OP_BATCHER_BIN="${SCRIPT_DIR}/../../op/optimism/op-batcher/bin/op-batcher"

set -x  # Prints the FULL expanded command automatically
"${OP_BATCHER_BIN}" \
  --data-availability-type "${OP_BATCHER_DATA_AVAILABILITY_TYPE}" \
  --l1-eth-rpc "http://localhost:${L1_RPC_PORT}" \
  --l2-eth-rpc "http://localhost:${OP_GETH_HTTP_PORT}" \
  --rollup-rpc "http://localhost:${OP_NODE_RPC_PORT}" \
  --private-key "${BATCHER_PRIVATE_KEY}" \
  --rpc.addr "0.0.0.0" \
  --rpc.port "${OP_BATCHER_RPC_PORT}" \
  --rpc.enable-admin \
  --log.level "${LOG_LEVEL}" \
  --max-channel-duration "${OP_BATCHER_MAX_CHANNEL_DURATION}" \
  --sub-safety-margin 4
set +x
