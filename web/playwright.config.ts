import { defineConfig } from "playwright/test";

// 请通过 `npm run test:playwright` 启动；`web/scripts/run-playwright.mjs` 会解析浏览器目录。
export default defineConfig({
  testDir: "./tests",
  timeout: 30000,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:5173",
    headless: true,
    viewport: { width: 1440, height: 960 },
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "npm run dev:full -- --host 127.0.0.1 --port 5173",
    url: "http://127.0.0.1:5173",
    // 避免复用旧 dev 进程（未 export 或错误 base 时会 404→HTML，Lua preload 失败）。
    reuseExistingServer: process.env.PW_REUSE_SERVER === "1",
    timeout: 60000,
  },
});
