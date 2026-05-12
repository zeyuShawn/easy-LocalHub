import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import os from "node:os";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, "data");
const CONFIG_FILE = path.join(__dirname, "config.json");
const ROOMS_FILE = path.join(DATA_DIR, "rooms.json");
const MESSAGES_DIR = path.join(DATA_DIR, "messages");
const UPLOADS_DIR = path.join(DATA_DIR, "uploads");
const PUBLIC_DIR = path.join(__dirname, "public");
const APP_VERSION = "2.0.0";

// --- Load config ---
function loadConfig() {
  if (!fs.existsSync(CONFIG_FILE)) {
    console.error("❌ config.json not found! Run: bash install.sh");
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(CONFIG_FILE, "utf8"));
}
const config = loadConfig();
const ROOM_CODE = config.roomCode;
const PORTS = config.ports || [8080, 8081, 8082, 8083, 8084, 8085];
const MAX_UPLOAD = 256 * 1024 * 1024;
const MAX_JSON_BODY = 64 * 1024;
const MAX_MESSAGE_TEXT = 2000;
const MAX_USERNAME = 40;
const MAX_FILES_LIST = 5000;

// --- Helpers ---
function ensureDir(d) { fs.mkdirSync(d, { recursive: true }); }
function ensureData() {
  ensureDir(DATA_DIR); ensureDir(MESSAGES_DIR); ensureDir(UPLOADS_DIR);
  ensureDir(path.join(UPLOADS_DIR, ROOM_CODE));
  if (!fs.existsSync(ROOMS_FILE))
    fs.writeFileSync(ROOMS_FILE, JSON.stringify({ [ROOM_CODE]: { code: ROOM_CODE, name: config.roomName || "Default Room" } }));
}
function loadRooms() { try { return JSON.parse(fs.readFileSync(ROOMS_FILE, "utf8")); } catch { return {}; } }
function getLanIPs() {
  const ifaces = os.networkInterfaces(); const ips = [];
  for (const n of Object.keys(ifaces))
    for (const i of ifaces[n])
      if (i.family === "IPv4" && !i.internal) ips.push(i.address);
  return ips;
}
function getMsgPath(c) { return path.join(MESSAGES_DIR, c + ".jsonl"); }
function getUploadPath(c) { return path.join(UPLOADS_DIR, c); }
function isInsideDir(parent, child) {
  const rel = path.relative(parent, child);
  return rel === "" || (!!rel && !rel.startsWith("..") && !path.isAbsolute(rel));
}
function safeJoin(parent, relPath) {
  const resolvedParent = path.resolve(parent);
  const target = path.resolve(resolvedParent, relPath);
  return isInsideDir(resolvedParent, target) ? target : null;
}
function safeDecodeURIComponent(value) {
  try { return decodeURIComponent(value); } catch { return null; }
}
function readMessages(c) {
  const p = getMsgPath(c);
  if (!fs.existsSync(p)) return [];
  const raw = fs.readFileSync(p, "utf8").trim();
  if (!raw) return [];
  return raw.split("\n").map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
}

// Write queue for JSONL append
const wq = new Map();
function appendMsg(code, msg) {
  return new Promise(resolve => {
    const q = wq.get(code) || [];
    q.push({ msg, resolve }); wq.set(code, q);
    if (q.length === 1) drain(code);
  });
}
function drain(code) {
  const q = wq.get(code);
  if (!q || !q.length) return;
  const { msg, resolve } = q[0];
  fs.appendFile(getMsgPath(code), JSON.stringify(msg) + "\n", () => {
    resolve(); q.shift(); if (q.length) drain(code);
  });
}

// --- Response helpers ---
const COMMON_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
  "Cache-Control": "no-store"
};
function jsonResp(res, data, status = 200) {
  res.writeHead(status, { ...COMMON_HEADERS, "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(data));
}
function errResp(res, msg, status = 400) { jsonResp(res, { error: msg }, status); }

// --- Multipart parser (zero dependency) ---
function parseMultipart(buffer, boundary) {
  const results = [];
  const fullSep = Buffer.from("\r\n--" + boundary);
  const startMarker = Buffer.from("--" + boundary);
  const endMarker = Buffer.from("--" + boundary + "--");

  let firstSep = buffer.indexOf(startMarker);
  if (firstSep === -1) return results;
  let pos = firstSep + startMarker.length;
  if (buffer[pos] === 0x0d && buffer[pos + 1] === 0x0a) pos += 2;

  while (pos < buffer.length) {
    if (buffer[pos] === 0x2d && buffer[pos + 1] === 0x2d) break;
    const headEnd = buffer.indexOf("\r\n\r\n", pos);
    if (headEnd === -1) break;
    const head = buffer.slice(pos, headEnd).toString("utf8");
    pos = headEnd + 4;
    const nextSep = buffer.indexOf(fullSep, pos);
    let body;
    if (nextSep === -1) {
      const endPos = buffer.indexOf(endMarker, pos);
      body = endPos === -1 ? buffer.slice(pos) : buffer.slice(pos, endPos);
    } else {
      body = buffer.slice(pos, nextSep);
    }
    const nameMatch = head.match(/Content-Disposition:[^\r\n]*;\s*name="([^"]+)"/i);
    const filenameMatch = head.match(/Content-Disposition:[^\r\n]*;\s*filename="([^"]*)"/i);
    if (nameMatch) {
      results.push({
        name: nameMatch[1],
        filename: filenameMatch ? filenameMatch[1] || null : null,
        data: body
      });
    }
    if (nextSep === -1) break;
    pos = nextSep + fullSep.length;
    if (buffer[pos] === 0x0d && buffer[pos + 1] === 0x0a) pos += 2;
  }
  return results;
}

// --- Path & file utils ---
function sanitizeRelPath(p) {
  if (!p || typeof p !== "string") return null;
  p = p.replace(/\\/g, "/");
  if (p.startsWith("/") || p.match(/^[A-Za-z]:/) || p.includes("\0")) return null;
  const parts = p.split("/").filter(Boolean);
  for (const seg of parts) {
    if (seg === ".." || seg === "." || /[\r\n]/.test(seg)) return null;
  }
  return parts.length ? parts.join("/") : null;
}
function cleanText(value, maxLen) {
  if (typeof value !== "string") return null;
  const text = value.trim();
  if (!text || text.length > maxLen || /[\0]/.test(text)) return null;
  return text;
}

function mimeFor(ext) {
  const m = { ".html":"text/html",".css":"text/css",".js":"text/javascript",".json":"application/json",
    ".png":"image/png",".jpg":"image/jpeg",".jpeg":"image/jpeg",".gif":"image/gif",".svg":"image/svg+xml",
    ".pdf":"application/pdf",".zip":"application/zip",".txt":"text/plain",".md":"text/markdown",
    ".mp4":"video/mp4",".mp3":"audio/mpeg",".webp":"image/webp",".woff2":"font/woff2",
    ".xlsx":"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".docx":"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".csv":"text/csv",".xml":"application/xml",".tar":"application/x-tar",".gz":"application/gzip" };
  return m[ext] || "application/octet-stream";
}

function encodeRFC5987ValueChars(value) {
  return encodeURIComponent(value).replace(/['()*]/g, ch => "%" + ch.charCodeAt(0).toString(16).toUpperCase());
}
function asciiFilenameFallback(name) {
  const fallback = path.basename(name)
    .normalize("NFKD")
    .replace(/[^\x20-\x7E]+/g, "_")
    .replace(/[\r\n"\\]/g, "_")
    .trim();
  return fallback || "download";
}
function contentDisposition(name) {
  const base = path.basename(name);
  return `inline; filename="${asciiFilenameFallback(base)}"; filename*=UTF-8''${encodeRFC5987ValueChars(base)}`;
}
function streamFile(fp, res) {
  const stat = fs.statSync(fp, { throwIfNoEntry: false });
  if (!stat || !stat.isFile()) { errResp(res, "Not found", 404); return; }
  res.writeHead(200, {
    ...COMMON_HEADERS,
    "Content-Type": mimeFor(path.extname(fp).toLowerCase()),
    "Content-Length": stat.size,
    "Content-Disposition": contentDisposition(fp)
  });
  fs.createReadStream(fp).pipe(res);
}

function walkDir(dir, base) {
  const results = [];
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return results; }
  for (const ent of entries) {
    if (results.length >= MAX_FILES_LIST) break;
    const rel = base ? base + "/" + ent.name : ent.name;
    if (ent.isDirectory()) {
      results.push({ name: rel, type: "directory" });
      results.push(...walkDir(path.join(dir, ent.name), rel));
    } else if (ent.isFile()) {
      const st = fs.statSync(path.join(dir, ent.name), { throwIfNoEntry: false });
      results.push({ name: rel, type: "file", size: st ? st.size : 0 });
    }
  }
  return results;
}

function collectBody(req, maxBytes = MAX_UPLOAD) {
  return new Promise((resolve, reject) => {
    const chunks = []; let size = 0;
    req.on("data", c => {
      size += c.length;
      if (size > maxBytes) { reject(new Error("Too large")); req.destroy(); return; }
      chunks.push(c);
    });
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}
async function readJson(req) {
  const ct = req.headers["content-type"] || "";
  if (!ct.toLowerCase().startsWith("application/json")) throw new Error("JSON required");
  return JSON.parse((await collectBody(req, MAX_JSON_BODY)).toString("utf8"));
}

// --- Request handler ---
async function handleRequest(req, res) {
  const url = new URL(req.url, "http://" + req.headers.host);
  const p = url.pathname;

  if (req.method === "OPTIONS") {
    res.writeHead(204, { ...COMMON_HEADERS, "Access-Control-Allow-Methods":"GET,POST,OPTIONS","Access-Control-Allow-Headers":"Content-Type" });
    return res.end();
  }

  // API: health
  if (p === "/api/health" && req.method === "GET")
    return jsonResp(res, { ok:true, version:APP_VERSION, ips:getLanIPs() });

  // API: join room
  if (p === "/api/room/join" && req.method === "POST") {
    try {
      const { code } = await readJson(req);
      if (code !== ROOM_CODE) return errResp(res, "Invalid room code", 403);
      const rooms = loadRooms(); const room = rooms[code];
      if (!room) return errResp(res, "Room not found", 404);
      return jsonResp(res, { ok:true, room, messageCount: readMessages(code).length });
    } catch (e) { return errResp(res, e.message); }
  }

  let m;
  // API: messages
  if ((m = p.match(/^\/api\/room\/([^/]+)\/messages$/))) {
    const code = m[1];
    if (code !== ROOM_CODE) return errResp(res, "Invalid room", 403);
    if (req.method === "GET") {
      const limit = Math.min(parseInt(url.searchParams.get("limit")||"200",10), 500);
      const all = readMessages(code);
      return jsonResp(res, { ok:true, messages: all.slice(-limit), total: all.length });
    }
    if (req.method === "POST") {
      try {
        const body = await readJson(req);
        const user = cleanText(body.user, MAX_USERNAME);
        const text = cleanText(body.text, MAX_MESSAGE_TEXT);
        if (!text || !user) return errResp(res, "valid user and text required");
        const msg = { user, text, ts: Date.now() };
        await appendMsg(code, msg);
        return jsonResp(res, { ok:true, message: msg });
      } catch (e) { return errResp(res, e.message); }
    }
  }

  // API: upload
  if ((m = p.match(/^\/api\/room\/([^/]+)\/upload$/)) && req.method === "POST") {
    const code = m[1];
    if (code !== ROOM_CODE) return errResp(res, "Invalid room", 403);
    try {
      const ct = req.headers["content-type"] || "";
      const bm = ct.match(/boundary=(.+)/i);
      if (!bm) return errResp(res, "Multipart required");
      const parts = parseMultipart(await collectBody(req), bm[1].trim());
      const uploadRoot = getUploadPath(code);
      ensureDir(uploadRoot);
      const saved = [];
      const relPathFields = [];
      const fileFields = [];
      for (const part of parts) {
        if (!part.filename && part.name === "relativePath") relPathFields.push(part.data.toString("utf8").trim());
        else if (part.filename) fileFields.push(part);
      }
      for (let i = 0; i < fileFields.length; i++) {
        const part = fileFields[i];
        const relPath = relPathFields[i] || part.filename;
        const safe = sanitizeRelPath(relPath);
        if (!safe) continue;
        const dest = safeJoin(uploadRoot, safe);
        if (!dest) continue;
        ensureDir(path.dirname(dest));
        fs.writeFileSync(dest, part.data);
        await appendMsg(code, { user: "system", text: "\ud83d\udcce " + safe + " uploaded", ts: Date.now(), type: "file" });
        saved.push({ name: safe, size: part.data.length });
      }
      return jsonResp(res, { ok:true, saved });
    } catch (e) { return errResp(res, e.message); }
  }

  // API: file list
  if ((m = p.match(/^\/api\/room\/([^/]+)\/files$/)) && req.method === "GET") {
    const code = m[1];
    if (code !== ROOM_CODE) return errResp(res, "Invalid room", 403);
    return jsonResp(res, { ok:true, files: walkDir(getUploadPath(code), "") });
  }

  // API: file download
  if ((m = p.match(/^\/api\/room\/([^/]+)\/files\/(.+)$/)) && req.method === "GET") {
    const code = m[1]; const fp = m[2];
    if (code !== ROOM_CODE) return errResp(res, "Invalid room", 403);
    const decoded = safeDecodeURIComponent(fp);
    if (decoded === null) return errResp(res, "Invalid path");
    const safe = sanitizeRelPath(decoded);
    if (!safe) return errResp(res, "Invalid path");
    const abs = safeJoin(getUploadPath(code), safe);
    if (!abs) return errResp(res, "Path escape", 403);
    if (!fs.existsSync(abs)) return errResp(res, "Not found", 404);
    if (fs.statSync(abs).isDirectory()) return jsonResp(res, { ok:true, files: walkDir(abs, safe) });
    streamFile(abs, res); return;
  }

  // Static files
  const rawStaticPath = (req.url || "/").split(/[?#]/, 1)[0];
  const decodedStaticPath = safeDecodeURIComponent(rawStaticPath);
  if (decodedStaticPath === null || decodedStaticPath.split("/").includes("..")) {
    errResp(res, "Forbidden", 403); return;
  }
  let fp = p === "/" ? "index.html" : decodedStaticPath.replace(/^\/+/, "");
  fp = safeJoin(PUBLIC_DIR, fp);
  if (!fp) { errResp(res, "Forbidden", 403); return; }
  if (fs.existsSync(fp) && fs.statSync(fp).isFile()) streamFile(fp, res);
  else streamFile(path.join(PUBLIC_DIR, "index.html"), res);
}

// --- Bootstrap ---
ensureData();

async function tryListen(port) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      handleRequest(req, res).catch(e => { console.error("Error:", e); if (!res.headersSent) errResp(res, "Internal error", 500); });
    });
    server.on("error", reject);
    server.listen(port, "0.0.0.0", () => {
      const ips = getLanIPs();
      console.log("");
      console.log("🚀 easy-LocalHub running!");
      console.log("   Local:   http://localhost:" + port + "/");
      ips.forEach(ip => console.log("   LAN:     http://" + ip + ":" + port + "/"));
      console.log("");
      console.log("🔑 Room code: " + ROOM_CODE);
      console.log("   Open the LAN URL on any device, enter " + ROOM_CODE + " to join.");
      console.log("");
      fs.writeFileSync(path.join(DATA_DIR, "port.txt"), String(port));
      resolve(server);
    });
  });
}

for (const port of PORTS) {
  try { await tryListen(port); break; }
  catch (e) { if (e.code === "EADDRINUSE" || e.code === "EPERM") { console.log("Port " + port + " unavailable, trying next..."); continue; } throw e; }
}
