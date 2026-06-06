import type { Page } from "playwright/test";

export async function collectClientErrors(page: Page) {
  const pageErrors: string[] = [];
  const consoleErrors: string[] = [];

  page.on("pageerror", (error) => {
    pageErrors.push(error.message);
  });
  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
  });

  return { pageErrors, consoleErrors };
}

export function filterKnownNoise(errors: string[]) {
  return errors.filter(
    (message) => !message.includes("ERR_CONNECTION_REFUSED") && !message.includes("ERR_NETWORK_CHANGED"),
  );
}
