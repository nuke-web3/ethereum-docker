#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.env"

PROJECT_NAME="${PROJECT_NAME:-devnet}"
OP_ALT_DA_PORT="${OP_ALT_DA_PORT:-3100}"

DA_SERVER_HOST_BIN="${SCRIPT_DIR}/../../op/alt-da/bin/da-server"

[ -x "${DA_SERVER_HOST_BIN}" ] || {
  echo "da-server not found/executable: ${DA_SERVER_HOST_BIN}" >&2
  exit 1
}

: "${CELESTIA_NAMESPACE:?CELESTIA_NAMESPACE is required}"
: "${CELESTIA_NODE_RPC_PORT:?CELESTIA_NODE_RPC_PORT is required}"
: "${CELESTIA_CORE_GRPC_PORT:?CELESTIA_CORE_GRPC_PORT is required}"
: "${CELESTIA_NETWORK:?CELESTIA_NETWORK is required}"
: "${CELESTIA_TX_KEYRING_PATH:?CELESTIA_TX_KEYRING_PATH is required}"
: "${CELESTIA_TX_KEY_NAME:?CELESTIA_TX_KEY_NAME is required}"

[ -d "${CELESTIA_TX_KEYRING_PATH}" ] || {
  echo "CELESTIA_TX_KEYRING_PATH does not exist: ${CELESTIA_TX_KEYRING_PATH}" >&2
  exit 1
}

set -x
docker run --rm -it \
  --name "${PROJECT_NAME}-op-alt-da-1" \
  --network=host \
  -e TERM="${TERM:-xterm-256color}" \
  -e FORCE_COLOR=1 \
  -v "${DA_SERVER_HOST_BIN}:/bin/da-server:ro" \
  -v "${CELESTIA_TX_KEYRING_PATH}:${CELESTIA_TX_KEYRING_PATH}:ro" \
  debian:bookworm-slim \
  /bin/da-server \
    --addr "0.0.0.0" \
    --port "${OP_ALT_DA_PORT}" \
    --metrics.enabled \
    --metrics.port "${OP_ALT_DA_METRICS_PORT}" \
    --log.level "${LOG_LEVEL}" \
    --celestia.namespace "${CELESTIA_NAMESPACE}" \
    --celestia.server "http://localhost:${CELESTIA_NODE_RPC_PORT}" \
    --celestia.tls-enabled=false \
    --celestia.tx-client.core-grpc.addr "localhost:${CELESTIA_CORE_GRPC_PORT}" \
    --celestia.tx-client.core-grpc.tls-enabled=false \
    --celestia.tx-client.keyring-path "${CELESTIA_TX_KEYRING_PATH}" \
    --celestia.tx-client.key-name "${CELESTIA_TX_KEY_NAME}" \
    --celestia.tx-client.p2p-network "${CELESTIA_NETWORK}"
set +x
