# 🏠 easy-LocalHub

<p align="center">
  <strong>零依赖 · 一键部署 · 数据留在本机的局域网协作空间</strong>
</p>

<p align="center">
  <a href="#-快速开始">快速开始</a> ·
  <a href="#-功能地图">功能地图</a> ·
  <a href="#-架构图解">架构图解</a> ·
  <a href="#-安全边界">安全边界</a> ·
  <a href="#-常见问题">常见问题</a>
</p>

<p align="center">
  <strong>语言 / Language：</strong> 简体中文 · <a href="README.en.md">English</a>
</p>

> 把一台电脑变成同 Wi‑Fi 下的临时协作站：朋友打开浏览器，输入房间码，就能聊天、传文件、下载文件。无需数据库、无需 `npm install`，消息和上传内容都保存在你的机器上。

---

## ✨ 适合什么场景？

| 场景 | 你会得到什么 |
| --- | --- |
| 会议室 / 教室临时分发资料 | 同一 Wi‑Fi 下直接打开 LAN 地址下载文件 |
| 手机 ↔ 电脑互传文件 | 浏览器上传，宿主机本地保存 |
| 小团队临时沟通 | 简单群聊，刷新后消息仍在 |
| 不想把文件传到云端 | 数据只写入本机 `data/` 目录 |

---

## 🎯 功能地图

- 📂 **文件中转**：拖拽上传文件或整个文件夹，保留目录结构。
- 💬 **群聊消息**：聊天记录以 JSONL 持久化，刷新不丢失。
- 🔑 **房间码校验**：加入接口由服务端校验房间码，健康检查不暴露房间码。
- 📱 **全平台访问**：Windows / macOS / Linux / iOS / Android 的现代浏览器均可使用。
- 🚀 **零依赖运行**：纯 Node.js HTTP 服务，不需要安装 npm 包。
- 🔄 **可选开机自启**：支持安装为 systemd 用户服务。
- 🛡️ **基础安全加固**：路径边界校验、输入长度限制、响应安全头、上传体积限制。

---

## 🖼️ 架构图解

### 1. 局域网协作架构

![easy-LocalHub architecture](docs/images/architecture.svg)

### 2. 从部署到协作的流程

![easy-LocalHub workflow](docs/images/workflow.svg)

### 3. 数据边界与安全加固

![easy-LocalHub security and data boundaries](docs/images/security-data.svg)

---

## 🚀 快速开始

```bash
# 1. 克隆到你的电脑
git clone https://github.com/zeyuShawn/easy-LocalHub.git
cd easy-LocalHub

# 2. 首次安装并设置房间码
bash install.sh

# 3. 启动服务
node server.mjs
```

启动后终端会打印类似：

```text
🚀 easy-LocalHub running!
   Local:   http://localhost:8080/
   LAN:     http://192.168.1.100:8080/

🔑 Room code: 123456
```

把 **LAN 地址** 和 **房间码** 发给同一 Wi‑Fi 下的参与者：

1. 浏览器打开 LAN 地址。
2. 输入房间码。
3. 设置昵称。
4. 开始聊天、上传或下载文件。

---

## 🔧 开机自动启动（可选）

```bash
bash install.sh --service
```

安装为 systemd 用户服务后，可用以下命令管理：

```bash
systemctl --user status easy-localhub    # 查看状态
systemctl --user restart easy-localhub   # 重启
systemctl --user stop easy-localhub      # 停止
journalctl --user -u easy-localhub -f    # 查看日志
```

---

## ⚙️ 配置说明

`install.sh` 首次运行时会引导你设置，也可以手动编辑 `config.json`：

```json
{
  "roomCode": "123456",
  "roomName": "我的房间",
  "ports": [8080, 8081, 8082, 8083, 8084, 8085]
}
```

| 字段 | 说明 |
| --- | --- |
| `roomCode` | 房间码，加入房间和访问房间 API 时需要匹配。 |
| `roomName` | 房间显示名称。 |
| `ports` | 候选端口列表，服务会自动使用第一个可用端口。 |

---

## 📁 项目结构

```text
easy-LocalHub/
├── server.mjs                 # HTTP 服务（零依赖 Node.js）
├── public/
│   └── index.html             # 前端 SPA（聊天 + 文件管理）
├── docs/
│   └── images/                # README 图解 SVG
├── install.sh                 # 首次部署 + 可选 systemd 服务
├── generate-guide.sh          # 生成 HTML/PDF 使用指南
├── config.example.json        # 配置示例
├── easy-LocalHub-Guide.pdf    # 使用指南 PDF
├── README.md                  # 中文说明
├── README.en.md               # English README
└── LICENSE                    # MIT
```

运行 `install.sh` 后会额外生成：

```text
├── config.json                # 你的房间码和端口配置（gitignored）
└── data/                      # 聊天记录、上传文件、运行端口（gitignored）
```

---

## 🧭 API 与数据流

| 能力 | 路径 | 说明 |
| --- | --- | --- |
| 健康检查 | `GET /api/health` | 返回服务状态与 LAN IP；不会返回房间码。 |
| 加入房间 | `POST /api/room/join` | 服务端校验 `roomCode`。 |
| 拉取消息 | `GET /api/room/:code/messages` | 返回最近消息，默认最多 200 条。 |
| 发送消息 | `POST /api/room/:code/messages` | 写入 `data/messages/<code>.jsonl`。 |
| 上传文件 | `POST /api/room/:code/upload` | 写入 `data/uploads/<code>/`，单请求上限 256 MB。 |
| 文件列表 | `GET /api/room/:code/files` | 递归列出最多 5000 个文件/目录项。 |
| 下载文件 | `GET /api/room/:code/files/:path` | 经路径清理与目录边界校验后返回文件。 |

---

## 🛡️ 安全边界

### 已做的基础防护

- 健康检查接口不返回房间码，避免任何打开页面的人直接看到访问凭据。
- 前端加入房间时调用服务端 `POST /api/room/join`，不再只做客户端比较。
- 上传与下载路径会经过相对路径清理和 `safeJoin` 目录边界校验，降低路径逃逸风险。
- JSON 请求体、用户名、消息文本都有大小/长度限制，避免明显的滥用输入。
- 响应附带 `X-Content-Type-Options: nosniff`、`Referrer-Policy: no-referrer` 和 `Cache-Control: no-store`。

### 仍需你注意

- 本项目定位为 **可信局域网工具**，不是公网文件站。
- 房间码是主要访问控制，请设置成不易猜测的值并只发给可信成员。
- 上传文件不会做病毒扫描；下载和打开前请自行判断来源。
- 如需公网访问，请务必额外添加 HTTPS、反向代理鉴权、访问日志、速率限制和病毒扫描。

---

## 📖 使用说明 PDF

项目内置 PDF 使用指南生成脚本：

```bash
bash generate-guide.sh
# 生成: easy-LocalHub-Guide.pdf
```

若环境没有 PDF 转换器，脚本会保留 HTML 指南，你也可以在浏览器中打开后打印为 PDF。

---

## ✅ 环境要求

| 角色 | 要求 |
| --- | --- |
| 服务端 | Node.js 18+；Linux 推荐 Debian/Ubuntu；macOS/Windows 可手动运行 `node server.mjs`。 |
| 客户端 | 任意现代浏览器：Chrome / Safari / Firefox / Edge。 |
| 网络 | 参与设备和宿主机处于同一局域网，防火墙放行所选端口。 |

---

## ❓ 常见问题

<details>
<summary>其他设备打不开 LAN 地址怎么办？</summary>

- 确认设备在同一 Wi‑Fi / 局域网下。
- 确认宿主机防火墙放行当前端口（默认 8080）。
- 检查终端打印的 LAN 地址是否为当前网络网卡地址。

</details>

<details>
<summary>端口被占用怎么办？</summary>

服务会按 `config.json` 的 `ports` 顺序尝试端口。你可以添加更多候选端口：

```json
{
  "ports": [8080, 8081, 8090, 9000]
}
```

</details>

<details>
<summary>上传大文件失败怎么办？</summary>

当前单次上传请求上限为 256 MB。请拆分文件、压缩文件夹，或在可信环境下按需调整 `server.mjs` 中的 `MAX_UPLOAD`。

</details>

<details>
<summary>数据在哪里？如何清理？</summary>

- 消息：`data/messages/`
- 文件：`data/uploads/`
- 当前端口：`data/port.txt`

停止服务后删除对应目录即可清理历史数据。

</details>

---

## 📜 License

MIT
