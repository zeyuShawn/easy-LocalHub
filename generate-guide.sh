#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

ROOM_CODE="YOUR_ROOM"
if [ -f config.json ]; then
    ROOM_CODE=$(python3 -c "import json; print(json.load(open('config.json'))['roomCode'])" 2>/dev/null || echo "YOUR_ROOM")
fi

HTML_FILE="local-hub-guide.html"
PDF_FILE="easy-LocalHub-Guide.pdf"

cat > "$HTML_FILE" << HTMLEOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body { font-family: -apple-system, "Segoe UI", sans-serif; max-width: 700px; margin: 40px auto; padding: 20px; color: #333; line-height: 1.7; }
  h1 { color: #6366f1; border-bottom: 2px solid #6366f1; padding-bottom: 8px; }
  h2 { color: #4f46e5; margin-top: 28px; }
  code { background: #f4f4f5; padding: 2px 6px; border-radius: 4px; font-family: monospace; font-size: 13px; }
  pre { background: #f4f4f5; padding: 14px 16px; border-radius: 8px; overflow-x: auto; font-size: 13px; }
  .box { background: #f0fdf4; border: 1px solid #86efac; border-radius: 8px; padding: 16px; margin: 12px 0; }
  .warn { background: #fefce8; border: 1px solid #fde047; border-radius: 8px; padding: 16px; margin: 12px 0; }
  ol li { margin-bottom: 8px; }
  table { width: 100%; border-collapse: collapse; margin: 12px 0; }
  td, th { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
  th { background: #f4f4f5; }
  .footer { margin-top: 40px; padding-top: 16px; border-top: 1px solid #ddd; color: #999; font-size: 12px; }
</style>
</head>
<body>
<h1>🏠 easy-LocalHub 使用说明</h1>

<h2>一、简介</h2>
<p>easy-LocalHub 是一个<strong>自托管</strong>的局域网协作工具。Clone 到你自己的机器上，运行安装脚本，同 Wi-Fi 下的所有设备即可通过浏览器互相<strong>传文件</strong>和<strong>聊天</strong>。</p>
<ul>
<li>零依赖，纯 Node.js 实现</li>
<li>数据全部存在你自己的机器上</li>
<li>支持拖拽上传整个文件夹并保留目录结构</li>
</ul>

<h2>二、环境要求</h2>
<table>
<tr><th>项目</th><th>要求</th></tr>
<tr><td>操作系统</td><td>Linux（推荐 Debian / Ubuntu）</td></tr>
<tr><td>Node.js</td><td>18 或更高版本</td></tr>
<tr><td>端口</td><td>默认 8080，自动寻找可用端口</td></tr>
<tr><td>客户端浏览器</td><td>Chrome / Safari / Firefox / Edge（任意现代浏览器）</td></tr>
</table>

<h2>三、首次部署（在你自己的机器上）</h2>

<h3>步骤 1：克隆项目</h3>
<pre>git clone https://github.com/zeyuShawn/easy-LocalHub.git
cd easy-LocalHub</pre>

<h3>步骤 2：运行安装脚本</h3>
<pre>bash install.sh</pre>
<p>首次运行会要求你输入：</p>
<ul>
<li><strong>房间码</strong>（如 <code>123456</code>）— 所有加入的设备需要输入此码</li>
<li><strong>房间名称</strong>（可选，回车使用默认值）</li>
</ul>
<p>安装脚本会自动创建 <code>config.json</code> 和数据目录。</p>

<h3>步骤 3：启动服务</h3>
<pre>node server.mjs</pre>
<p>终端会显示：</p>
<pre>🚀 easy-LocalHub running!
   Local:   http://localhost:8080/
   LAN:     http://192.168.x.x:8080/

🔑 Room code: 123456</pre>

<div class="box">
<strong>💡 开机自启动：</strong>运行 <code>bash install.sh --service</code> 即可安装为 systemd 用户服务，重启机器后自动启动。
</div>

<h2>四、客户端使用（加入别人的房间）</h2>
<ol>
<li>确保你的设备和宿主机在<strong>同一 Wi-Fi</strong> 下</li>
<li>在浏览器中打开宿主机的 LAN 地址（如 <code>http://192.168.x.x:8080/</code>）</li>
<li>输入宿主机告诉你的<strong>房间码</strong></li>
<li>设置一个昵称，点击「确认加入」</li>
<li>开始聊天和传文件！</li>
</ol>

<h2>五、功能说明</h2>

<h3>💬 聊天</h3>
<ul>
<li>所有消息持久化存储在宿主机上，刷新页面不丢失</li>
<li>支持多人同时聊天</li>
<li>每 3 秒自动刷新消息</li>
</ul>

<h3>📂 文件中转</h3>
<ul>
<li><strong>点击</strong>选择文件上传</li>
<li><strong>Shift + 点击</strong>选择整个文件夹上传</li>
<li><strong>拖拽</strong>文件或文件夹到上传区域</li>
<li>上传的文件保留原始目录结构</li>
<li>所有设备都可以在文件列表中浏览和下载</li>
</ul>

<div class="warn">
<strong>⚠️ 注意：</strong>
<ul>
<li>单文件上传上限 256 MB</li>
<li>文件存储在宿主机 <code>data/uploads/</code> 目录下</li>
<li>房主应确保磁盘空间充足</li>
</ul>
</div>

<h2>六、运维管理（宿主机操作）</h2>
<table>
<tr><th>操作</th><th>命令</th></tr>
<tr><td>查看状态</td><td><code>systemctl --user status easy-localhub</code></td></tr>
<tr><td>重启服务</td><td><code>systemctl --user restart easy-localhub</code></td></tr>
<tr><td>停止服务</td><td><code>systemctl --user stop easy-localhub</code></td></tr>
<tr><td>查看日志</td><td><code>journalctl --user -u easy-localhub -f</code></td></tr>
<tr><td>健康检查</td><td><code>curl http://localhost:8080/api/health</code></td></tr>
<tr><td>重新生成 PDF</td><td><code>bash generate-guide.sh</code></td></tr>
</table>

<h2>七、配置文件说明</h2>
<p><code>config.json</code>（由 <code>install.sh</code> 自动生成）：</p>
<pre>{
  "roomCode": "123456",
  "roomName": "我的房间",
  "ports": [8080, 8081, 8082, 8083, 8084, 8085]
}</pre>
<table>
<tr><th>字段</th><th>说明</th></tr>
<tr><td><code>roomCode</code></td><td>房间码，加入时需要输入</td></tr>
<tr><td><code>roomName</code></td><td>房间显示名称</td></tr>
<tr><td><code>ports</code></td><td>可用端口列表，自动使用第一个可用端口</td></tr>
</table>

<h2>八、安全提示</h2>
<ul>
<li>仅在可信任的局域网环境下使用</li>
<li>房间码是唯一的访问控制，请妥善保管</li>
<li>所有数据仅存储在宿主机本地，不会上传到任何云端</li>
<li>不使用时建议停止服务</li>
<li>上传文件不做病毒扫描，请自行确保文件安全</li>
</ul>

<h2>九、常见问题</h2>
<table>
<tr><th>问题</th><th>解答</th></tr>
<tr><td>其他设备打不开？</td><td>确认在同一 Wi-Fi 下；检查宿主机防火墙是否放行了 8080 端口</td></tr>
<tr><td>端口被占用？</td><td>编辑 <code>config.json</code> 的 <code>ports</code> 列表，添加其他端口</td></tr>
<tr><td>重启后服务没启动？</td><td>确认已运行 <code>bash install.sh --service</code></td></tr>
<tr><td>上传大文件失败？</td><td>单文件上限 256 MB，超过会被拒绝</td></tr>
</table>

<div class="footer">
<p>easy-LocalHub · MIT License · <a href="https://github.com/zeyuShawn/easy-LocalHub">github.com/zeyuShawn/easy-LocalHub</a></p>
</div>
</body>
</html>
HTMLEOF

echo "📄 HTML guide generated: $HTML_FILE"

if command -v wkhtmltopdf &>/dev/null; then
    wkhtmltopdf --quiet "$HTML_FILE" "$PDF_FILE"
    echo "📕 PDF guide generated: $PDF_FILE"
elif command -v chromium &>/dev/null; then
    chromium --headless --disable-gpu --print-to-pdf="$PDF_FILE" "$HTML_FILE" 2>/dev/null
    echo "📕 PDF guide generated: $PDF_FILE"
elif command -v google-chrome &>/dev/null; then
    google-chrome --headless --disable-gpu --print-to-pdf="$PDF_FILE" "$HTML_FILE" 2>/dev/null
    echo "📕 PDF guide generated: $PDF_FILE"
elif command -v python3 &>/dev/null && python3 -c "import weasyprint" 2>/dev/null; then
    python3 -c "import weasyprint; weasyprint.HTML(filename='$HTML_FILE').write_pdf('$PDF_FILE')"
    echo "📕 PDF guide generated: $PDF_FILE"
else
    echo ""
    echo "⚠️  No PDF converter found. Install one of:"
    echo "   - wkhtmltopdf:  sudo apt install wkhtmltopdf"
    echo "   - Or open $HTML_FILE in a browser and print to PDF"
    echo ""
fi
