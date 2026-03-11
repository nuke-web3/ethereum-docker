# Celestia Rollup Devnet Suite </br> _Ethereum + Celestia + Rollups_

This repository provisions local devnets using Docker Compose and `just`, with **separate compose files per “part”** (currently **Ethereum** and **Celestia**, with more coming for rollup stacks).

- **Ethereum** runs an execution + consensus setup (Geth + Teku) backed by a deterministic genesis.
- **Celestia** runs its own local stack (see `docker-compose.celestia.yml`).
- _Soon various rollup stacks!_

You control what runs via `just` by selecting a **part** (`eth`, `cel`, or `all`) and an optional **project name** (`proj`, default: `devnet`).

## Repository layout

- `docker-compose.ethereum.yml` - Ethereum devnet.
  - `values.env` - Source-of-truth inputs for deterministic Ethereum genesis (chain ID, fork versions, validator count, timing, premine, etc.). Used by the Ethereum genesis tooling.
- `docker-compose.celestia.yml` - Celestia devnet.
- `justfile` - Primary UX. Wraps `docker compose` and wires up “part” selection.

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/) (Docker Engine 20.10+ required; must include `docker compose`)
- [just](https://just.systems/) (v1.45+)

## Quickstart

Use `just`:

```bash
# List available commands
just

# Creates **everything from scratch**
just genesis

# Follow logs for everything
just logs

# DESTROYS all devnet data, brings all services down
just clean
```

### `just` arguments

To allow more granular control and operation of multiple independent devnets, all `just` commands follow this shape:

```bash
just <command> <part> <proj>
```

- `part` is one of:

  - `all` - uses all compose files together
  - `eth` - uses `docker-compose.ethereum.yml`
  - `cel` - uses `docker-compose.celestia.yml`

- `proj` is the Docker Compose project name (defaults to `devnet`), which namespaces:

  - container names
  - networks
  - volumes

#### Examples:

```bash
# Run a second independent stack alongside the default one
just up all op-test-1

# Bring down that second stack
just down all op-test-1
```

## Ethereum

**Ethereum** runs an execution + consensus setup (Geth + Teku).

- **Deterministic genesis** - artifacts are produced from [`values.env`](./values.env).
- **Validator material** - The `keygen` container generates a 64-validator keystore from the mnemonic embedded in `values.env`. Teku mounts those keys from `eth-devnet-genesis/keystore/teku-keys` and starts proposing/attesting automatically.
- **Prefunded execution accounts** - The chain ships with prefunded accounts defined externally in [`genesis_constants.star`](https://github.com/ethpandaops/ethereum-package/blob/main/src/prelaunch_data_generator/genesis_constants/genesis_constants.star). Any account listed there can be used immediately for testing without needing faucet funds.


Interact with the network using your preferred tools:

- **Execution RPC (HTTP):** `http://localhost:8545`
- **Engine API:** `http://localhost:8551`  
  - JWT secret at `eth-devnet-genesis/jwt/jwtsecret`
- **Beacon REST API:** `http://localhost:4000`

### Regenerate genesis (DESTROYS existing data)

This resets timestamps and forces fresh genesis generation (and wipes volumes/state for the project):

```bash
just genesis
```

By default, `just genesis` targets `proj=devnet` and performs:

- `clean all devnet` (destroys containers/networks/volumes for both parts under that project)
- updates `GENESIS_TIMESTAMP` in `values.env` to “now”
- `up all devnet`

If you want to run a separate project name:

```bash
just genesis nitro-test-1
```

> Note: `genesis` is intended for the Ethereum devnet flow; it currently cleans/boots `all` for the specified project to keep the full environment consistent.
