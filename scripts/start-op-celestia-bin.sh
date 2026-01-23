#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../.env"

ROLLUP_FILE="${SCRIPT_DIR}/../config/${L2_CHAIN_ID}-rollup.json"
OP_CELESTIA_BIN="${SCRIPT_DIR}/../../op/optimism/op-celestia/bin/op-celestia-indexer"

# Extract required data from configs
INBOX_ADDRESS=$(jq -r '.batch_inbox_address' "${ROLLUP_FILE}")
GENESIS_L1_BLOCK=$(jq -r '.genesis.l1.number' "${ROLLUP_FILE}")

if [[ -z "${INBOX_ADDRESS}" || "${INBOX_ADDRESS}" == "null" ]]; then
  echo "ERROR: could not find `batch_inbox_address` in ${ROLLUP_FILE}" >&2
  exit 1
fi

if [[ -z "${INBOX_ADDRESS}" || "${INBOX_ADDRESS}" == "null" ]]; then
  echo "ERROR: could not find L1 genesis block height in ${ROLLUP_FILE}" >&2
  exit 1
fi

set -x  # Prints the FULL expanded command automatically
exec "${OP_CELESTIA_BIN}" \
  --rpc.port 9999 \
  --start-l1-block "${GENESIS_L1_BLOCK}" \
  --batch-inbox-address "${INBOX_ADDRESS}" \
  --l1-eth-rpc "http://localhost:${L1_RPC_PORT}" \
  --l1-beacon-rpc "http://localhost:${L1_BEACON_RPC_PORT}" \
  --l2-eth-rpc "http://localhost:${OP_GETH_HTTP_PORT}" \
  --op-node-rpc "http://localhost:${OP_NODE_RPC_PORT}" \
  --db-path "${OP_CELESTIA_DB_PATH}" \
  --log.level "${LOG_LEVEL}" \
  --da.rpc "http://localhost:${CELESTIA_NODE_RPC_PORT}" \
  --da.namespace "${CELESTIA_NAMESPACE}" \
  --rpc.enable-admin
set +x
