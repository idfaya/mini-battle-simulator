import * as fengari from "fengari";
import type { BattleCommand, BattleEvent, BattleSnapshot } from "../types/battle";
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
}
