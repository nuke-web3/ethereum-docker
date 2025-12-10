set quiet := true
set dotenv-path := ".env"

default:
	@just --list

# Start a new chain
genesis:
    just _check-volumes
    just _unsafe-genesis

_unsafe-genesis:
	echo "Starting new chain with genesis timstamp = now ..."
	sed -i "s/^export GENESIS_TIMESTAMP=.*/export GENESIS_TIMESTAMP=$(date +%s)/" values.env
	docker compose up -d

up:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down -v

clean-genesis:
	just clean
	just genesis

_check-volumes:
	#!/usr/bin/env bash
	existing_volumes="$(
		docker volume ls -q | while read -r v; do
			case "$v" in
				*eth-devnet-genesis*|*geth-data*|*teku-data*)
				echo "	$v"
				;;
			esac
		done
	)"
	if [ -n "$existing_volumes" ]; then
		echo "Devnet docker volumes already exist:"
		echo "$existing_volumes"
		echo
		echo "To reset, run \`just clean-start\`"
		echo
		exit 1
	fi
