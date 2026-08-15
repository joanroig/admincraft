#!/usr/bin/env bash
#
# Updates the Minecraft stack: pulls newer container images and recreates the
# stack. Two separate things get updated by this:
#
#   1. The Bedrock server binary  - itzg's entry script re-checks Mojang's API
#                                   on every container start, so a restart is
#                                   enough.
#   2. The container images        - only ever update via an explicit pull.
#
# Skipping (2) is what strands the server: an old image carries the old version
# lookup, which broke when Mojang changed their download page.
#
set -euo pipefail

COMPOSE_DIR=/home/ubuntu
BACKUP_DIR="${COMPOSE_DIR}/backups"

log() { echo "[$(date -u '+%Y-%m-%d %H:%M:%SZ')] $*"; }

newest_backup() {
    find "${BACKUP_DIR}" -maxdepth 1 -name '*.mcworld' -printf '%T@\n' 2>/dev/null \
        | sort -n | tail -1
}

cd "${COMPOSE_DIR}"

log "=== update run starting ==="

before=$(newest_backup)

# Give anyone online a heads-up. Harmless if nobody is connected, and the
# server may legitimately be down already - don't abort the update over it.
if docker exec minecraft send-command say "Server restarting for updates in 60s" >/dev/null 2>&1; then
    log "warned online players; waiting 60s"
    sleep 60
else
    log "could not reach server console (not running?); continuing"
fi

log "pulling images"
docker compose pull

# Forced recreate: the Bedrock version check only runs at container start, so
# without this a night with no image change would never pick up a new server
# build - and the backup verification below would have nothing to verify.
log "recreating stack"
docker compose up -d --force-recreate

log "pruning dangling images"
docker image prune -f

# The backup container takes a snapshot on start (runInitialBackup: true in
# the backups config) after its 60s startupDelay. Confirm it landed
# rather than assuming it did - a silently broken backup chain is the one
# failure that makes unattended updates dangerous.
log "waiting for post-update backup"
for _ in $(seq 1 30); do
    sleep 10
    after=$(newest_backup)
    if [[ -n "${after}" && "${after}" != "${before}" ]]; then
        log "OK backup landed: $(ls -t "${BACKUP_DIR}"/*.mcworld | head -1)"
        break
    fi
done

if [[ "$(newest_backup)" == "${before}" ]]; then
    log "WARNING no new backup appeared within 5 minutes - check 'docker compose logs backup'"
fi

version=$(docker compose logs minecraft --tail 300 2>/dev/null \
    | grep -oE 'Version: [0-9.]+' | tail -1 || true)
log "server ${version:-version unknown}"

docker compose ps --format '{{.Name}}: {{.Status}}' | while read -r line; do log "  ${line}"; done

log "=== update run finished ==="
