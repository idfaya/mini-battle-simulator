import * as fengari from "fengari";
import type { BattleCommand, BattleEvent, BattleSnapshot } from "../types/battle";
import type { RunActionResponse, RunSnapshot } from "../types/roguelike";
import { normalizeEvent } from "./eventBridge";

const { lua, lauxlib, lualib, to_jsstring, to_luastring } = fengari;
const assetUrl = (path: string) => {
  const base = typeof document !== "undefined" ? document.baseURI : window.location.href;
  return new URL(path, base);
};

type LuaManifest = {
  entry: string;
  modules: Array<{ path: string; moduleName: string }>;
};

export class LuaBattleHost {
  private L: lua.State;

  private static readLuaString(value: unknown): string {
    if (typeof value === "string") {
      return value;
    }
    if (value == null) {
      return "";
    }
    return to_jsstring(value as Parameters<typeof to_jsstring>[0]);
  }

  static async create(): Promise<LuaBattleHost> {
    const host = new LuaBattleHost();
    await host.bootstrap();
    return host;
  }

  private constructor() {
    this.L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(this.L);
  }

  private async bootstrap() {
    const manifest = (await fetch(assetUrl("lua/project/manifest.json")).then((res) =>
      res.json(),
    )) as LuaManifest;
    await Promise.all(
      manifest.modules.map(async (module) => {
        const source = await fetch(assetUrl(`lua/project/${module.path}`)).then((res) => res.text());
        this.preloadModule(module.moduleName, source);
      }),
    );

    const entrySource = await fetch(assetUrl(`lua/project/${manifest.entry}`)).then((res) =>
      res.text(),
    );
    this.runChunk(entrySource, manifest.entry);
  }

  private assertOk(status: number, context: string) {
    if (status !== lua.LUA_OK) {
      const error = LuaBattleHost.readLuaString(lua.lua_tostring(this.L, -1));
      lua.lua_pop(this.L, 1);
      throw new Error(`${context}: ${error}`);
    }
  }

  private preloadModule(moduleName: string, source: string) {
    lua.lua_getglobal(this.L, to_luastring("package"));
    lua.lua_getfield(this.L, -1, to_luastring("preload"));

    const loadStatus = lauxlib.luaL_loadstring(this.L, to_luastring(source));
    this.assertOk(loadStatus, `load module ${moduleName}`);

    lua.lua_setfield(this.L, -2, to_luastring(moduleName));
    lua.lua_pop(this.L, 2);
  }

  private runChunk(source: string, filename: string) {
    const status = lauxlib.luaL_loadstring(this.L, to_luastring(source));
    this.assertOk(status, `load ${filename}`);
    this.assertOk(lua.lua_pcall(this.L, 0, 0, 0), `exec ${filename}`);
  }

  private callApi<T>(name: string, payload?: unknown): T {
    lua.lua_getglobal(this.L, to_luastring("MiniBattleWebApi"));
    lua.lua_getfield(this.L, -1, to_luastring(name));

    const jsonPayload = payload === undefined ? "" : JSON.stringify(payload);
    lua.lua_pushstring(this.L, to_luastring(jsonPayload));

    this.assertOk(lua.lua_pcall(this.L, 1, 1, 0), `call MiniBattleWebApi.${name}`);

    const raw = LuaBattleHost.readLuaString(lua.lua_tostring(this.L, -1));
    lua.lua_pop(this.L, 2);
    return JSON.parse(raw) as T;
  }

  async initBattle(config?: unknown): Promise<BattleSnapshot> {
    return this.callApi<BattleSnapshot>("init_battle", config);
  }

  async tick(deltaMs: number): Promise<{ events: BattleEvent[]; snapshot: BattleSnapshot }> {
    const events = this.callApi<BattleEvent[]>("tick", { deltaMs }).map(normalizeEvent);
    const snapshot = this.callApi<BattleSnapshot>("get_snapshot");
    return { events, snapshot };
  }

  async queueCommand(command: BattleCommand): Promise<boolean> {
    const result = this.callApi<{ accepted: boolean }>("queue_command", command);
    return result.accepted;
  }

  async restart(config?: unknown): Promise<BattleSnapshot> {
    return this.callApi<BattleSnapshot>("restart_battle", config);
  }

  async startRun(config?: unknown): Promise<RunSnapshot> {
    return this.callApi<RunSnapshot>("start_run", config);
  }

  async tickRun(deltaMs: number): Promise<{ events: BattleEvent[]; snapshot: RunSnapshot }> {
    // tick_run returns battle visual events (same schema as battle tick)
    const events = this.callApi<BattleEvent[]>("tick_run", { deltaMs }).map(normalizeEvent);
    const snapshot = this.callApi<RunSnapshot>("get_run_snapshot");
    return { events, snapshot };
  }

  async getRunSnapshot(): Promise<RunSnapshot> {
    return this.callApi<RunSnapshot>("get_run_snapshot");
  }

  async choosePath(nodeId: number): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("choose_path", { nodeId });
  }

  async enterNode(): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("enter_node");
  }

  async chooseReward(index: number): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("choose_reward", { index });
  }

  async chooseEventOption(optionId: number): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("choose_event_option", { optionId });
  }

  async shopBuy(goodsId: number): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("shop_buy", { goodsId });
  }

  async shopRefresh(): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("shop_refresh");
  }

  async shopLeave(): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("shop_leave");
  }

  async promoteBenchHero(benchRosterId: number): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("promote_bench_hero", { benchRosterId });
  }

  async swapBenchWithTeam(benchRosterId: number, teamRosterId: number): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("swap_bench_with_team", { benchRosterId, teamRosterId });
  }

  async campChoose(actionId: number): Promise<RunActionResponse> {
    return this.callApi<RunActionResponse>("camp_choose", { actionId });
  }

  async queueRunBattleCommand(command: BattleCommand): Promise<boolean> {
    const result = this.callApi<{ accepted: boolean }>("queue_run_battle_command", command);
    return result.accepted;
  }

  async restartRun(config?: unknown): Promise<RunSnapshot> {
    return this.callApi<RunSnapshot>("restart_run", config);
  }
}
