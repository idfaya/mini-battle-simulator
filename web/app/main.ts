import "./main.css";
import { bootstrapApp } from "./app";

const root = document.querySelector<HTMLDivElement>("#app");
if (!root) {
  throw new Error("App root not found");
}

root.replaceChildren();

let appHandle: Awaited<ReturnType<typeof bootstrapApp>> | null = null;

void bootstrapApp(root)
  .then((handle) => {
    appHandle = handle;
  })
  .catch((error) => {
    const panel = document.createElement("pre");
    panel.className = "fatal-error";
    panel.textContent = [
      "浏览器战斗启动失败",
      "",
      error instanceof Error ? error.message : String(error),
    ].join("\n");
    root.replaceChildren(panel);
    console.error(error);
  });

if (import.meta.hot) {
  import.meta.hot.dispose(() => {
    appHandle?.cleanup();
    appHandle = null;
  });
}
