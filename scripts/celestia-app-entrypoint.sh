#!/usr/bin/env bash
set -euo pipefail

APPD="${APPD:-celestia-appd}"
APP_HOME="${APP_HOME:-/data/local-celestia}"
CHAIN_ID="${CHAIN_ID:?CHAIN_ID is required}"
FUND_ADDR="${FUND_ADDR:?FUND_ADDR is required}"
FUND_AMOUNT="${FUND_AMOUNT:?FUND_AMOUNT is required}"
STAKE_AMOUNT="${STAKE_AMOUNT:?STAKE_AMOUNT is required}"
FEES="${FEES:?FEES is required}"
CELESTIA_APP_RPC_PORT="${CELESTIA_APP_RPC_PORT:?CELESTIA_APP_RPC_PORT is required}"
CELESTIA_CORE_GRPC_PORT="${CELESTIA_CORE_GRPC_PORT:?CELESTIA_CORE_GRPC_PORT is required}"

echo "[info] $($APPD version 2>&1)"
echo "[info] home=$APP_HOME chain=$CHAIN_ID"

mkdir -p "$APP_HOME"

if [ -f "$APP_HOME/config/genesis.json" ]; then
  echo "[init] existing node home detected at $APP_HOME"
  echo "[init] skipping init/genesis; starting with existing state"
else
  echo "[init] no genesis found, bootstrapping new chain"

  "$APPD" init "$CHAIN_ID" --chain-id "$CHAIN_ID" --home "$APP_HOME" >/dev/null 2>&1

  echo "[keys] creating validator key (keyring=test)"
  "$APPD" keys add validator --keyring-backend test --home "$APP_HOME" >/dev/null 2>&1

  VAL_ADDR="$("$APPD" keys show validator -a --keyring-backend test --home "$APP_HOME")"

  echo "[genesis] funding validator=$VAL_ADDR and tx addr=$FUND_ADDR"
  "$APPD" genesis add-genesis-account "$VAL_ADDR" "$FUND_AMOUNT" --home "$APP_HOME" >/dev/null 2>&1
  "$APPD" genesis add-genesis-account "$FUND_ADDR" "$FUND_AMOUNT" --home "$APP_HOME" >/dev/null 2>&1

  echo "[gentx] staking $STAKE_AMOUNT (fees $FEES)"
  "$APPD" genesis gentx validator "$STAKE_AMOUNT" \
    --fees "$FEES" \
    --keyring-backend test \
    --chain-id "$CHAIN_ID" \
    --home "$APP_HOME" >/dev/null 2>&1

  echo "[collect] including gentxs"
  "$APPD" genesis collect-gentxs --home "$APP_HOME" >/dev/null 2>&1
fi

echo "[start] rpc :$CELESTIA_APP_RPC_PORT grpc :$CELESTIA_CORE_GRPC_PORT"
exec "$APPD" start --home "$APP_HOME" \
  --rpc.laddr "tcp://0.0.0.0:$CELESTIA_APP_RPC_PORT" \
  --grpc.enable=true \
  --grpc.address "0.0.0.0:$CELESTIA_CORE_GRPC_PORT" \
  --force-no-bbr
