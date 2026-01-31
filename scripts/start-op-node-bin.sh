#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${SCRIPT_DIR}/../.env

ROLLUP_FILE="${SCRIPT_DIR}/../config/${L2_CHAIN_ID}-rollup.json"
OP_NODE_BIN="${SCRIPT_DIR}/../../op/optimism/op-node/bin/op-node"

L1_CHAIN_CONFIG="${SCRIPT_DIR}/../config/l1-chain-config.json"
if [[ ! -f "${L1_CHAIN_CONFIG}" ]]; then
  cat > "${L1_CHAIN_CONFIG}" << EOF
{
  "chainId": ${L1_CHAIN_ID},
  "homesteadBlock": 0,
  "eip150Block": 0,
  "eip155Block": 0,
  "eip158Block": 0,
  "byzantiumBlock": 0,
  "constantinopleBlock": 0,
  "petersburgBlock": 0,
  "istanbulBlock": 0,
  "muirGlacierBlock": 0,
  "berlinBlock": 0,
  "londonBlock": 0,
  "arrowGlacierBlock": 0,
  "grayGlacierBlock": 0,
  "shanghaiTime": 0,
  "cancunTime": 0,
  "blobSchedule": {
    "cancun": { 
      "target": ${L2_BLOB_TARGET}, 
      "max": ${L2_BLOB_MAX}, 
      "baseFeeUpdateFraction": ${L2_BLOB_FEE_FRACTION}
    }
  }
}
EOF
fi

set -x  # Prints the FULL expanded command automatically
"${OP_NODE_BIN}" \
  --l1 "http://localhost:${L1_RPC_PORT}" \
  --l1.beacon "http://localhost:${L1_BEACON_RPC_PORT}" \
  --l1.beacon.ignore \
  --l1.trustrpc \
  --l2 "http://localhost:${OP_GETH_AUTH_PORT}" \
  --l2.jwt-secret "${SCRIPT_DIR}/../config/jwt.txt" \
  --rollup.config "${ROLLUP_FILE}" \
  --rollup.l1-chain-config "${L1_CHAIN_CONFIG}" \
  --rpc.addr "0.0.0.0" \
  --rpc.port "${OP_NODE_RPC_PORT}" \
  --rpc.enable-admin \
  --p2p.disable \
  --sequencer.enabled \
  --sequencer.l1-confs 0 \
  --verifier.l1-confs 0 \
  --log.level "${LOG_LEVEL}" \
  --p2p.sequencer.key "${SEQUENCER_PRIVATE_KEY}" \
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
