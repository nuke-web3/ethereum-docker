#!/bin/sh
set -eu

STATE_PATH="${STATE_PATH:-/config/anvil-state.json}"

# Pull from .env (compose env_file passes these into container)
CHAIN_ID="${L1_CHAIN_ID:-31337}"
PORT="${L1_RPC_PORT:-8545}"

HOST="0.0.0.0"

DUMP_ARGS="--host ${HOST} --port ${PORT} --chain-id ${CHAIN_ID} --dump-state ${STATE_PATH}"

if [ -f "${STATE_PATH}" ]; then
  echo "[anvil-entrypoint] Loading state from ${STATE_PATH}"
  exec anvil --load-state "${STATE_PATH}" $DUMP_ARGS
else
  echo "[anvil-entrypoint] No state file at ${STATE_PATH}; starting fresh"
  exec anvil $DUMP_ARGS
fi

