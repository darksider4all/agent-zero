#!/usr/bin/env bash
# agent-zero — zero-downtime deploy with FAISS backup + healthcheck triple + auto-rollback.
# Goes into: agent-zero/scripts/deploy.sh
# Modelled on /root/docker/finched/deploy/deploy.sh — same shape, same logging.
#
# Usage on agent LXC (.115), as `deploy` user via sudo where needed:
#   ./deploy.sh <tag>            # deploy a specific image tag
#   ./deploy.sh latest           # whatever ':latest' points at right now
#   ./deploy.sh --rollback       # restore previous image + FAISS backup
#
# Healthcheck triple (all three must pass to consider a deploy good):
#   1. HTTP 302 on http://localhost:50080/
#   2. MCP SSE returns 200 on /mcp/t-<token>/sse
#   3. memory doc count ≥ pre-deploy baseline − 2 (tolerance for in-flight saves)
#   4. (bonus) docker logs since restart contains "MemPalace patches installed:"

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────
PROJECT_DIR="/root/agent-zero-data/docker/run"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
SERVICE="agent-zero"
IMAGE_BASE="agent-zero-homelab"
MEMORY_DIR="/root/agent-zero-data/usr/memory/default"
HEALTH_URL="http://localhost:50080/"
HEALTH_RETRIES=18           # × 5 s = 90 s window
HEALTH_INTERVAL=5
PREV_STATE_FILE="/root/agent-zero-data/.deploy-prev-state"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ── Colours ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*"; }
ok()   { echo -e "${GREEN}✔${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
fail() { echo -e "${RED}✖${NC} $*"; }

# ── Healthcheck helpers ─────────────────────────────────────────────────
check_http() {
    local code
    code=$(curl -sIo /dev/null -w '%{http_code}' --max-time 3 "$HEALTH_URL" || echo "000")
    [[ "$code" == "302" ]] || { warn "HTTP got $code, expected 302"; return 1; }
}

check_mcp() {
    # Pull current MCP token from inside the container (derived, not stored)
    local token code
    token=$(sudo docker exec "$SERVICE" /opt/venv-a0/bin/python3 -c \
        "from helpers import settings; print(settings.get_settings()['mcp_server_token'])" 2>/dev/null) || return 1
    [[ -n "$token" ]] || { warn "MCP token unreadable"; return 1; }
    code=$(curl -so /dev/null -w '%{http_code}' --max-time 2 \
        "http://localhost:50080/mcp/t-${token}/sse" || echo "000")
    [[ "$code" == "200" ]] || { warn "MCP SSE got $code, expected 200"; return 1; }
}

doc_count() {
    sudo docker exec "$SERVICE" /opt/venv-a0/bin/python3 -c \
        "import pickle; d,_=pickle.load(open('/a0/usr/memory/default/index.pkl','rb')); print(len(d._dict))" \
        2>/dev/null || echo "0"
}

check_doc_count() {
    local baseline=$1
    local current
    current=$(doc_count)
    [[ "$current" -ge $((baseline - 2)) ]] || {
        fail "doc count regressed: baseline=$baseline current=$current"
        return 1
    }
    ok "doc count: baseline=$baseline current=$current"
}

check_patches_log() {
    sudo docker logs --since 60s "$SERVICE" 2>&1 \
        | grep -q "MemPalace patches installed:" \
        || { warn "MemPalace patches install line not in last 60s of logs"; return 1; }
    ok "MemPalace patches confirmed in logs"
}

healthcheck_triple() {
    local baseline=$1
    local attempt
    for attempt in $(seq 1 $HEALTH_RETRIES); do
        log "healthcheck attempt $attempt/$HEALTH_RETRIES"
        if check_http && check_mcp && check_doc_count "$baseline"; then
            check_patches_log || warn "patches log check soft-failed (deploy continues)"
            return 0
        fi
        sleep $HEALTH_INTERVAL
    done
    return 1
}

# ── Pre-deploy: capture state for rollback ──────────────────────────────
snapshot_state() {
    local current_image baseline_docs
    current_image=$(sudo docker inspect --format='{{.Config.Image}}' "$SERVICE" 2>/dev/null || echo "none")
    baseline_docs=$(doc_count)
    cat > "$PREV_STATE_FILE" <<EOF
PREV_IMAGE=$current_image
PREV_DOC_COUNT=$baseline_docs
PREV_TIMESTAMP=$TIMESTAMP
EOF
    ok "state snapshotted: image=$current_image docs=$baseline_docs"
}

backup_memory() {
    for f in index.faiss index.pkl index.faiss.sha256; do
        sudo cp "$MEMORY_DIR/$f" "$MEMORY_DIR/${f}.bak_deploy_${TIMESTAMP}"
    done
    ok "memory backup tagged _bak_deploy_${TIMESTAMP}"
}

# ── Deploy ──────────────────────────────────────────────────────────────
deploy() {
    local tag="${1:-latest}"
    local target_image="${IMAGE_BASE}:${tag}"

    log "starting deploy → $target_image"
    sudo docker image inspect "$target_image" >/dev/null 2>&1 \
        || { fail "image $target_image not present locally; build first"; exit 1; }

    snapshot_state
    backup_memory

    # shellcheck source=/dev/null
    source "$PREV_STATE_FILE"

    log "swapping container (compose recreate)"
    cd "$PROJECT_DIR"
    # The compose file pins image: by tag — we set it via env override so
    # we don't mutate the committed file.
    sudo IMAGE_TAG="$target_image" docker compose up -d --force-recreate "$SERVICE"

    log "waiting for run_ui to be RUNNING"
    for _ in $(seq 1 18); do
        if sudo docker exec "$SERVICE" supervisorctl status run_ui 2>/dev/null | grep -q RUNNING; then
            ok "run_ui RUNNING"
            break
        fi
        sleep 5
    done

    if healthcheck_triple "$PREV_DOC_COUNT"; then
        ok "deploy succeeded → $target_image"
        # Prune old backups: keep last 5 by mtime
        sudo find "$MEMORY_DIR" -maxdepth 1 -name 'index.*.bak_deploy_*' -type f \
            -printf '%T@ %p\n' | sort -rn | tail -n +16 | awk '{print $2}' \
            | xargs -r sudo rm -v
        exit 0
    fi

    fail "healthcheck FAILED — rolling back to $PREV_IMAGE"
    rollback
    exit 1
}

# ── Rollback ────────────────────────────────────────────────────────────
rollback() {
    [[ -r "$PREV_STATE_FILE" ]] || { fail "no prev-state file at $PREV_STATE_FILE"; exit 1; }
    # shellcheck source=/dev/null
    source "$PREV_STATE_FILE"

    log "restoring image to $PREV_IMAGE"
    cd "$PROJECT_DIR"
    sudo IMAGE_TAG="$PREV_IMAGE" docker compose up -d --force-recreate "$SERVICE"

    log "restoring memory store from _bak_deploy_${PREV_TIMESTAMP}"
    for f in index.faiss index.pkl index.faiss.sha256; do
        sudo cp "$MEMORY_DIR/${f}.bak_deploy_${PREV_TIMESTAMP}" "$MEMORY_DIR/$f"
    done

    for _ in $(seq 1 18); do
        if sudo docker exec "$SERVICE" supervisorctl status run_ui 2>/dev/null | grep -q RUNNING; then
            break
        fi
        sleep 5
    done

    if healthcheck_triple "$PREV_DOC_COUNT"; then
        ok "rollback succeeded; live on $PREV_IMAGE"
    else
        fail "rollback ALSO failed — manual intervention required"
    fi
}

# ── Main ────────────────────────────────────────────────────────────────
case "${1:-}" in
    --rollback) rollback ;;
    -h|--help)  grep '^#' "$0" | head -25 ;;
    "")         fail "usage: $0 <tag> | --rollback"; exit 2 ;;
    *)          deploy "$1" ;;
esac
