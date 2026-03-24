#!/usr/bin/env bash
set -euo pipefail

KEY_NAME="${CELESTIA_TX_KEY_NAME}"
KEYRING_DIR="${CELESTIA_TX_KEYRING_PATH}"
KEYRING_BACKEND="${CELESTIA_TX_KEYRING_BACKEND:-test}"
MNEMONIC="${CELESTIA_TX_MNEMONIC}"
EXPECTED_ADDRESS="${CELESTIA_TX_ADDRESS:-}"

mkdir -p "$KEYRING_DIR"

if cel-key show "$KEY_NAME" \
  --keyring-dir "$KEYRING_DIR" \
  --keyring-backend "$KEYRING_BACKEND" \
  >/dev/null 2>&1; then
  echo "[ok] key already exists: $KEY_NAME"
else
  printf '%s\n' "$MNEMONIC" | cel-key add "$KEY_NAME" \
    --recover \
    --keyring-dir "$KEYRING_DIR" \
    --keyring-backend "$KEYRING_BACKEND" \
    >/dev/null
fi

ADDR="$(
  cel-key show "$KEY_NAME" \
    --address \
    --keyring-dir "$KEYRING_DIR" \
    --keyring-backend "$KEYRING_BACKEND"
)"

if [ -n "$EXPECTED_ADDRESS" ] && [ "$ADDR" != "$EXPECTED_ADDRESS" ]; then
  echo "[error] expected=$EXPECTED_ADDRESS actual=$ADDR"
  exit 1
fi

echo "[result] address=$ADDR"
