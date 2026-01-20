#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../.env"

ROLLUP_FILE="${SCRIPT_DIR}/../config/${L2_CHAIN_ID}-rollup.json"
STATE_FILE="${SCRIPT_DIR}/../config/state.json"
OP_PROPOSER_BIN="${SCRIPT_DIR}/../../op/optimism/op-proposer/bin/op-proposer"

# Extract DisputeGameFactory *proxy* (what op-proposer should use)
DGF_ADDRESS="$(jq -re '.opChainDeployments[0].DisputeGameFactoryProxy' "${STATE_FILE}")"

if [[ -z "${DGF_ADDRESS}" || "${DGF_ADDRESS}" == "null" ]]; then
  echo "ERROR: could not find DisputeGameFactoryProxy in ${STATE_FILE}" >&2
  exit 1
fi

exec "${OP_PROPOSER_BIN}" \
  --l1-eth-rpc "http://localhost:${L1_RPC_PORT}" \
  --rollup-rpc "http://localhost:${OP_NODE_RPC_PORT}" \
  --game-factory-address "${DGF_ADDRESS}" \
  --game-type 1 \
  --proposal-interval "10s" \
  --private-key "${PROPOSER_PRIVATE_KEY}" \
  --rpc.addr "0.0.0.0" \
  --rpc.port "${OP_PROPOSER_RPC_PORT}" \
  --log.level "${LOG_LEVEL}" \
  --poll-interval "12s" \
  --allow-non-finalized
