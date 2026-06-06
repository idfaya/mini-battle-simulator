import type { Page } from "playwright/test";

export async function getAliveUnitIdByName(page: Page, name: string) {
  return page.evaluate((unitName: string) => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        callApi?: <T>(name: string, payload?: unknown) => T;
      };
    };
    const host = runtime.__miniBattleHost;
    if (!host || typeof host.callApi !== "function") {
      return "";
    }
    const snapshot = host.callApi<{
      leftTeam?: Array<{ id: string; name: string; isAlive: boolean }>;
      rightTeam?: Array<{ id: string; name: string; isAlive: boolean }>;
    }>("get_snapshot");
    const unit = [...(snapshot.leftTeam ?? []), ...(snapshot.rightTeam ?? [])].find(
      (candidate) => candidate.name === unitName && candidate.isAlive,
    );
    return unit?.id ?? "";
  }, name);
}

export async function forceKillRuntimeUnit(page: Page, unitId: string) {
  return page.evaluate((targetUnitId: string) => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        runChunk?: (source: string, filename: string) => void;
      };
    };
    const host = runtime.__miniBattleHost;
    if (!host || typeof host.runChunk !== "function") {
      return false;
    }
    const chunk = `
local BattleAttribute = require("modules.battle_attribute")
local BattleFormation = require("modules.battle_formation")
for _, hero in ipairs(BattleFormation.GetAllHeroes() or {}) do
    local heroId = tostring(hero.instanceId or hero.id or "")
    if heroId == ${JSON.stringify(targetUnitId)} then
        BattleAttribute.SetHpByVal(hero, 0)
        break
    end
end
`;
    host.runChunk(chunk, "playwright_force_kill_unit.lua");
    return true;
  }, unitId);
}

export async function waitForUnitsReturnToBase(page: Page, unitIds: string[], timeoutMs = 700) {
  return page.evaluate(
    async ({ trackedUnitIds, trackedTimeoutMs }: { trackedUnitIds: string[]; trackedTimeoutMs: number }) => {
      const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
      const runtime = window as typeof window & {
        __miniBattleRenderer?: {
          getBattleDebugState: () => {
            unitLayouts?: Array<{ id: string; x: number; y: number; baseX: number; baseY: number }>;
          };
        };
      };
      const renderer = runtime.__miniBattleRenderer;
      if (!renderer) {
        return false;
      }
      const attempts = Math.max(1, Math.ceil(trackedTimeoutMs / 40));
      for (let attempt = 0; attempt < attempts; attempt += 1) {
        await sleep(40);
        const layouts = new Map((renderer.getBattleDebugState().unitLayouts ?? []).map((layout) => [layout.id, layout]));
        const settled = trackedUnitIds.every((unitId) => {
          const layout = layouts.get(unitId);
          if (!layout) {
            return true;
          }
          return Math.hypot(layout.x - layout.baseX, layout.y - layout.baseY) < 4;
        });
        if (settled) {
          return true;
        }
      }
      return false;
    },
    { trackedUnitIds: unitIds, trackedTimeoutMs: timeoutMs },
  );
}
