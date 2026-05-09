#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo ""
echo "========================================="
echo "   🏠 easy-LocalHub Installer"
echo "========================================="
echo ""

# Check Node.js
if ! command -v node &>/dev/null; then
    echo "❌ Node.js not found! Install it first:"
    echo "   https://nodejs.org/"
    exit 1
fi
echo "✅ Node.js $(node -v) found"

# Check config
if [ ! -f config.json ]; then
    echo ""
    echo "📝 First-time setup — configure your room code"
    echo ""
    read -rp "   Enter room code (e.g. 123456): " ROOM_CODE
    ROOM_CODE=$(echo "$ROOM_CODE" | tr -d '[:space:]')
    if [ -z "$ROOM_CODE" ]; then
        echo "❌ Room code cannot be empty"
        exit 1
    fi
    read -rp "   Enter room name [Default Room]: " ROOM_NAME
    ROOM_NAME=${ROOM_NAME:-"Default Room"}

    cat > config.json << EOF
{
  "roomCode": "$ROOM_CODE",
  "roomName": "$ROOM_NAME",
  "ports": [8080, 8081, 8082, 8083, 8084, 8085]
}
EOF
    echo ""
    echo "✅ config.json created"
else
    echo "✅ config.json found"
    ROOM_CODE=$(python3 -c "import json; print(json.load(open('config.json'))['roomCode'])")
fi

# Create data dirs
mkdir -p data/messages data/uploads/"$ROOM_CODE"
echo "✅ data directories ready"

# Install systemd user service (optional)
if [ "${1:-}" = "--service" ] || [ "${1:-}" = "-s" ]; then
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/easy-localhub.service << SVCEOF
[Unit]
Description=easy-LocalHub LAN server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$(pwd)
ExecStart=$(command -v node) $(pwd)/server.mjs
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
SVCEOF
    systemctl --user daemon-reload
    systemctl --user enable --now easy-localhub.service
    echo ""
    echo "✅ systemd user service installed and started"
    echo "   Manage: systemctl --user {start|stop|restart|status} easy-localhub"
else
    echo ""
    echo "💡 To also install as a systemd auto-start service, run:"
    echo "   bash install.sh --service"
fi

echo ""
echo "========================================="
echo "   ✅ Installation complete!"
echo "========================================="
echo ""
echo "   🚀 Start server:   node server.mjs"
echo "   🔑 Room code:      $ROOM_CODE"
echo ""
echo "   Other devices on the same Wi-Fi can"
echo "   open the LAN URL shown at startup."
echo ""
