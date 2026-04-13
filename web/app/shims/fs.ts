function notAvailable() {
  throw new Error("fs is not available in the browser");
}

export const readFileSync = notAvailable;
export const writeFileSync = notAvailable;
export const openSync = notAvailable;
export const existsSync = () => false;
export const statSync = notAvailable;
export const createReadStream = notAvailable;

export default {
  readFileSync,
  writeFileSync,
  openSync,
  existsSync,
  statSync,
  createReadStream,
};
