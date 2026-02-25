#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.env"

PROJECT_NAME="${PROJECT_NAME:-devnet}"
VOLUME_BASE_NAME="${VOLUME_BASE_NAME:-common-config}"
VOLUME_NAME="${PROJECT_NAME}_${VOLUME_BASE_NAME}"

OP_BATCHER_HOST_BIN="${SCRIPT_DIR}/../../op/optimism/op-batcher/bin/op-batcher"
[ -x "${OP_BATCHER_HOST_BIN}" ] || {
  echo "op-batcher not found/executable: ${OP_BATCHER_HOST_BIN}" >&2
  exit 1
}

# Optional: mount celestia keyring path if present on host (matches your flag path exactly)
EXTRA_MOUNTS=()
if [ -d "${HOME}/.celestia-devnet" ]; then
  EXTRA_MOUNTS+=( -v "${HOME}/.celestia-devnet:/home/nuke/.celestia-devnet:ro" )
fi

# Run op-batcher inside Docker WITH TTY so colors are preserved
set -x
docker run --rm -it \
  --name "${PROJECT_NAME}-op-batcher-1" \
  --env-file "${SCRIPT_DIR}/../.env" \
  --network=host \
  -e TERM="${TERM:-xterm-256color}" \
  -e FORCE_COLOR=1 \
  -v "${VOLUME_NAME}:/config:ro" \
  -v "${OP_BATCHER_HOST_BIN}:/bin/op-batcher:ro" \
  "${EXTRA_MOUNTS[@]}" \
  alpine \
  /bin/op-batcher \
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
    --sub-safety-margin 4 \
    \
    --da.rpc "http://localhost:${CELESTIA_NODE_RPC_PORT}" \
    --da.tls-enabled=false \
    --da.namespace "${CELESTIA_NAMESPACE}" \
    --da.tx-client.key-name "devkey" \
    --da.tx-client.keyring-path "/home/nuke/.celestia-devnet" \
    --da.tx-client.core-grpc.addr "localhost:${CELESTIA_CORE_GRPC_PORT}" \
    --da.tx-client.core-grpc.tls-enabled=false \
    --da.tx-client.p2p-network "${CELESTIA_NETWORK}"
set +x
