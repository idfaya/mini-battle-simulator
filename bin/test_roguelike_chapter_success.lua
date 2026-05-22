-- 章节结算成功路径回归：用已验证可通关的种子 10101 跑一遍 act1，
-- 断言最终落到 chapter_result.success=true 且 reason=boss_defeated，
-- 锁定 RoguelikeRun.chapterResult 字段契约。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local BattleFormation = require("modules.battle_formation")

local function getUltimateSkillForUnit(unitId)
    local hero = BattleFormation.FindHeroByInstanceId and BattleFormation.FindHeroByInstanceId(tonumber(unitId)) or nil
    local instances = hero and hero.skillData and hero.skillData.skillInstances or nil
    if not instances then return nil end
    for _, skill in pairs(instances) do
        if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then return skill end
    end
    return nil
end

local function isOutputUlt(unit)
    if not unit or not unit.id or unit.ultimateReady ~= true then return false end
    local ult = getUltimateSkillForUnit(unit.id)
    if not ult then return false end
    local ts = ult.targetsSelections or (ult.config and ult.config.targetsSelections)
    local ct = ts and ts.castTarget or ult.castTarget
    if ct == E_CAST_TARGET.Enemy or ct == E_CAST_TARGET.EnemyPos then return true end
    local desc = (ult.skillConfig and ult.skillConfig.description) or ""
    if desc:find("治疗") or desc:find("复活") then return false end
    return desc:find("d%d+") ~= nil
end

local function findReadyHero(s)
    local b = s and s.battleSnapshot
    if not b then return nil end
    for _, u in ipairs(b.leftTeam or {}) do
        if isOutputUlt(u) then return u.id end
    end
    return nil
end

local function runBattle(maxSteps)
    local s
    for _ = 1, maxSteps do
        Run.Tick(800)
        s = Run.GetSnapshot()
        if s.phase ~= "battle" then return s end
        local heroId = findReadyHero(s)
        if heroId then
            Run.QueueBattleCommand({ type = "cast_ultimate", heroId = heroId })
        end
    end
    return s
end

local function chooseRewardIndex(s)
    local r = s and s.rewardState
    if not r or not r.options then return 1 end
    local priority = { equipment = 1, blessing = 2, gold = 3 }
    local bestIdx, bestScore = 1, 99
    for i, opt in ipairs(r.options) do
        local sc = priority[opt.rewardType] or 99
        if sc < bestScore then bestIdx, bestScore = i, sc end
    end
    return bestIdx
end

-- BFS 寻路：从 current 到目标 predicate 的最短路径，返回下一跳；stair_up 仅作终点不作中转。
local function findPathNextHop(snapshot, predicate)
    local nodes = (snapshot.map and snapshot.map.nodes) or {}
    if #nodes == 0 then return nil end
    local indexById, current = {}, nil
    for _, n in ipairs(nodes) do
        indexById[n.id] = n
        if n.current then current = n end
    end
    if not current then return nil end
    local queue, visited, parent = { current.id }, { [current.id] = true }, {}
    local target
    while #queue > 0 do
        local id = table.remove(queue, 1)
        local node = indexById[id]
        if node ~= current and predicate(node) then target = node; break end
        for _, nxt in ipairs(node.nextNodeIds or {}) do
            local nb = indexById[nxt]
            if nb and not visited[nxt] then
                local block = (nb.nodeType == "stair_up") and (not predicate(nb))
                if not block then
                    visited[nxt] = true
                    parent[nxt] = id
                    queue[#queue + 1] = nxt
                end
            end
        end
    end
    if not target then return nil end
    local cur = target.id
    while parent[cur] and parent[cur] ~= current.id do cur = parent[cur] end
    return indexById[cur]
end

-- 复用 act1 同款 PREFERENCE 评分 + BFS 寻路：dungeon §4.2 cleared 房仅作通路。
local PREFERENCE = {
    shop          = 10,
    camp          = 20,
    event         = 30,
    equip         = 40,
    battle_normal = 60,
    stair_down    = 80,
    boss          = 90,
    battle_elite  = 100,
}
local VISITED_SCORE = 200

local function pickAggressiveNode(s)
    local sel = {}
    for _, n in ipairs((s.map and s.map.nodes) or {}) do
        if n.selectable then sel[#sel + 1] = n end
    end
    if #sel == 0 then return nil end
    local pl = tonumber(s.partyLevel) or 1
    local currentFloor = 1
    for _, n in ipairs((s.map and s.map.nodes) or {}) do
        if n.current then currentFloor = tonumber(n.floor) or 1; break end
    end

    -- 高 partyLevel 直接 BFS 找 boss / 本层 stair_down 的下一跳。
    if pl >= currentFloor * 4 and pl >= 3 then
        local hop = findPathNextHop(s, function(n) return n.nodeType == "boss" and not n.visited end)
            or findPathNextHop(s, function(n) return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor end)
        if hop then
            for _, x in ipairs(sel) do if x.id == hop.id then return hop end end
        end
    end

    -- selectable 全 visited 时按图 BFS 寻路一步。
    local hasUnvisited = false
    for _, n in ipairs(sel) do
        if not n.visited and n.nodeType ~= "stair_up" then hasUnvisited = true; break end
    end
    if not hasUnvisited then
        local hop
        if pl >= 5 then
            hop = findPathNextHop(s, function(n) return n.nodeType == "boss" and not n.visited end)
                or findPathNextHop(s, function(n) return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor end)
        else
            hop = findPathNextHop(s, function(n) return not n.visited and n.nodeType ~= "stair_up" and n.nodeType ~= "empty" end)
                or findPathNextHop(s, function(n) return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor end)
        end
        if hop then return hop end
    end

    local best, bestScore
    for _, node in ipairs(sel) do
        local score
        local floorDepth = tonumber(node.floor) or 1
        if node.visited then
            -- cleared stair_down 仅作通路但比其他 visited 房更优（保持本层推进）。
            if node.nodeType == "stair_down" and pl >= 3 then
                score = 45
            else
                score = VISITED_SCORE
            end
        else
            score = PREFERENCE[node.nodeType] or 99
            if node.nodeType == "battle_elite" then
                if pl < floorDepth * 2 then score = 100 else score = 60 end
            elseif node.nodeType == "battle_normal" then
                if pl < 3 then
                    score = 5
                elseif pl >= floorDepth * 6 then
                    score = 70
                end
            elseif node.nodeType == "stair_down" then
                if pl < 3 then score = 150
                elseif pl >= floorDepth * 4 then score = 25 end
            elseif node.nodeType == "boss" then
                if pl >= 5 then score = 15 end
            elseif node.nodeType == "stair_up" then
                score = 220
            end
        end
        if not bestScore or score < bestScore then
            best = node; bestScore = score
        end
    end
    return best or sel[1]
end

local SEED = 10101
math.randomseed(SEED)

local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = SEED,
})
assert(snapshot.phase == "map", "run should start on map")

local guard = 0
while guard < 300 do
    guard = guard + 1
    snapshot = Run.GetSnapshot()
    if snapshot.phase == "chapter_result" then break end
    assert(snapshot.phase ~= "failed", string.format("seed %d should not fail before chapter result", SEED))

    if snapshot.phase == "map" then
        local n = pickAggressiveNode(snapshot)
        assert(n, "should always have a selectable node before chapter result")
        assert(Run.ChoosePath(n.id) == true, "choose path should succeed")
        assert(Run.EnterCurrentNode() == true, "enter node should succeed")
    elseif snapshot.phase == "battle" then
        snapshot = runBattle(900)
        if snapshot.phase == "reward" then
            assert(Run.ChooseReward(chooseRewardIndex(snapshot)) == true, "reward should resolve")
        end
    elseif snapshot.phase == "reward" then
        assert(Run.ChooseReward(chooseRewardIndex(snapshot)) == true, "reward should resolve")
    elseif snapshot.phase == "camp" then
        -- camp short_rest 可能因约束（如 duplicate_blessing）失败，按可用列表 fallback。
        local actions = (snapshot.campState and snapshot.campState.actions) or {}
        local resolved = false
        for _, preferId in ipairs({ 2, 1, 3 }) do
            for _, action in ipairs(actions) do
                if tonumber(action.id) == preferId and action.available ~= false then
                    if Run.CampChoose(preferId) == true then resolved = true; break end
                end
            end
            if resolved then break end
        end
        if not resolved then
            assert(Run.CampLeave() == true, "camp leave should succeed when no action available")
        end
    elseif snapshot.phase == "shop" then
        assert(Run.ShopLeave() == true, "shop leave should succeed")
    elseif snapshot.phase == "event" then
        local opts = snapshot.eventState and snapshot.eventState.options or {}
        assert(opts[1], "event should have at least one option")
        assert(Run.ChooseEventOption(opts[1].id) == true, "event option should resolve")
    elseif snapshot.phase == "stair" then
        -- 楼梯方向感知：down 直接下楼推进；up 仅在 partyLevel 不足时主动回补，否则路过当通路。
        local stair = snapshot.stairState or {}
        local depth = tonumber(stair.currentFloorDepth) or 1
        local pl = tonumber(snapshot.partyLevel) or 1
        if stair.direction == "down" then
            assert(Run.StairUse() == true, "stair down use should succeed")
        elseif stair.direction == "up" and pl < depth * 2 then
            assert(Run.StairUse() == true, "stair up use should succeed")
        else
            assert(Run.StairLeave() == true, "stair leave should succeed")
        end
    else
        error("unsupported phase: " .. tostring(snapshot.phase))
    end
end

assert(snapshot.phase == "chapter_result", string.format("seed %d should converge to chapter_result, got %s", SEED, tostring(snapshot.phase)))
local result = snapshot.chapterResult
assert(result, "chapter_result snapshot should expose chapterResult payload")
assert(result.success == true, "chapter_result.success should be true on boss defeat path")
assert(result.reason == "boss_defeated", string.format("chapter_result.reason should be boss_defeated, got %s", tostring(result.reason)))
assert(snapshot.chapterId == 103, string.format("should clear all 3 chapters and end on chapterId=103, got %s", tostring(snapshot.chapterId)))
assert(type(result.gold) == "number", "chapter_result.gold should be a number")
assert(type(result.equipmentCount) == "number", "chapter_result.equipmentCount should be a number")
assert(type(result.blessingCount) == "number", "chapter_result.blessingCount should be a number")

print("roguelike chapter_result success path passed")
