#!/usr/bin/env bash
set -euo pipefail

KEY_NAME="devkey"
KEYRING_DIR="$HOME/.celestia-devnet"

# HARDCODED MNEMONIC (dev only!!)
MNEMONIC="unique jaguar empower frozen task napkin brisk web popular forest plastic repeat buffalo tape iron reject flat aim laundry latin tattoo input camera above"

mkdir -p "$KEYRING_DIR"

if ! command -v cel-key >/dev/null 2>&1; then
  echo "[error] cel-key not found in PATH"
  exit 1
fi

if cel-key show "$KEY_NAME" --keyring-dir "$KEYRING_DIR" >/dev/null 2>&1; then
  echo "[ok] key already exists: $KEY_NAME"
else
  echo "[action] importing '$KEY_NAME' from mnemonic (non-interactive)..."
  printf '%s\n' "$MNEMONIC" | cel-key add "$KEY_NAME" \
    --recover \
    --keyring-dir "$KEYRING_DIR" \
    >/dev/null
fi

ADDR="$(cel-key show "$KEY_NAME" --address --keyring-dir "$KEYRING_DIR")"
echo "[result] key-name=$KEY_NAME"
echo "[result] keyring-dir=$KEYRING_DIR"
echo "[result] address=$ADDR"

