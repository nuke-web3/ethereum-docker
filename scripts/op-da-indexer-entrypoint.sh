#!/bin/sh
set -eu

log() {
  echo "[op-celestia-indexer] $*" >&2
}

die() {
  echo "[op-celestia-indexer] ERROR: $*" >&2
  exit 1
}

require_env() {
  var_name="$1"
  eval "var_value=\${$var_name-}"
  [ -n "$var_value" ] || die "$var_name is not set"
  log "$var_name=$var_value"
}

log "entrypoint starting"

require_env L2_CHAIN_ID
require_env OP_CELESTIA_RPC_PORT
require_env L1_RPC_PORT
require_env L1_BEACON_RPC_PORT
require_env OP_GETH_HTTP_PORT
require_env OP_NODE_RPC_PORT
require_env CELESTIA_NODE_RPC_PORT
require_env CELESTIA_NAMESPACE
require_env LOG_LEVEL

ROLLUP_FILE="/config/${L2_CHAIN_ID}-rollup.json"
DB_PATH="/data/indexer.db"
BIN="/usr/local/bin/op-da-indexer"

log "BIN=$BIN"
log "ROLLUP_FILE=$ROLLUP_FILE"
log "DB_PATH=$DB_PATH"

[ -x "$BIN" ] || die "missing binary at $BIN"
[ -f "$ROLLUP_FILE" ] || die "missing rollup config $ROLLUP_FILE"

log "listing /config"
ls -la /config >&2 || true

INBOX_ADDRESS="$(
  sed -n 's/.*"batch_inbox_address"[[:space:]]*:[[:space:]]*"\(0x[0-9a-fA-F]\+\)".*/\1/p' "$ROLLUP_FILE" | head -n1
)"

GENESIS_L1_BLOCK="$(
  awk '
    /"genesis"[[:space:]]*:/ { in_genesis=1 }
    in_genesis && /"l1"[[:space:]]*:/ { in_l1=1 }
    in_genesis && in_l1 && /"number"[[:space:]]*:/ {
      if (match($0, /[0-9]+/)) {
        print substr($0, RSTART, RLENGTH)
        exit
      }
    }
  ' "$ROLLUP_FILE"
)"

[ -n "$INBOX_ADDRESS" ] || die "could not extract batch_inbox_address from $ROLLUP_FILE"
[ -n "$GENESIS_L1_BLOCK" ] || die "could not extract genesis.l1.number from $ROLLUP_FILE"

log "INBOX_ADDRESS=$INBOX_ADDRESS"
log "GENESIS_L1_BLOCK=$GENESIS_L1_BLOCK"
log "starting op-da-indexer"

exec "$BIN" \
  --rpc.port "${OP_CELESTIA_RPC_PORT}" \
  --start-l1-block "${GENESIS_L1_BLOCK}" \
  --batch-inbox-address "${INBOX_ADDRESS}" \
  --l1-eth-rpc "http://anvil:${L1_RPC_PORT}" \
  --l1-beacon-rpc "http://anvil:${L1_BEACON_RPC_PORT}" \
  --l2-eth-rpc "http://op-geth:${OP_GETH_HTTP_PORT}" \
  --op-node-rpc "http://op-node:${OP_NODE_RPC_PORT}" \
  --db-path "${DB_PATH}" \
  --log.level "${LOG_LEVEL}" \
  --da.rpc "http://celestia-bridge:${CELESTIA_NODE_RPC_PORT}" \
  --da.namespace "${CELESTIA_NAMESPACE}" \
  --rpc.enable-admin
