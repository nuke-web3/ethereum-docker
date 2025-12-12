set quiet := true

ETH := "docker-compose.ethereum.yml"
CEL := "docker-compose.celestia.yml"

_default:
    @just --list

# -----------------------------
# Ethereum only
# -----------------------------
# (Re)Start Ethereum Devnet (consensus and execution nodes)
up-eth:
    docker compose -f {{ETH}} -p eth up -d

down-eth:
    docker compose -f {{ETH}} -p eth down

logs-eth:
    docker compose -f {{ETH}} -p eth logs -f

# Shutdown Ethereum AND remove its volumes
clean-eth:
    docker compose -f {{ETH}} -p eth down -v

# -----------------------------
# Celestia only
# -----------------------------
# (Re)Start Celestia Devnet (validator + bridge node)
up-cel:
    docker compose -f {{CEL}} -p cel up -d

down-cel:
    docker compose -f {{CEL}} -p cel down

logs-cel:
    docker compose -f {{CEL}} -p cel logs -f

# Shutdown Celestia AND remove its volumes
clean-cel:
    docker compose -f {{CEL}} -p cel down -v

# -----------------------------
# Combined stack (Ethereum + Celestia)
# -----------------------------
# (Re)Start Full Devnet (Ethereum + Celestia)
up-all:
    docker compose -f {{ETH}} -f {{CEL}} -p fullstack up -d

down-all:
    docker compose -f {{ETH}} -f {{CEL}} -p fullstack down

logs-all:
    docker compose -f {{ETH}} -f {{CEL}} -p fullstack logs -f

# Shutdown fullstack AND remove ALL volumes
clean-all:
    docker compose -f {{ETH}} -f {{CEL}} -p fullstack down -v

# -----------------------------
# Utility
# -----------------------------
# `docker compose `ps` for all devnets
ps:
    docker compose -p eth ps || true
    docker compose -p cel ps || true
    docker compose -p fullstack ps || true

restart-all:
    just down-all
    just up-all

# Destroy existing devnet and start from scratch. 
genesis:
    #!/usr/bin/env bash
    just clean
    NOW=$(date +%s)
    echo "Starting new chain with genesis timestamp = NOW (UNIX=$NOW) ..."
    sed -i "s/^export GENESIS_TIMESTAMP=.*/export GENESIS_TIMESTAMP=$NOW/" values.env
    just up-all
