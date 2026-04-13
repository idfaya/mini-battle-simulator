export function randomBytes(size: number) {
  const array = new Uint8Array(size);
  globalThis.crypto.getRandomValues(array);
  return array;
}

export default {
  randomBytes,
};
