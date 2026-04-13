function notAvailable() {
  throw new Error("child_process is not available in the browser");
}

export const execFileSync = notAvailable;
export const spawnSync = notAvailable;

export default {
  execFileSync,
  spawnSync,
};
