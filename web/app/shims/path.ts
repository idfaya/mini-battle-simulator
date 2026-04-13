export const sep = "/";

export function join(...parts: string[]) {
  return parts.join("/").replace(/\/+/g, "/");
}

export function resolve(...parts: string[]) {
  return join(...parts);
}

export function dirname(input: string) {
  const normalized = input.replace(/\\/g, "/");
  const index = normalized.lastIndexOf("/");
  return index <= 0 ? "/" : normalized.slice(0, index);
}

export function basename(input: string) {
  const normalized = input.replace(/\\/g, "/");
  const index = normalized.lastIndexOf("/");
  return index === -1 ? normalized : normalized.slice(index + 1);
}

export default {
  sep,
  join,
  resolve,
  dirname,
  basename,
};
