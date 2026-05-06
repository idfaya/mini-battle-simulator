import { expect, test } from "playwright/test";

async function collectClientErrors(page: import("playwright/test").Page) {
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

function filterKnownNoise(errors: string[]) {
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

function findLineIndex(logs: string[], matcher: (line: string) => boolean, startIndex = 0) {
  for (let index = startIndex; index < logs.length; index += 1) {
    if (matcher(logs[index])) {
      return index;
    }
  }
  return -1;
}

test("fighter web flow shows rebuilt names and action surge opens a fresh attack action", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910006&level=3&fighterFeats=2100301&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(1);
  await expect(page.locator(".ult-button-name")).toHaveText("Fighter");
  await expect(page.locator(".ult-button-skill")).toContainText("ULT · 1/1");

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("Fighter 使用 动作激增");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 8000 })
    .toContain("Fighter 发动动作激增：获得额外攻击行动");

  const level3LogLines = await page.locator(".battle-log li").allTextContents();
  const level3Logs = level3LogLines.join("\n");
  expect(level3Logs).toContain("动作激增");
  expect(level3Logs).not.toContain("盾击");
  expect(level3Logs).not.toContain("顺劈");
  expect(level3Logs).not.toContain("旋风");
  const actionSurgeCastIndex = findLineIndex(level3LogLines, (line) => line.includes("Fighter 使用 动作激增"));
  const actionSurgeActionIndex = findLineIndex(
    level3LogLines,
    (line) => line.includes("Fighter 发动动作激增：获得额外攻击行动"),
    actionSurgeCastIndex + 1,
  );
  const actionSurgeExtraAttackIndex = findLineIndex(
    level3LogLines,
    (line) => line.includes("Fighter 触发额外攻击：对同一目标"),
    actionSurgeActionIndex + 1,
  );
  expect(actionSurgeCastIndex).toBeGreaterThanOrEqual(0);
  expect(actionSurgeActionIndex).toBeGreaterThan(actionSurgeCastIndex);
  expect(actionSurgeExtraAttackIndex).toBeGreaterThan(actionSurgeActionIndex);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910004&level=1&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("Fighter 使用 基础武器攻击");
  const level1Logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(level1Logs).toContain("基础武器攻击");
  expect(level1Logs).not.toContain("盾击");
  expect(level1Logs).not.toContain("顺劈");
  expect(level1Logs).not.toContain("旋风");

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-web-smoke.png", fullPage: true });
});

test("fighter extra attack logs a same-target second hit at lv2", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910004&level=2&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("Fighter 触发额外攻击：对同一目标");

  let followUpState = {
    extraAttackIndex: -1,
    targetName: "",
    followUpAttackIndex: -1,
  };
  await expect
    .poll(async () => {
      const logs = await page.locator(".battle-log li").allTextContents();
      const extraAttackIndex = findLineIndex(logs, (line) => line.includes("Fighter 触发额外攻击：对同一目标"));
      const extraAttackLine = extraAttackIndex >= 0 ? logs[extraAttackIndex] : "";
      const targetMatch = extraAttackLine.match(/对同一目标 (.+) 追加第二击/);
      const targetName = targetMatch?.[1] ?? "";
      const followUpAttackIndex = findLineIndex(
        logs,
        (line) => targetName !== "" && line.includes(`Fighter 的 基础武器攻击 对 ${targetName}`),
        extraAttackIndex + 1,
      );
      followUpState = {
        extraAttackIndex,
        targetName,
        followUpAttackIndex,
      };
      return followUpAttackIndex >= 0 && targetName !== "";
    }, { timeout: 10000 })
    .toBeTruthy();

  expect(followUpState.targetName).not.toBe("");
  expect(followUpState.extraAttackIndex).toBeGreaterThanOrEqual(0);
  expect(followUpState.followUpAttackIndex).toBeGreaterThan(followUpState.extraAttackIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter precise attack logs AC-2 and the attack roll uses adjusted AC", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910006&level=4&fighterFeats=2100301,2100401&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("Fighter 触发精准攻击：");

  const logs = await page.locator(".battle-log li").allTextContents();
  const preciseIndex = findLineIndex(logs, (line) => line.includes("Fighter 触发精准攻击："));
  const preciseLine = preciseIndex >= 0 ? logs[preciseIndex] : "";
  const preciseMatch = preciseLine.match(/AC (\d+) -> (\d+)/);
  const adjustedAc = preciseMatch?.[2] ?? "";
  const attackIndex = findLineIndex(
    logs,
    (line) =>
      adjustedAc !== "" &&
      line.includes("Fighter 的 基础武器攻击 对") &&
      line.includes(`vs AC ${adjustedAc}`),
    preciseIndex + 1,
  );

  expect(preciseIndex).toBeGreaterThanOrEqual(0);
  expect(preciseMatch).not.toBeNull();
  expect(Number(preciseMatch?.[1] ?? 0) - Number(preciseMatch?.[2] ?? 0)).toBe(2);
  expect(attackIndex).toBeGreaterThan(preciseIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter counter reaction logs when reaction is queued", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=4&fighterFeats=2100302,2100402&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("Fighter 触发被动 反击战法：登记反击 将对 Orc 发动反击");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("Fighter 使用 基础武器攻击");

  const logs = await page.locator(".battle-log li").allTextContents();
  const attackIndex = logs.findIndex((line) => line.includes("Orc 使用 基础武器攻击"));
  const queueIndex = logs.findIndex((line) => line.includes("Fighter 触发被动 反击战法：登记反击 将对 Orc 发动反击"));
  const resultIndex = logs.findIndex((line) => line.includes("Orc 的 基础武器攻击 对 Fighter"));
  const counterIndex = logs.findIndex((line) => line.includes("Fighter 使用 基础武器攻击"));

  expect(attackIndex).toBeGreaterThanOrEqual(0);
  expect(queueIndex).toBeGreaterThan(attackIndex);
  expect(resultIndex).toBeGreaterThan(queueIndex);
  expect(counterIndex).toBeGreaterThan(resultIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-counter-queued-log.png", fullPage: true });
});

test("fighter guard reaction logs when ally attack queues guard counter", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  const perHeroBuilds = "2100302,2100402,2100502|2100301,2100401,2100501|2100301,2100401,2100501";
  await page.goto(
    `/?mode=single-battle&heroes=900005,900005,900005&enemies=910003,910003,910003&level=5&fighterFeatsByHero=${perHeroBuilds}&seed=101001`,
  );
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("Fighter 触发被动 护卫架势：登记护卫反击 将对 Orc 发动护卫反击");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("Fighter 触发被动 护卫架势：登记护卫反击 将对 Orc 发动护卫反击");

  const logs = await page.locator(".battle-log li").allTextContents();
  const queueIndex = logs.findIndex((line) => line.includes("Fighter 触发被动 护卫架势：登记护卫反击 将对 Orc 发动护卫反击"));
  const resultIndex = logs.findIndex(
    (line, index) => index > queueIndex && line.includes("Orc 的 基础武器攻击 对 Fighter"),
  );

  expect(logs.some((line) => line.includes("Fighter 使用 动作激增") || line.includes("Fighter 使用 护卫架势"))).toBeTruthy();
  expect(queueIndex).toBeGreaterThanOrEqual(0);
  expect(resultIndex).toBeGreaterThan(queueIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-guard-queued-log.png", fullPage: true });
});

test("fighter sweeping attack shows chained log visibility at lv5", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=5&fighterFeats=2100301,2100401,2100501&seed=101001",
  );
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("Fighter 触发被动 横扫攻击：追加横扫");

  const logs = await page.locator(".battle-log li").allTextContents();
  const basicAttackIndex = findLineIndex(logs, (line) => line.includes("Fighter 的 基础武器攻击 对 Orc 造成"));
  const sweepDamageIndex = findLineIndex(
    logs,
    (line) => line.includes("Fighter 对 Orc 造成") && !line.includes("基础武器攻击"),
    basicAttackIndex + 1,
  );
  const sweepTriggerIndex = findLineIndex(logs, (line) => line.includes("Fighter 触发被动 横扫攻击：追加横扫"), sweepDamageIndex + 1);

  expect(basicAttackIndex).toBeGreaterThanOrEqual(0);
  expect(sweepDamageIndex).toBeGreaterThan(basicAttackIndex);
  expect(sweepTriggerIndex).toBeGreaterThan(sweepDamageIndex);
  expect(logs[sweepTriggerIndex]).toMatch(/波及 .* 造成 \d+ 伤害/);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter second wind mastery shows boosted recovery logs at lv5", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=5&fighterFeats=2100302,2100402,2100502&seed=101001",
  );
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 15000 })
    .toContain("Fighter 触发被动 二次生命：濒危回复 恢复");

  const logs = await page.locator(".battle-log li").allTextContents();
  const healIndex = findLineIndex(logs, (line) => line.includes("Fighter 治疗 Fighter "));
  const secondWindIndex = findLineIndex(logs, (line) => line.includes("Fighter 触发被动 二次生命：濒危回复 恢复"), healIndex + 1);
  const secondWindLine = secondWindIndex >= 0 ? logs[secondWindIndex] : "";
  const healLine = healIndex >= 0 ? logs[healIndex] : "";
  const recoverMatch = secondWindLine.match(/恢复(\d+)生命/);
  const healMatch = healLine.match(/Fighter 治疗 Fighter (\d+)/);
  const recovered = recoverMatch ? Number(recoverMatch[1]) : 0;
  const healed = healMatch ? Number(healMatch[1]) : 0;

  expect(healIndex).toBeGreaterThanOrEqual(0);
  expect(secondWindIndex).toBeGreaterThanOrEqual(0);
  expect(recovered).toBeGreaterThan(0);
  expect(healed).toBe(recovered);
  expect(secondWindIndex).toBeGreaterThan(healIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
