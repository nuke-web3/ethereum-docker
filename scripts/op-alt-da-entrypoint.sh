#!/bin/sh
set -eu

APP_RPC_HOST="${CELESTIA_APP_RPC_HOST:?CELESTIA_APP_RPC_HOST is required}"
APP_RPC_PORT="${CELESTIA_APP_RPC_PORT:?CELESTIA_APP_RPC_PORT is required}"
BRIDGE_RPC_HOST="${CELESTIA_BRIDGE_RPC_HOST:?CELESTIA_BRIDGE_RPC_HOST is required}"
BRIDGE_RPC_PORT="${CELESTIA_BRIDGE_RPC_PORT:?CELESTIA_BRIDGE_RPC_PORT is required}"
CORE_GRPC_HOST="${CELESTIA_CORE_GRPC_HOST:?CELESTIA_CORE_GRPC_HOST is required}"
CORE_GRPC_PORT="${CELESTIA_CORE_GRPC_PORT:?CELESTIA_CORE_GRPC_PORT is required}"
KEYRING_PATH="${CELESTIA_KEYRING_PATH:-/celestia-keyring}"

WAIT_ATTEMPTS="${OP_ALT_DA_WAIT_ATTEMPTS:-120}"
WAIT_SECONDS="${OP_ALT_DA_WAIT_SECONDS:-2}"

STATUS_URL="http://${APP_RPC_HOST}:${APP_RPC_PORT}/status"
BRIDGE_URL="http://${BRIDGE_RPC_HOST}:${BRIDGE_RPC_PORT}"
CORE_GRPC_ADDR="${CORE_GRPC_HOST}:${CORE_GRPC_PORT}"

i=1
while [ "$i" -le "$WAIT_ATTEMPTS" ]; do
  STATUS_BODY="$(wget -qO- "$STATUS_URL" 2>/dev/null || true)"

  if echo "$STATUS_BODY" | grep -q '"latest_block_height":"[1-9][0-9]*"'; then
    break
  fi

  if [ "$i" -eq "$WAIT_ATTEMPTS" ]; then
    echo "[error] celestia-app did not become ready in time: ${STATUS_URL}"
    exit 1
  fi

  i=$((i + 1))
  sleep "$WAIT_SECONDS"
done

exec /usr/local/bin/da-server \
  --addr=0.0.0.0 \
  --port="${OP_ALT_DA_PORT}" \
  --metrics.enabled \
  --metrics.port="${OP_ALT_DA_METRICS_PORT}" \
  --log.level="${LOG_LEVEL}" \
  --celestia.namespace="${CELESTIA_NAMESPACE}" \
  --celestia.server="${BRIDGE_URL}" \
  --celestia.tls-enabled=false \
  --celestia.tx-client.core-grpc.addr="${CORE_GRPC_ADDR}" \
  --celestia.tx-client.core-grpc.tls-enabled=false \
  --celestia.tx-client.keyring-path="${KEYRING_PATH}" \
  --celestia.tx-client.key-name="${CELESTIA_TX_KEY_NAME}" \
  --celestia.tx-client.p2p-network="${CELESTIA_NETWORK}"
