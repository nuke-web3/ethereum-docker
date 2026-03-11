#!/bin/sh
set -eu

log() {
  echo "[op-proposer] $*" >&2
}

die() {
  echo "[op-proposer] ERROR: $*" >&2
  exit 1
}

require_env() {
  var_name="$1"
  eval "var_value=\${$var_name-}"
  [ -n "$var_value" ] || die "$var_name is not set"
  log "$var_name=$var_value"
}

log "entrypoint starting"

require_env L1_RPC_PORT
require_env OP_NODE_RPC_PORT
require_env OP_PROPOSER_RPC_PORT
require_env PROPOSER_PRIVATE_KEY
require_env LOG_LEVEL

STATE_FILE="/config/state.json"

if command -v op-proposer >/dev/null 2>&1; then
  BIN="$(command -v op-proposer)"
elif [ -x /usr/local/bin/op-proposer ]; then
  BIN=/usr/local/bin/op-proposer
elif [ -x /bin/op-proposer ]; then
  BIN=/bin/op-proposer
else
  log "contents of /usr/local/bin:"
  ls -la /usr/local/bin >&2 || true
  log "contents of /bin:"
  ls -la /bin >&2 || true
  die "could not find op-proposer binary"
fi

log "BIN=$BIN"
log "STATE_FILE=$STATE_FILE"

log "contents of /config:"
ls -la /config >&2 || true

[ -f "$STATE_FILE" ] || die "missing $STATE_FILE"

line="$(
  grep -m1 -E '"DisputeGameFactoryProxy"[[:space:]]*:[[:space:]]*"?0x[0-9a-fA-F]+"?' "$STATE_FILE" || true
)"

[ -n "$line" ] || die "DisputeGameFactoryProxy not found in $STATE_FILE"

DGF_ADDRESS="$(
  printf '%s\n' "$line" |
    sed -n -E 's/.*"DisputeGameFactoryProxy"[[:space:]]*:[[:space:]]*"?((0x[0-9a-fA-F]+))"?.*/\1/p'
)"

[ -n "$DGF_ADDRESS" ] || die "could not extract DisputeGameFactoryProxy from $STATE_FILE"
[ "$DGF_ADDRESS" != "null" ] || die "DisputeGameFactoryProxy was null in $STATE_FILE"

log "DGF_ADDRESS=$DGF_ADDRESS"
log "launching $BIN"

exec "$BIN" \
  --l1-eth-rpc="http://anvil:${L1_RPC_PORT}" \
  --rollup-rpc="http://op-node:${OP_NODE_RPC_PORT}" \
  --game-factory-address="$DGF_ADDRESS" \
  --game-type=1 \
  --proposal-interval=3s \
  --private-key="${PROPOSER_PRIVATE_KEY}" \
  --rpc.addr=0.0.0.0 \
  --rpc.port="${OP_PROPOSER_RPC_PORT}" \
  --log.level="${LOG_LEVEL}" \
  --poll-interval=12s \
  --metrics.enabled \
  --metrics.port=7302 \
  --allow-non-finalized
