set quiet := true

ETH := "docker-compose.ethereum.yml"
CEL := "docker-compose.celestia.yml"

_default:
    @just --list

# Startup from absolute zero - required for timestame of genesis not to cause shit
pheonix:
    just destroy
    docker compose -f docker-compose.init_op.yml up -d 
    docker compose -f docker-compose.optimism.yml up -d 

destroy:
    docker compose -f docker-compose.optimism.yml down -v
    docker compose -f docker-compose.init_op.yml down -v
    rm -f config/*

# Bring up devnet (create/start containers).
up part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} up -d

# Stop containers (keeps containers + networks + volumes).
stop part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} stop

# Start previously-stopped containers (no recreate).
start part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} start

# Bring down devnet (removes containers + networks; keeps volumes unless -v).
down part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} down

# Follow logs.
logs part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} logs -f

# *DESTROY* data and bring down devnet (removes containers + networks + volumes).
clean part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} down -v

# Show containers status.
ps part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} ps

# Restart, preserving containers/volumes (stop -> start).
restart part="all" proj="devnet":
    just stop {{ part }} {{ proj }}
    just start {{ part }} {{ proj }}

# *DESTROY* existing data and startup with new genesis.
genesis proj="devnet":
    #!/usr/bin/env bash
    set -euo pipefail
    just clean all {{ proj }}
    NOW=$(date +%s)
    sed -i "s/^export GENESIS_TIMESTAMP=.*/export GENESIS_TIMESTAMP=$NOW/" values.env
    just up all {{ proj }}

# Private helper to run compose. part: eth | cel | all // proj: project
# Private helper to run compose.
#
# NOTE: part/proj are POSITIONAL here (recommended).
_docker-compose part="all" proj="devnet" *args:
    #!/usr/bin/env bash
    set -euo pipefail

    part="{{ part }}"
    project="{{ proj }}"

    case "$part" in
      eth) files=(-f "{{ ETH }}") ;;
      cel) files=(-f "{{ CEL }}") ;;
      all) files=(-f "{{ ETH }}" -f "{{ CEL }}") ;;
      *)
        echo "unknown part: $part (use eth|cel|all)" >&2
        exit 2
        ;;
    esac

    # Forward variadic args the shell way (keeps tokens split correctly).
    set -- {{ args }}
    exec docker compose "${files[@]}" -p "$project" "$@"
