import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const outputRoot = path.join(repoRoot, "web", "public", "lua", "project");
const sourceDirs = ["core", "modules", "config", "ui", "utils"];
const embeddedFiles = [
  "config/res_hero.json",
  "config/res_enemy.json",
  "config/res_skill.json"
];

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function walkLuaFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const results = [];
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkLuaFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith(".lua")) {
      results.push(fullPath);
    }
  }
  return results;
}

function copyFilePreserveRoot(filePath) {
  const relativePath = path.relative(repoRoot, filePath);
  const destination = path.join(outputRoot, relativePath);
  ensureDir(path.dirname(destination));
  fs.writeFileSync(destination, fs.readFileSync(filePath));
  return relativePath.replace(/\\/g, "/");
}

function toModuleName(relativePath) {
  return relativePath.replace(/\\/g, "/").replace(/\.lua$/, "").replace(/\//g, ".");
}

function toLuaLongString(content) {
  let eq = "=";
  while (content.includes(`]${eq}]`)) {
    eq += "=";
  }
  return `[${eq}[${content}]${eq}]`;
}

fs.rmSync(outputRoot, { recursive: true, force: true });
ensureDir(outputRoot);

const manifest = [];
for (const dir of sourceDirs) {
  const absoluteDir = path.join(repoRoot, dir);
  for (const filePath of walkLuaFiles(absoluteDir)) {
    manifest.push({
      path: copyFilePreserveRoot(filePath),
      moduleName: toModuleName(path.relative(repoRoot, filePath))
    });
  }
}

const webEntrySource = path.join(repoRoot, "web", "lua_source", "web_entry.lua");
const webEntryDestination = path.join(outputRoot, "web_entry.lua");
ensureDir(path.dirname(webEntryDestination));
fs.writeFileSync(webEntryDestination, fs.readFileSync(webEntrySource));

const embeddedLuaLines = ["return {"];
for (const relativeFile of embeddedFiles) {
  const absoluteFile = path.join(repoRoot, relativeFile);
  const content = fs.readFileSync(absoluteFile, "utf8");
  embeddedLuaLines.push(`  ["${relativeFile.replace(/\\/g, "/")}"] = ${toLuaLongString(content)},`);
}
embeddedLuaLines.push("}");
fs.writeFileSync(path.join(outputRoot, "web_generated_files.lua"), `${embeddedLuaLines.join("\n")}\n`, "utf8");

manifest.push({
  path: "web_generated_files.lua",
  moduleName: "web_generated_files"
});

fs.writeFileSync(
  path.join(outputRoot, "manifest.json"),
  JSON.stringify(
    {
      entry: "web_entry.lua",
      modules: manifest.sort((a, b) => a.moduleName.localeCompare(b.moduleName))
    },
    null,
    2
  ),
  "utf8"
);
