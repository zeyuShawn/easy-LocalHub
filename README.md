# 🏠 easy-LocalHub

**一键部署的局域网协作空间。** Clone 到你自己的机器上，运行安装脚本，同 Wi-Fi 下的所有设备即可通过浏览器互相传文件、聊天。

> 零依赖 · 纯 Node.js · 数据全部存在你自己的机器上

## ✨ 功能

- 📂 **文件中转** — 拖拽上传文件或整个文件夹，保留目录结构
- 💬 **群聊** — 聊天记录持久化，刷新不丢失
- 🔑 **房间码** — 设定你的专属房间码，控制谁能加入
- 📱 **全平台** — Windows / macOS / Linux / 手机，任意浏览器
- 🚀 **零依赖** — 不需要 `npm install`，只要有 Node.js 就能跑
- 🔄 **开机自启** — 可选 systemd 服务，重启自动拉起

## 🚀 快速开始（在你自己的机器上）

```bash
# 1. 克隆到你的电脑
git clone https://github.com/zeyuShawn/easy-LocalHub.git
cd easy-LocalHub

# 2. 运行安装脚本（首次会要求你设置房间码）
bash install.sh

# 3. 启动服务
node server.mjs
```

启动后终端会打印类似：

```
🚀 easy-LocalHub running!
   Local:   http://localhost:8080/
   LAN:     http://192.168.1.100:8080/

🔑 Room code: 195220
```

**把 LAN 地址发给同一 Wi-Fi 下的朋友**，他们打开浏览器输入地址 → 输入房间码 → 设置昵称 → 开始协作。

## 🔧 开机自动启动

```bash
bash install.sh --service
```

安装为 systemd 用户服务，重启后自动运行。

管理命令：

```bash
systemctl --user status easy-localhub    # 查看状态
systemctl --user restart easy-localhub   # 重启
systemctl --user stop easy-localhub      # 停止
journalctl --user -u easy-localhub -f    # 看日志
```

## 📖 使用说明 PDF

项目内置了 PDF 使用指南（部署后自动生成）：

```bash
bash generate-guide.sh
# 生成: easy-LocalHub-Guide.pdf
```

## 📁 项目结构

```
easy-LocalHub/
├── server.mjs            # HTTP 服务（零依赖 Node.js）
├── public/
│   └── index.html        # 前端 SPA（聊天 + 文件管理）
├── install.sh            # 安装脚本（首次部署 + 可选 systemd）
├── generate-guide.sh     # 生成 PDF 使用指南
├── config.example.json   # 配置示例
├── README.md
├── LICENSE               # MIT
└── .gitignore
```

运行 `install.sh` 后会额外生成：

```
├── config.json           # 你的房间码和端口配置（gitignored）
└── data/                 # 聊天记录和上传文件（gitignored）
```

## ⚙️ 配置

`install.sh` 首次运行时会引导你设置，也可以手动编辑 `config.json`：

```json
{
  "roomCode": "195220",
  "roomName": "我的房间",
  "ports": [8080, 8081, 8082, 8083, 8084, 8085]
}
```

| 字段 | 说明 |
|------|------|
| `roomCode` | 房间码，加入时需要输入 |
| `roomName` | 房间显示名称 |
| `ports` | 端口列表，自动使用第一个可用端口 |

## 📋 要求

- **服务端**: Node.js 18+，Linux（推荐 Debian/Ubuntu）
- **客户端**: 任意现代浏览器（Chrome / Safari / Firefox / Edge）

## 🛡️ 安全提示

- 仅在可信任的局域网环境使用
- 房间码是唯一的访问控制，请妥善保管
- 所有数据（消息 + 文件）仅存储在宿主机器的 `data/` 目录下
- 不使用时建议停止服务

## License

MIT
