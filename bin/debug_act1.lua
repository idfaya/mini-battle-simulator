local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

-- 复用 act1 测试的路径选择/奖励选择逻辑（不重写），让 debug 与回归一致。
local Run = require("roguelike.roguelike_run")

math.randomseed(10102)
local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = 10102,
})

-- 简版 chooseNextNode：遵循"先 shop / 再 camp / 再 recruit / 再 event"，类似回归测试。
local function pickNode(snap)
    for _, n in ipairs((snap.map and snap.map.nodes) or {}) do
        if n.selectable and n.nodeType == "shop" then return n end
    end
    for _, n in ipairs((snap.map and snap.map.nodes) or {}) do
        if n.selectable and n.nodeType == "camp" then return n end
    end
    for _, n in ipairs((snap.map and snap.map.nodes) or {}) do
        if n.selectable and n.nodeType == "recruit" then return n end
    end
    for _, n in ipairs((snap.map and snap.map.nodes) or {}) do
        if n.selectable and n.nodeType == "event" then return n end
    end
    for _, n in ipairs((snap.map and snap.map.nodes) or {}) do
        if n.selectable and n.nodeType == "battle_normal" then return n end
    end
    for _, n in ipairs((snap.map and snap.map.nodes) or {}) do
        if n.selectable then return n end
    end
end

local guard = 0
while guard < 40 do
    guard = guard + 1
    snapshot = Run.GetSnapshot()
    local levels = {}
    for _, h in ipairs(snapshot.team or {}) do levels[#levels+1] = string.format("%s:Lv%d/HP%d", h.name or "?", h.level or 1, h.hp or 0) end
    print(string.format("[%d] phase=%s pl=%s pe=%s gold=%s team=[%s]",
        guard, tostring(snapshot.phase), tostring(snapshot.partyLevel), tostring(snapshot.partyExp), tostring(snapshot.gold), table.concat(levels, ",")))
    if snapshot.phase == "chapter_result" or snapshot.phase == "failed" then
        if snapshot.chapterResult then print("  result=", snapshot.chapterResult.success, snapshot.chapterResult.reason) end
        break
    end
    if snapshot.phase == "map" then
        local pick = pickNode(snapshot)
        if not pick then break end
        print("  pick:", pick.id, pick.nodeType)
        Run.ChoosePath(pick.id)
        Run.EnterCurrentNode()
    elseif snapshot.phase == "battle" then
        for i = 1, 600 do
            Run.Tick(800)
            local s = Run.GetSnapshot()
            if s.phase ~= "battle" then break end
        end
    elseif snapshot.phase == "reward" then
        local rew = snapshot.rewardState or {}
        if rew.kind == "feat_levelup" then
            local levelByRoster = {}
            for _, h in ipairs(snapshot.team or {}) do
                levelByRoster[tonumber(h.rosterId) or 0] = tonumber(h.level) or 1
            end
            local bestIdx, bestLv = 1, 99
            for i, o in ipairs(rew.options or {}) do
                local lv = levelByRoster[tonumber(o.rosterId) or 0] or 99
                if lv < bestLv then bestLv = lv; bestIdx = i end
            end
            print("  feat:")
            for i, o in ipairs(rew.options or {}) do
                print("   ", i, o.tier, o.heroName, o.featName, "(roster", o.rosterId, "→Lv", o.level, ")")
            end
            print("  pick", bestIdx)
            Run.ChooseReward(bestIdx)
        else
            Run.ChooseReward(1)
        end
    elseif snapshot.phase == "camp" then
        Run.CampChoose(2)
    elseif snapshot.phase == "shop" then
        Run.ShopLeave()
    elseif snapshot.phase == "event" then
        local opts = (snapshot.eventState and snapshot.eventState.options) or {}
        Run.ChooseEventOption(opts[1] and opts[1].id or 1)
    end
end
