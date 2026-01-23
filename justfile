set quiet := true

# full consensus & execution layer mocked
# ETH := "docker-compose.ethereum.yml"
# anvil (exposes a few becon blob enpoints)

ETH := "docker-compose.anvil.yml"
CEL := "docker-compose.celestia.yml"
OP := "docker-compose.optimism.yml"
INIT_OP := "docker-compose.init_op.yml"

_default:
    @just --list

# One-time setup (OP init): run jobs, then remove init stack containers/networks.
init proj="devnet":
    #!/usr/bin/env bash
    set -euo pipefail

    NOW=$(date +%s)
    sed -i "s/^export GENESIS_TIMESTAMP=.*/export GENESIS_TIMESTAMP=$NOW/" values.env
    just _docker-compose init_op {{ proj }} up --remove-orphans -d
    just _docker-compose init_op {{ proj }} wait op-geth-init
    # Remove init containers + networks (but NOT volumes; no -v)
    just _docker-compose init_op {{ proj }} down

    echo "[SUCCESS] Initialization of OP on local devnet complete!"

# *DESTROY* existing data and startup with new genesis.
genesis proj="devnet":
    #!/usr/bin/env bash
    set -euo pipefail
    just clean all {{ proj }}
    just init {{ proj }}
    just _docker-compose all {{ proj }} up --remove-orphans -d
    just up all {{ proj }}

# Bring up devnet (create/start containers).
up part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} up -d

# Stop containers (keeps containers + networks + volumes).
stop part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} stop

# Start previously-stopped containers (no recreate).
start part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} start

# Bring down devnet (removes containers + networks; keeps volumes, see `just clean` to rm).
down part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} down

# Follow logs.
logs part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} logs -f

# *DESTROY* data and bring down devnet (removes containers + networks + volumes).
clean part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} down -v
    # also need to clean up init, as it defines exported volumes! (geth data)
    just _docker-compose init_op {{ proj }} down -v
    rm -f config/*

# Show containers status.
ps part="all" proj="devnet":
    just _docker-compose {{ part }} {{ proj }} ps

# Restart, preserving containers/volumes (stop -> start).
restart part="all" proj="devnet":
    just stop {{ part }} {{ proj }}
    just start {{ part }} {{ proj }}

# Private helper to run compose. part: eth | cel | all // proj: project
#

# NOTE: part/proj are POSITIONAL here.
_docker-compose part="all" proj="devnet" *args:
    #!/usr/bin/env bash
    set -euo pipefail

    part="{{ part }}"
    project="{{ proj }}"

    case "$part" in
      eth) files=(-f "{{ ETH }}") ;;
      cel) files=(-f "{{ CEL }}") ;;
      op)  files=(-f "{{ OP }}") ;;
      init_op)  files=(-f "{{ INIT_OP }}") ;;
      all) files=(-f "{{ ETH }}" -f "{{ CEL }}" -f "{{ OP }}") ;;
      *)
        echo "unknown part: $part (use eth|cel|op|all)" >&2
        exit 2
        ;;
    esac

    set -- {{ args }}
    exec docker compose "${files[@]}" -p "$project" "$@"
