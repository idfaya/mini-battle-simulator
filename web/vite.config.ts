import path from "node:path";
import { defineConfig } from "vite";

const stub = (file: string) => path.resolve(__dirname, "app/shims", file);
const repoName = process.env.GITHUB_REPOSITORY?.split("/")[1];
const repoBase = process.env.GITHUB_ACTIONS && repoName ? `/${repoName}/` : "/";

export default defineConfig({
  base: repoBase,
  root: ".",
  publicDir: "public",
  resolve: {
    alias: {
      fs: stub("fs.ts"),
      os: stub("os.ts"),
      path: stub("path.ts"),
      crypto: stub("crypto.ts"),
      child_process: stub("child_process.ts"),
      "readline-sync": stub("readline-sync.ts"),
      tmp: stub("tmp.ts"),
    },
  },
  server: {
    host: "127.0.0.1",
    port: 5173,
  },
});
