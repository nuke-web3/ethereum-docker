#!/usr/bin/env bash
set -euo pipefail

NODE_STORE="${NODE_STORE:-/data/local-celestia/bridge}"
CELESTIA_NETWORK="${CELESTIA_NETWORK:?CELESTIA_NETWORK is required}"
CELESTIA_CORE_GRPC_PORT="${CELESTIA_CORE_GRPC_PORT:?CELESTIA_CORE_GRPC_PORT is required}"
CELESTIA_NODE_RPC_PORT="${CELESTIA_NODE_RPC_PORT:?CELESTIA_NODE_RPC_PORT is required}"
CELESTIA_APP_RPC_HOST="${CELESTIA_APP_RPC_HOST:-celestia-app}"

if [ ! -d "$NODE_STORE" ] || [ -z "$(ls -A "$NODE_STORE" 2>/dev/null)" ]; then
  echo "[init] initializing bridge store at $NODE_STORE"
  celestia bridge init \
    --p2p.network "$CELESTIA_NETWORK" \
    --node.store "$NODE_STORE" \
    --core.ip "$CELESTIA_APP_RPC_HOST" \
    --core.port "$CELESTIA_CORE_GRPC_PORT"
else
  echo "[init] existing bridge store found; skipping init"
fi

echo "[start] starting bridge node (p2p.network=$CELESTIA_NETWORK)"
exec celestia bridge start \
  --p2p.network "$CELESTIA_NETWORK" \
  --node.store "$NODE_STORE" \
  --core.ip "$CELESTIA_APP_RPC_HOST" \
  --core.port "$CELESTIA_CORE_GRPC_PORT" \
  --rpc.skip-auth \
  --rpc.addr 0.0.0.0 \
  --rpc.port "$CELESTIA_NODE_RPC_PORT" \
  --log.level.module share/discovery:error \
  --log.level.module module/p2p:panic
