#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../.env"

PROJECT_NAME="${PROJECT_NAME:-devnet}"
VOLUME_BASE_NAME="${VOLUME_BASE_NAME:-common-config}"
VOLUME_NAME="${PROJECT_NAME}_${VOLUME_BASE_NAME}"

STATE_FILE="/config/state.json"

OP_PROPOSER_HOST_BIN="${SCRIPT_DIR}/../../op/optimism/op-proposer/bin/op-proposer"
[ -x "${OP_PROPOSER_HOST_BIN}" ] || {
  echo "op-proposer not found/executable: ${OP_PROPOSER_HOST_BIN}" >&2
  exit 1
}

# Extract DisputeGameFactoryProxy from state.json inside the volume using only base alpine tools.
# This expects a JSON fragment like: "DisputeGameFactoryProxy": "0xabc..."
DGF_ADDRESS="$(
  docker run --rm \
    -v "${VOLUME_NAME}:/config:ro" \
    alpine \
    sh -ceu '
      f="'"${STATE_FILE}"'"
      [ -f "$f" ] || { echo "missing $f" >&2; exit 1; }

      # Print the first match and extract the 0x... address
      # Works with optional spaces, and with or without quotes around the value.
      line="$(grep -m1 -E "\"DisputeGameFactoryProxy\"[[:space:]]*:[[:space:]]*\"?0x[0-9a-fA-F]+\"?" "$f" || true)"
      [ -n "$line" ] || { echo "DisputeGameFactoryProxy not found in $f" >&2; exit 1; }

      # Extract 0x... from the matched line
      echo "$line" | sed -n -E "s/.*\"DisputeGameFactoryProxy\"[[:space:]]*:[[:space:]]*\"?(0x[0-9a-fA-F]+)\"?.*/\1/p"
    '
)"

if [[ -z "${DGF_ADDRESS}" || "${DGF_ADDRESS}" == "null" ]]; then
  echo "ERROR: could not find DisputeGameFactoryProxy in ${STATE_FILE} (volume: ${VOLUME_NAME})" >&2
  exit 1
fi

set -x
exec docker run --rm -it \
  --env-file "${SCRIPT_DIR}/../.env" \
  --name "${PROJECT_NAME}-op-proposer-1" \
  --network=host \
  -e TERM="${TERM:-xterm-256color}" \
  -e FORCE_COLOR=1 \
  -v "${OP_PROPOSER_HOST_BIN}:/bin/op-proposer:ro" \
  alpine \
  /bin/op-proposer \
    --l1-eth-rpc "http://localhost:${L1_RPC_PORT}" \
    --rollup-rpc "http://localhost:${OP_NODE_RPC_PORT}" \
    --game-factory-address "${DGF_ADDRESS}" \
    --game-type 1 \
    --proposal-interval "3s" \
    --private-key "${PROPOSER_PRIVATE_KEY}" \
    --rpc.addr "0.0.0.0" \
    --rpc.port "${OP_PROPOSER_RPC_PORT}" \
    --log.level "${LOG_LEVEL}" \
    --poll-interval "12s" \
    --allow-non-finalized
set +x
