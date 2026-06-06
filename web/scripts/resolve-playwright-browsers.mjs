import { existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

function defaultBrowsersPath() {
  const home = homedir();
  if (process.platform === "darwin") {
    return join(home, "Library", "Caches", "ms-playwright");
  }
  if (process.platform === "win32") {
    const localAppData = process.env.LOCALAPPDATA || join(home, "AppData", "Local");
    return join(localAppData, "ms-playwright");
  }
  return join(home, ".cache", "ms-playwright");
}

function hasChromiumHeadlessShell(browsersPath) {
  if (!browsersPath || browsersPath === "0" || !existsSync(browsersPath)) {
    return false;
  }

  let entries = [];
  try {
    entries = readdirSync(browsersPath, { withFileTypes: true });
  } catch {
    return false;
  }

  for (const entry of entries) {
    if (!entry.isDirectory() || !entry.name.startsWith("chromium_headless_shell-")) {
      continue;
    }
    const shellDir = join(browsersPath, entry.name);
    const nestedEntries = readdirSync(shellDir, { withFileTypes: true });
    const hasShellBinary = nestedEntries.some((nested) => {
      if (!nested.isDirectory()) {
        return false;
      }
      const nestedPath = join(shellDir, nested.name);
      try {
        return readdirSync(nestedPath).some((file) => file.includes("chrome-headless-shell"));
      } catch {
        return false;
      }
    });
    if (hasShellBinary) {
      return true;
    }
  }

  return false;
}

export function resolvePlaywrightBrowsersPath(options = {}) {
  const candidates = [];
  const configured = process.env.PLAYWRIGHT_BROWSERS_PATH;
  if (configured && configured !== "0") {
    candidates.push(configured);
  }
  candidates.push(defaultBrowsersPath());
  if (options.projectLocalPath) {
    candidates.push(options.projectLocalPath);
  }

  const seen = new Set();
  for (const candidate of candidates) {
    if (!candidate || seen.has(candidate)) {
      continue;
    }
    seen.add(candidate);
    if (hasChromiumHeadlessShell(candidate)) {
      return candidate;
    }
  }

  return configured && configured !== "0" ? configured : defaultBrowsersPath();
}
