set quiet := true

_default:
    @just --list

# Start the services, reusing volumes unless "just up reset"
up mode="reuse":
    #!/usr/bin/env bash
    if [ "{{ mode }}" = "reset" ]; then
    just _genesis
    else
    docker compose up -d
    fi

# Shutdown, preserve data in volumes
down:
    docker compose down

# Shutdown, nuke data in volumes
clean:
    docker compose down -v

# Start fresh devnet, clearing all existing data volumes
_genesis:
    #!/usr/bin/env bash
    just clean
    NOW=$(date +%s)
    echo "Starting new chain with genesis timestamp = NOW (UNIX=$NOW) ..."
    sed -i "s/^export GENESIS_TIMESTAMP=.*/export GENESIS_TIMESTAMP=$NOW/" values.env
    docker compose up -d
