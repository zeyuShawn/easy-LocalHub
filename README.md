# 🏠 easy-LocalHub 2.0.0

<p align="center">
  <strong>一台电脑，马上变成同 Wi‑Fi 下的聊天 + 文件中转站</strong><br>
  <span>零 npm 依赖 · 数据留在本机 · 支持 OpenClaw 一键安装/启动/设置</span>
</p>

<p align="center">
  <a href="#-30-秒开始使用">30 秒开始</a> ·
  <a href="#-openclaw-一键接入醒目入口">OpenClaw 一键接入</a> ·
  <a href="#-你会喜欢它的原因">产品亮点</a> ·
  <a href="#-配置与运维">配置与运维</a> ·
  <a href="README.en.md">English</a>
</p>

> 适合会议室、教室、临时项目组和家庭局域网：主持人启动服务，其他人打开 LAN 地址、输入房间码，就能聊天、上传文件夹、下载文件。2.0.0 修复了中文文件名下载失败的问题，并把 OpenClaw 自动化入口放到首屏。

---

## 🚀 30 秒开始使用

```bash
git clone https://github.com/zeyuShawn/easy-LocalHub.git
cd easy-LocalHub
bash install.sh
node server.mjs
```

启动后终端会显示：

```text
🚀 easy-LocalHub running!
   Local:   http://localhost:8080/
   LAN:     http://192.168.1.100:8080/

🔑 Room code: 123456
```

把 **LAN 地址** 和 **房间码** 发给同一 Wi‑Fi 下的参与者即可使用。

---

## 🤖 OpenClaw 一键接入（醒目入口）

如果你希望让 OpenClaw 机器人通过代码自动安装、启动并进入设置流程，直接运行：

```bash
bash install.sh --openclaw
```

也可以使用独立脚本，便于机器人/CI 指定参数：

```bash
EASY_LOCALHUB_ROOM_CODE=123456 \
EASY_LOCALHUB_ROOM_NAME="OpenClaw LocalHub" \
bash openclaw-setup.sh setup
```

这个流程会：

1. 检查 Node.js。
2. 创建 `config.json` 和 `data/` 目录。
3. 启动 easy-LocalHub，并打印浏览器地址、房间码和日志路径。
4. 如果本机没有 OpenClaw，使用官方安装器安装。
5. 运行 `openclaw onboard --install-daemon` 进入 OpenClaw 认证、模型、网关/守护进程设置。

常用命令：

```bash
bash openclaw-setup.sh localhub       # 只安装/启动 easy-LocalHub
bash openclaw-setup.sh openclaw       # 只安装/设置 OpenClaw
bash openclaw-setup.sh dashboard      # 打开 OpenClaw Dashboard
bash openclaw-setup.sh status         # 查看 LocalHub 地址并运行 OpenClaw 检查
```

可用于机器人自动化的环境变量：

| 变量 | 作用 |
| --- | --- |
| `EASY_LOCALHUB_ROOM_CODE` | 无交互设置房间码。 |
| `EASY_LOCALHUB_ROOM_NAME` | 无交互设置房间名。 |
| `EASY_LOCALHUB_SERVICE=1` | 将 easy-LocalHub 安装为 systemd 用户服务。 |
| `OPENCLAW_SKIP_ONBOARD=1` | 只完成 LocalHub/OpenClaw 安装，跳过交互式 onboarding。 |

OpenClaw 官方安装说明：<https://docs.openclaw.ai/install>

---

## ✨ 你会喜欢它的原因

| 用户场景 | 产品价值 |
| --- | --- |
| 会前 1 分钟临时发资料 | 不建群、不传云盘，打开 LAN 地址就能取文件。 |
| 手机、平板、电脑互传 | 浏览器上传，宿主机保存，跨平台无客户端。 |
| 临时讨论和资料沉淀 | 聊天 JSONL 持久化，刷新后仍可查看。 |
| 文件夹原样转移 | 拖拽整个文件夹上传，保留目录结构。 |
| 本地优先 | 文件和消息默认只写入当前机器的 `data/`。 |
| 自动化部署 | OpenClaw/脚本可一键安装、启动、设置。 |

---

## ✅ 2.0.0 更新重点

- **修复中文文件名下载失败**：`Content-Disposition` 对非 ASCII 文件名使用 RFC 5987 `filename*` 编码，同时提供 ASCII fallback，避免 Node.js 抛出 `ERR_INVALID_CHAR`。
- **OpenClaw 集成**：新增 `openclaw-setup.sh` 和 `bash install.sh --openclaw`，让机器人可通过代码完成安装、启动和设置。
- **文档重构**：中英文 README 以“立即使用 + OpenClaw 入口 + 产品价值”的结构展示。
- **版本升级**：应用版本更新为 `2.0.0`，健康检查返回版本号，前端页脚显示版本号。

---

## 🎯 功能地图

- 📂 **文件中转**：拖拽上传文件或整个文件夹，保留目录结构。
- ⬇️ **可靠下载**：支持中文、空格和常见符号文件名下载。
- 💬 **群聊消息**：聊天记录以 JSONL 持久化，刷新不丢失。
- 🔑 **房间码校验**：加入接口由服务端校验房间码，健康检查不暴露房间码。
- 📱 **全平台访问**：Windows / macOS / Linux / iOS / Android 的现代浏览器均可使用。
- 🚀 **零依赖运行**：纯 Node.js HTTP 服务，不需要安装 npm 包。
- 🔄 **可选开机自启**：支持安装为 systemd 用户服务。
- 🛡️ **基础安全加固**：路径边界校验、输入长度限制、响应安全头、上传体积限制。

---

## 🖼️ 架构图解

![easy-LocalHub architecture](docs/images/architecture.svg)

![easy-LocalHub workflow](docs/images/workflow.svg)

![easy-LocalHub security and data boundaries](docs/images/security-data.svg)

---

## ⚙️ 配置与运维

`install.sh` 首次运行时会引导你设置，也可以手动编辑 `config.json`：

```json
{
  "roomCode": "123456",
  "roomName": "我的房间",
  "ports": [8080, 8081, 8082, 8083, 8084, 8085]
}
```

安装为 systemd 用户服务：

```bash
bash install.sh --service
systemctl --user status easy-localhub
systemctl --user restart easy-localhub
journalctl --user -u easy-localhub -f
```

---

## 🧭 API 与数据流

| 能力 | 路径 | 说明 |
| --- | --- | --- |
| 健康检查 | `GET /api/health` | 返回服务状态、版本号与 LAN IP；不会返回房间码。 |
| 加入房间 | `POST /api/room/join` | 服务端校验 `roomCode`。 |
| 拉取消息 | `GET /api/room/:code/messages` | 返回最近消息，默认最多 200 条。 |
| 发送消息 | `POST /api/room/:code/messages` | 写入 `data/messages/<code>.jsonl`。 |
| 上传文件 | `POST /api/room/:code/upload` | 写入 `data/uploads/<code>/`，单请求上限 256 MB。 |
| 文件列表 | `GET /api/room/:code/files` | 递归列出最多 5000 个文件/目录项。 |
| 下载文件 | `GET /api/room/:code/files/:path` | 经路径清理与目录边界校验后返回文件。 |

---

## 📁 项目结构

```text
easy-LocalHub/
├── server.mjs                 # HTTP 服务（零依赖 Node.js）
├── public/index.html          # 前端 SPA（聊天 + 文件管理）
├── docs/images/               # README 图解 SVG
├── install.sh                 # 首次部署 + systemd + OpenClaw 入口
├── openclaw-setup.sh          # OpenClaw/机器人一键安装、启动、设置脚本
├── config.example.json        # 配置示例
├── README.md                  # 中文说明
├── README.en.md               # English README
└── LICENSE                    # MIT
```

运行后会额外生成：

```text
├── config.json                # 你的房间码和端口配置（gitignored）
└── data/                      # 聊天记录、上传文件、运行端口、日志（gitignored）
```

---

## 🛡️ 安全边界

- 建议只在可信局域网内使用，不要直接暴露到公网。
- 房间码适合作为轻量访问门槛，不等同于完整账号系统。
- 上传文件会保存在宿主机本地，请定期清理 `data/uploads/`。
- OpenClaw 具备自动化能力，建议使用专用 API Key/账号，并遵循最小权限原则。

---

## 📄 License

MIT
