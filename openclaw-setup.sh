#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="easy-LocalHub"
DEFAULT_PORTS="[8080, 8081, 8082, 8083, 8084, 8085]"
ACTION="${1:-setup}"

log() { printf '%s\n' "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }
random_code() { node -e 'console.log(String(Math.floor(100000 + Math.random() * 900000)))'; }
json_escape() { node -e 'process.stdout.write(JSON.stringify(process.argv[1]).slice(1,-1))' "$1"; }

ensure_node() {
  if ! need_cmd node; then
    log "❌ Node.js is required for ${APP_NAME}. Install Node.js first: https://nodejs.org/"
    exit 1
  fi
  log "✅ Node.js $(node -v) found"
}

ensure_config() {
  if [ -f config.json ]; then
    ROOM_CODE=$(node -e "const fs=require('fs'); console.log(JSON.parse(fs.readFileSync('config.json','utf8')).roomCode || '')")
    log "✅ config.json found (room: ${ROOM_CODE})"
    return
  fi

  ROOM_CODE="${EASY_LOCALHUB_ROOM_CODE:-}"
  ROOM_NAME="${EASY_LOCALHUB_ROOM_NAME:-OpenClaw LocalHub}"
  if [ -z "$ROOM_CODE" ] && [ -t 0 ]; then
    read -rp "Enter easy-LocalHub room code [auto]: " ROOM_CODE
    read -rp "Enter room name [${ROOM_NAME}]: " input_name
    ROOM_NAME="${input_name:-$ROOM_NAME}"
  fi
  ROOM_CODE="${ROOM_CODE:-$(random_code)}"

  cat > config.json <<JSON
{
  "roomCode": "$(json_escape "$ROOM_CODE")",
  "roomName": "$(json_escape "$ROOM_NAME")",
  "ports": ${EASY_LOCALHUB_PORTS:-$DEFAULT_PORTS}
}
JSON
  log "✅ config.json created (room: ${ROOM_CODE})"
}

prepare_localhub() {
  ensure_node
  ensure_config
  mkdir -p "data/messages" "data/uploads/${ROOM_CODE}"
  log "✅ data directories ready"
}

install_openclaw() {
  if need_cmd openclaw; then
    log "✅ OpenClaw $(openclaw --version 2>/dev/null || true) found"
    return
  fi
  if ! need_cmd curl; then
    log "❌ curl is required to install OpenClaw with the official installer"
    exit 1
  fi
  log "📦 Installing OpenClaw with the official installer (no onboarding yet)..."
  curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
  export PATH="$(npm prefix -g 2>/dev/null)/bin:$PATH"
  if ! need_cmd openclaw; then
    log "❌ OpenClaw installed, but 'openclaw' is not on PATH. Open a new shell or add npm global bin to PATH."
    exit 1
  fi
  log "✅ OpenClaw installed"
}

start_localhub() {
  prepare_localhub
  if [ "${EASY_LOCALHUB_SERVICE:-0}" = "1" ] && need_cmd systemctl; then
    bash install.sh --service
    return
  fi
  if [ -f data/localhub.pid ] && kill -0 "$(cat data/localhub.pid)" 2>/dev/null; then
    log "✅ easy-LocalHub is already running (pid $(cat data/localhub.pid))"
  else
    nohup node server.mjs > data/easy-localhub.log 2>&1 &
    echo $! > data/localhub.pid
    sleep 1
    log "✅ easy-LocalHub started (pid $(cat data/localhub.pid))"
  fi
  show_connection
}

show_connection() {
  PORT="$(cat data/port.txt 2>/dev/null || node -e "const c=require('./config.json'); console.log((c.ports&&c.ports[0])||8080)")"
  log ""
  log "🔗 Open in browser: http://localhost:${PORT}/"
  log "🔑 Room code: ${ROOM_CODE:-$(node -e "const c=require('./config.json'); console.log(c.roomCode)")}"
  log "📄 Logs: data/easy-localhub.log"
}

run_onboarding() {
  install_openclaw
  if [ "${OPENCLAW_SKIP_ONBOARD:-0}" = "1" ]; then
    log "⏭️  Skipping OpenClaw onboarding because OPENCLAW_SKIP_ONBOARD=1"
    return
  fi
  log "🧭 Starting OpenClaw onboarding. Follow the prompts to choose model/auth/channel settings."
  openclaw onboard --install-daemon
}

open_dashboard() {
  install_openclaw
  log "🌐 Opening OpenClaw dashboard..."
  openclaw dashboard
}

case "$ACTION" in
  setup)
    start_localhub
    run_onboarding
    ;;
  localhub|start-localhub)
    start_localhub
    ;;
  openclaw|setup-openclaw)
    run_onboarding
    ;;
  dashboard)
    open_dashboard
    ;;
  status)
    prepare_localhub
    show_connection
    if need_cmd openclaw; then openclaw doctor || true; else log "OpenClaw: not installed"; fi
    ;;
  *)
    cat <<USAGE
Usage: bash openclaw-setup.sh [setup|localhub|openclaw|dashboard|status]

Environment variables for robots/CI:
  EASY_LOCALHUB_ROOM_CODE=123456       Set room code without prompts
  EASY_LOCALHUB_ROOM_NAME="Demo Room"   Set room name without prompts
  EASY_LOCALHUB_SERVICE=1              Install easy-LocalHub as systemd user service
  OPENCLAW_SKIP_ONBOARD=1              Install/start LocalHub but skip OpenClaw onboarding
USAGE
    exit 2
    ;;
esac
