import "./main.css";
import { bootstrapApp } from "./app";

const root = document.querySelector<HTMLDivElement>("#app");
if (!root) {
  throw new Error("App root not found");
}

void bootstrapApp(root).catch((error) => {
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
