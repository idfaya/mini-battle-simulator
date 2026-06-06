export function findLineIndex(logs: string[], matcher: (line: string) => boolean, startIndex = 0) {
  for (let index = startIndex; index < logs.length; index += 1) {
    if (matcher(logs[index])) {
      return index;
    }
  }
  return -1;
}
