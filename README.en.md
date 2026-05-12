# 🏠 easy-LocalHub 2.0.0

<p align="center">
  <strong>Turn one computer into an instant chat + file hub for the same Wi‑Fi</strong><br>
  <span>No npm dependencies · Local-first data · One-command OpenClaw install/start/setup</span>
</p>

<p align="center">
  <a href="#-start-in-30-seconds">Start in 30 seconds</a> ·
  <a href="#-openclaw-one-command-entrypoint">OpenClaw entrypoint</a> ·
  <a href="#-why-people-want-it">Why use it</a> ·
  <a href="#-configuration--operations">Operations</a> ·
  <a href="README.md">简体中文</a>
</p>

> Perfect for meeting rooms, classrooms, temporary project teams, and home LANs: the host starts the service, participants open the LAN URL, enter the room code, then chat, upload folders, and download files. Version 2.0.0 fixes Chinese/non-ASCII filename downloads and promotes OpenClaw automation to the top of the README.

---

## 🚀 Start in 30 seconds

```bash
git clone https://github.com/zeyuShawn/easy-LocalHub.git
cd easy-LocalHub
bash install.sh
node server.mjs
```

The server prints something like:

```text
🚀 easy-LocalHub running!
   Local:   http://localhost:8080/
   LAN:     http://192.168.1.100:8080/

🔑 Room code: 123456
```

Share the **LAN URL** and **room code** with people on the same Wi‑Fi.

---

## 🤖 OpenClaw one-command entrypoint

If you want an OpenClaw robot to install, start, and configure easy-LocalHub from code, run:

```bash
bash install.sh --openclaw
```

Or use the dedicated script with automation-friendly environment variables:

```bash
EASY_LOCALHUB_ROOM_CODE=123456 \
EASY_LOCALHUB_ROOM_NAME="OpenClaw LocalHub" \
bash openclaw-setup.sh setup
```

The flow will:

1. Check Node.js.
2. Create `config.json` and `data/` directories.
3. Start easy-LocalHub and print the browser URL, room code, and log path.
4. Install OpenClaw with the official installer if `openclaw` is not available.
5. Run `openclaw onboard --install-daemon` for auth, model, gateway, and daemon setup.

Useful commands:

```bash
bash openclaw-setup.sh localhub       # install/start easy-LocalHub only
bash openclaw-setup.sh openclaw       # install/configure OpenClaw only
bash openclaw-setup.sh dashboard      # open the OpenClaw Dashboard
bash openclaw-setup.sh status         # show the LocalHub URL and run OpenClaw checks
```

Automation variables:

| Variable | Purpose |
| --- | --- |
| `EASY_LOCALHUB_ROOM_CODE` | Set the room code without prompts. |
| `EASY_LOCALHUB_ROOM_NAME` | Set the room name without prompts. |
| `EASY_LOCALHUB_SERVICE=1` | Install easy-LocalHub as a systemd user service. |
| `OPENCLAW_SKIP_ONBOARD=1` | Install/start LocalHub and OpenClaw, but skip interactive onboarding. |

OpenClaw official installation docs: <https://docs.openclaw.ai/install>

---

## ✨ Why people want it

| Situation | Value |
| --- | --- |
| Share slides one minute before a meeting | No group chat, no cloud drive; participants open the LAN URL. |
| Move files between phone, tablet, and laptop | Upload in a browser; the host keeps the files locally. |
| Keep lightweight discussion context | Chat is persisted as JSONL and survives refreshes. |
| Transfer a folder as-is | Drag an entire folder and keep its structure. |
| Stay local-first | Messages and files are written to the host machine's `data/` directory. |
| Automate deployment | OpenClaw/scripts can install, start, and configure it in one command. |

---

## ✅ What changed in 2.0.0

- **Fixed non-ASCII filename downloads**: `Content-Disposition` now uses RFC 5987 `filename*` encoding plus an ASCII fallback, avoiding Node.js `ERR_INVALID_CHAR` errors.
- **OpenClaw integration**: added `openclaw-setup.sh` and `bash install.sh --openclaw` so robots can install, start, and configure the app.
- **README refresh**: Chinese and English READMEs now lead with instant usage, OpenClaw automation, and product value.
- **Version bump**: app version is now `2.0.0`; health checks return the version and the UI footer shows it.

---

## 🎯 Feature map

- 📂 **File relay**: drag files or entire folders; directory structure is preserved.
- ⬇️ **Reliable downloads**: Chinese, spaces, and common symbols in filenames are supported.
- 💬 **Group chat**: JSONL persistence keeps messages after refresh.
- 🔑 **Room-code verification**: the server validates room joins; health checks do not reveal the room code.
- 📱 **Cross-platform browser access**: Windows, macOS, Linux, iOS, and Android modern browsers work.
- 🚀 **Zero dependency runtime**: plain Node.js HTTP server; no npm package install required.
- 🔄 **Optional auto-start**: install as a systemd user service.
- 🛡️ **Basic hardening**: path boundary checks, input limits, security response headers, upload size cap.

---

## 🖼️ Architecture diagrams

![easy-LocalHub architecture](docs/images/architecture.svg)

![easy-LocalHub workflow](docs/images/workflow.svg)

![easy-LocalHub security and data boundaries](docs/images/security-data.svg)

---

## ⚙️ Configuration & operations

`install.sh` guides first-time setup. You can also edit `config.json` manually:

```json
{
  "roomCode": "123456",
  "roomName": "My Room",
  "ports": [8080, 8081, 8082, 8083, 8084, 8085]
}
```

Install as a systemd user service:

```bash
bash install.sh --service
systemctl --user status easy-localhub
systemctl --user restart easy-localhub
journalctl --user -u easy-localhub -f
```

---

## 🧭 API and data flow

| Capability | Path | Notes |
| --- | --- | --- |
| Health check | `GET /api/health` | Returns status, version, and LAN IPs; does not return the room code. |
| Join room | `POST /api/room/join` | Server validates `roomCode`. |
| Get messages | `GET /api/room/:code/messages` | Returns recent messages, default max 200. |
| Send message | `POST /api/room/:code/messages` | Appends to `data/messages/<code>.jsonl`. |
| Upload file | `POST /api/room/:code/upload` | Writes to `data/uploads/<code>/`; 256 MB request limit. |
| List files | `GET /api/room/:code/files` | Recursively lists up to 5000 files/directories. |
| Download file | `GET /api/room/:code/files/:path` | Sanitizes paths and validates directory boundaries before streaming. |

---

## 📁 Project structure

```text
easy-LocalHub/
├── server.mjs                 # Node.js HTTP server with zero npm dependencies
├── public/index.html          # Frontend SPA (chat + file manager)
├── docs/images/               # README SVG diagrams
├── install.sh                 # First-time setup + systemd + OpenClaw entrypoint
├── openclaw-setup.sh          # One-command OpenClaw/robot install, start, setup script
├── config.example.json        # Example config
├── README.md                  # Chinese README
├── README.en.md               # English README
└── LICENSE                    # MIT
```

Generated after runtime setup:

```text
├── config.json                # Your room code and port config (gitignored)
└── data/                      # Chat logs, uploads, selected port, logs (gitignored)
```

---

## 🛡️ Security boundaries

- Use it on trusted LANs; do not expose it directly to the public internet.
- The room code is a lightweight access gate, not a full account/auth system.
- Uploaded files stay on the host; clean `data/uploads/` periodically.
- OpenClaw can automate actions, so use dedicated API keys/accounts and least-privilege settings.

---

## 📄 License

MIT
