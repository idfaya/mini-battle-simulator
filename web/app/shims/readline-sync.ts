function notAvailable() {
  throw new Error("readline-sync is not available in the browser");
}

export const question = notAvailable;
export const keyIn = notAvailable;
export function setDefaultOptions() {}
export function prompt() {
  return "";
}

export default {
  question,
  keyIn,
  setDefaultOptions,
  prompt,
};
