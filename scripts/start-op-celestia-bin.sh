#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.env"

PROJECT_NAME="${PROJECT_NAME:-devnet}"
VOLUME_BASE_NAME="${VOLUME_BASE_NAME:-common-config}"
CONFIG_VOLUME_NAME="${PROJECT_NAME}_${VOLUME_BASE_NAME}"

DB_VOLUME_BASE_NAME="${OP_CELESTIA_DB_VOLUME_BASE_NAME:-op-celestia-indexer-data}"
DB_VOLUME_NAME="${PROJECT_NAME}_${DB_VOLUME_BASE_NAME}"

ROLLUP_FILE="/config/${L2_CHAIN_ID}-rollup.json"
OP_CELESTIA_BIN_HOST="${SCRIPT_DIR}/../../op/da-indexer/bin/op-da-indexer"

# Absolute paths inside the container for the DB volume
DB_DIR_IN_CONTAINER="/data"
DB_PATH_IN_CONTAINER="${DB_DIR_IN_CONTAINER}/indexer.db"

ROLLUP_JSON="$(
  docker run --rm \
    -v "${CONFIG_VOLUME_NAME}:/config:ro" \
    alpine \
    cat "${ROLLUP_FILE}"
)"

INBOX_ADDRESS="$(printf '%s\n' "${ROLLUP_JSON}" | jq -r '.batch_inbox_address')"
GENESIS_L1_BLOCK="$(printf '%s\n' "${ROLLUP_JSON}" | jq -r '.genesis.l1.number')"

if [[ -z "${INBOX_ADDRESS}" || "${INBOX_ADDRESS}" == "null" ]]; then
  echo "ERROR: could not find batch_inbox_address in ${ROLLUP_FILE}" >&2
  exit 1
fi

if [[ -z "${GENESIS_L1_BLOCK}" || "${GENESIS_L1_BLOCK}" == "null" ]]; then
  echo "ERROR: could not find L1 genesis block height in ${ROLLUP_FILE}" >&2
  exit 1
fi

# TODO: glibc means we need debian... move to alpine w/ musl?

set -x
docker run --rm -it \
  --name "${PROJECT_NAME}-op-celestia-indexer-1" \
  --network=host \
  -e TERM="${TERM:-xterm-256color}" \
  -e FORCE_COLOR=1 \
  -v "${CONFIG_VOLUME_NAME}:/config:ro" \
  -v "${DB_VOLUME_NAME}:${DB_DIR_IN_CONTAINER}" \
  -v "${OP_CELESTIA_BIN_HOST}:/bin/op-celestia-indexer:ro" \
  debian:bookworm-slim \
  /bin/op-celestia-indexer \
    --rpc.port "${OP_CELESTIA_RPC_PORT}" \
    --start-l1-block "${GENESIS_L1_BLOCK}" \
    --batch-inbox-address "${INBOX_ADDRESS}" \
    --l1-eth-rpc "http://localhost:${L1_RPC_PORT}" \
    --l1-beacon-rpc "http://localhost:${L1_BEACON_RPC_PORT}" \
    --l2-eth-rpc "http://localhost:${OP_GETH_HTTP_PORT}" \
    --op-node-rpc "http://localhost:${OP_NODE_RPC_PORT}" \
    --db-path "${DB_PATH_IN_CONTAINER}" \
    --log.level "${LOG_LEVEL}" \
    --da.rpc "http://localhost:${CELESTIA_NODE_RPC_PORT}" \
    --da.namespace "${CELESTIA_NAMESPACE}" \
    --rpc.enable-admin
set +x
