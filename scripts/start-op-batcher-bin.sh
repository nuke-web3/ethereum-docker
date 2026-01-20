#!/usr/bin/env bash
set -euo pipefail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source ${SCRIPT_DIR}/../.env
ROLLUP_FILE="${SCRIPT_DIR}/../config/${L2_CHAIN_ID}-rollup.json"
OP_BATCHER_BIN="${SCRIPT_DIR}/../../op/optimism/op-batcher/bin/op-batcher"

"${OP_BATCHER_BIN}" \
  --l1-eth-rpc "http://localhost:${L1_RPC_PORT}" \
  --l2-eth-rpc "http://localhost:${OP_GETH_HTTP_PORT}" \
  --rollup-rpc "http://localhost:${OP_NODE_RPC_PORT}" \
  --private-key "${BATCHER_PRIVATE_KEY}" \
  --rpc.addr "0.0.0.0" \
  --rpc.port "${OP_BATCHER_RPC_PORT}" \
  --rpc.enable-admin \
  --log.level "${LOG_LEVEL}" \
  --max-channel-duration 1 \
  --sub-safety-margin 4
