import assert from "node:assert/strict";
import { homedir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { resolvePlaywrightBrowsersPath } from "./resolve-playwright-browsers.mjs";

test("resolvePlaywrightBrowsersPath falls back when configured sandbox path is invalid", () => {
  const resolved = resolvePlaywrightBrowsersPath({
    envBrowsersPath: "/tmp/mini-battle-missing-playwright-browsers",
    projectLocalPath: "/tmp/mini-battle-missing-playwright-local",
  });
  const expectedDefault =
    process.platform === "darwin"
      ? join(homedir(), "Library", "Caches", "ms-playwright")
      : process.platform === "win32"
        ? join(process.env.LOCALAPPDATA || join(homedir(), "AppData", "Local"), "ms-playwright")
        : join(homedir(), ".cache", "ms-playwright");
  assert.equal(resolved, expectedDefault);
});

test("resolvePlaywrightBrowsersPath returns a non-empty path", () => {
  const resolved = resolvePlaywrightBrowsersPath();
  assert.ok(typeof resolved === "string");
  assert.ok(resolved.length > 0);
});
