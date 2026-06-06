import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { resolvePlaywrightBrowsersPath } from "./resolve-playwright-browsers.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const webRoot = resolve(__dirname, "..");
const playwrightCli = resolve(webRoot, "node_modules/playwright/cli.js");
const browsersPath = resolvePlaywrightBrowsersPath({
  projectLocalPath: resolve(webRoot, "node_modules/playwright-core/.local-browsers"),
});

const result = spawnSync(process.execPath, [playwrightCli, "test", ...process.argv.slice(2)], {
  cwd: webRoot,
  stdio: "inherit",
  env: {
    ...process.env,
    PLAYWRIGHT_BROWSERS_PATH: browsersPath,
  },
});

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);
