import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");

const rootArg = process.argv[2] ?? "web/dist";
const port = Number(process.argv[3] ?? "4173");
const rootDir = path.resolve(repoRoot, rootArg);

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".lua": "text/plain; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".svg": "image/svg+xml",
};

function resolvePath(urlPath) {
  const sanitized = decodeURIComponent(urlPath.split("?")[0]);
  const relativePath = sanitized === "/" ? "/index.html" : sanitized;
  const absolutePath = path.normalize(path.join(rootDir, relativePath));
  if (!absolutePath.startsWith(rootDir)) {
    return null;
  }
  return absolutePath;
}

const server = http.createServer((req, res) => {
  const resolvedPath = resolvePath(req.url ?? "/");
  if (!resolvedPath) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  let filePath = resolvedPath;
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(rootDir, "index.html");
  }

  if (!fs.existsSync(filePath)) {
    res.writeHead(404);
    res.end("Not found");
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  res.writeHead(200, {
    "Content-Type": mimeTypes[ext] ?? "application/octet-stream",
    "Cache-Control": "no-cache",
  });
  fs.createReadStream(filePath).pipe(res);
});

server.listen(port, "127.0.0.1", () => {
  process.stdout.write(`Static server running at http://127.0.0.1:${port}\n`);
});
