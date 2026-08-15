#!/usr/bin/env bash
#
# Sets up a Minecraft server and the Admincraft bridge in one go.
#
#   bash quickstart.sh                 # asks which edition
#   bash quickstart.sh --edition java  # or say so up front
#
# Writes a compose file, generates the secrets, starts the stack, and prints
# what to type into Admincraft. It never edits an existing compose file: if one
# is already here it stops and points at the guide for existing servers.
set -euo pipefail

EDITION=""
DIR="$PWD"

while [ $# -gt 0 ]; do
  case "$1" in
    --edition) EDITION="${2:-}"; shift 2 ;;
    --dir) DIR="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

say() { printf '\n\033[1m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1" >&2; exit 1; }

# ---- checks ------------------------------------------------------------------

command -v docker >/dev/null || fail "Docker is not installed. See https://docs.docker.com/engine/install/"
docker compose version >/dev/null 2>&1 || fail "The Docker Compose plugin is missing. See https://docs.docker.com/compose/install/"
docker info >/dev/null 2>&1 || fail "Cannot talk to Docker. Try again with sudo, or add yourself to the docker group."

mkdir -p "$DIR"
cd "$DIR"

if [ -e docker-compose.yml ]; then
  fail "docker-compose.yml already exists here.
This script only sets up a new server. To add Admincraft to a server you
already run, follow:
https://joanroig.github.io/admincraft/docs/getting-started/existing-server/"
fi

if [ -z "$EDITION" ]; then
  printf 'Which edition? [bedrock/java] '
  read -r EDITION
fi
EDITION="$(printf '%s' "$EDITION" | tr '[:upper:]' '[:lower:]')"
[ "$EDITION" = "bedrock" ] || [ "$EDITION" = "java" ] || fail "Edition must be bedrock or java."

# ---- secrets -----------------------------------------------------------------

# openssl is not guaranteed to be present, and a weak key here is the whole
# security of the bridge, so fall back to the kernel rather than to something
# predictable.
random_hex() {
  if command -v openssl >/dev/null; then
    openssl rand -hex 32
  else
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'
  fi
}

SECRET_KEY="$(random_hex)"
RCON_PASSWORD="$(random_hex)"

# ---- compose file ------------------------------------------------------------

if [ "$EDITION" = "bedrock" ]; then
  cat > docker-compose.yml <<COMPOSE
services:
  minecraft:
    container_name: minecraft
    image: itzg/minecraft-bedrock-server
    restart: always
    environment:
      EULA: "TRUE"
      # Required so the bridge can reach the server console.
      ENABLE_SSH: "true"
      GAMEMODE: survival
      DIFFICULTY: normal
      SERVER_NAME: Admincraft Server
    ports:
      - 19132:19132/udp
    volumes:
      - ./minecraft:/data
    stdin_open: true
    tty: true

  websocket:
    container_name: websocket
    image: joanroig/admincraft-websocket:latest
    restart: always
    depends_on:
      minecraft:
        condition: service_healthy
    ports:
      # Reachable only from this machine. Tailscale, a VPN or a LAN carries it
      # the rest of the way; see the guide linked at the end.
      - 8080:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      SECRET_KEY: ${SECRET_KEY}
      USE_SSL: "false"
      SERVER_TYPE: bedrock
      MC_NAME: minecraft
COMPOSE
else
  cat > docker-compose.yml <<COMPOSE
services:
  minecraft:
    container_name: minecraft
    image: itzg/minecraft-server
    restart: always
    environment:
      EULA: "TRUE"
      TYPE: PAPER
      ENABLE_RCON: "true"
      RCON_PASSWORD: ${RCON_PASSWORD}
      MEMORY: 2G
    ports:
      - 25565:25565
    # Never published: RCON is unencrypted and stays on the Docker network.
    expose:
      - "25575"
    volumes:
      - ./minecraft:/data
    tty: true

  websocket:
    container_name: websocket
    image: joanroig/admincraft-websocket:latest
    restart: always
    depends_on:
      - minecraft
    ports:
      - 8080:8080
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      SECRET_KEY: ${SECRET_KEY}
      USE_SSL: "false"
      SERVER_TYPE: java
      MC_NAME: minecraft
      RCON_HOST: minecraft
      RCON_PORT: "25575"
      RCON_PASSWORD: ${RCON_PASSWORD}
COMPOSE
fi

say "Starting the stack. The first run downloads the server, which takes a few minutes."
docker compose up -d

# ---- what to do next ---------------------------------------------------------

say "Done. In Admincraft, add a server with:"
cat <<DETAILS

  Minecraft edition   ${EDITION}
  Host or IP          this machine's address
  Port                8080
  Bridge secret key   ${SECRET_KEY}
  Connection type     Private network

The key is also in docker-compose.yml if you need it again.
DETAILS

say "One thing left"
cat <<'NEXT'
Port 8080 can run commands on your server, so it must not face the internet.
The usual arrangement is Tailscale between this machine and your devices, with
8080 closed in the firewall:

  https://joanroig.github.io/admincraft/docs/server/SERVER_SETUP/#connect-admincraft-with-tailscale-recommended
NEXT
