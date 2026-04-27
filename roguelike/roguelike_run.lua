local RoguelikeMap = require("roguelike.roguelike_map")
local RoguelikeBattleBridge = require("roguelike.roguelike_battle_bridge")
local RoguelikeReward = require("roguelike.roguelike_reward")
local RoguelikeEvent = require("roguelike.roguelike_event")
local RoguelikeShop = require("roguelike.roguelike_shop")
local RoguelikeCamp = require("roguelike.roguelike_camp")
local RoguelikeSnapshot = require("roguelike.roguelike_snapshot")
local RunNodePool = require("config.roguelike.run_node_pool")
local RunEncounterGroup = require("config.roguelike.run_encounter_group")
local HeroData = require("config.hero_data")

local RoguelikeRun = {}
local state = nil
local cachedBattleSnapshot = nil
local STARTER_LEVEL = 1
-- 5e growth: no star progression.
local STARTER_STAR = 1
local CHAPTER_LEVEL_CAP = 10
local EXP_BY_NODE_TYPE = {
    battle_normal = 1,
    battle_elite = 2,
    boss = 3,
    event = 1,
    shop = 1,
    camp = 1,
}
local LEVEL_EXP_THRESHOLDS = {
    [1] = 0,
    [2] = 1,
    [3] = 2,
    [4] = 3,
    [5] = 4,
    [6] = 5,
    [7] = 6,
    [8] = 7,
    [9] = 8,
    [10] = 9,
    [11] = 10,
    [12] = 11,
    [13] = 12,
    [14] = 13,
    [15] = 14,
    [16] = 15,
    [17] = 16,
    [18] = 17,
    [19] = 18,
    [20] = 19,
}

local function allocateRosterId(runState)
    runState.nextRosterId = (runState.nextRosterId or 1)
    local rosterId = runState.nextRosterId
    runState.nextRosterId = rosterId + 1
    return rosterId
end

local function deepCopyTable(obj, visited)
    if type(obj) ~= "table" then
        return obj
    end
    visited = visited or {}
    if visited[obj] then
        return visited[obj]
    end
    local result = {}
    visited[obj] = result
    for k, v in pairs(obj) do
        result[deepCopyTable(k, visited)] = deepCopyTable(v, visited)
    end
    return result
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function addUnique(list, value)
    if not contains(list, value) then
        list[#list + 1] = value
    end
end

local function getExpThreshold(level)
    local lv = math.max(1, tonumber(level) or 1)
    return LEVEL_EXP_THRESHOLDS[lv] or (lv - 1)
end

local function getExpToNextLevel(level)
    local lv = math.max(1, tonumber(level) or 1)
    return math.max(1, getExpThreshold(lv + 1) - getExpThreshold(lv))
end

local function getNodeExp(nodeType)
    return tonumber(EXP_BY_NODE_TYPE[nodeType]) or 0
end

local function applyRosterLevel(hero, newLevel)
    if not hero then
        return
    end
    local attrs = HeroData.CalculateHeroAttributes(hero.heroId, newLevel, 1)
    if not attrs then
        return
    end
    local oldMaxHp = tonumber(hero.maxHp) or 1
    local oldCurrentHp = tonumber(hero.currentHp) or 0
    hero.level = attrs.level or newLevel
    hero.star = 1
    hero.maxHp = attrs.maxHp or oldMaxHp
    if hero.isDead then
        hero.currentHp = 0
    else
        local deltaHp = hero.maxHp - oldMaxHp
        hero.currentHp = math.max(1, math.min(hero.maxHp, oldCurrentHp + deltaHp))
    end
end

local function grantRunExp(amount, sourceLabel)
    local gain = math.max(0, math.floor(tonumber(amount) or 0))
    if gain <= 0 then
        return 0
    end
    state.partyExp = (state.partyExp or 0) + gain
    local oldLevel = state.partyLevel or STARTER_LEVEL
    local newLevel = oldLevel
    local cap = state.levelCap or CHAPTER_LEVEL_CAP
    while newLevel < cap and (state.partyExp or 0) >= getExpThreshold(newLevel + 1) do
        newLevel = newLevel + 1
    end
    if newLevel > oldLevel then
        state.partyLevel = newLevel
        for _, hero in ipairs(state.teamRoster or {}) do
            applyRosterLevel(hero, newLevel)
        end
        for _, hero in ipairs(state.benchRoster or {}) do
            applyRosterLevel(hero, newLevel)
        end
        state.lastActionMessage = string.format("%s，队伍升到 Lv.%d", sourceLabel or "获得经验", newLevel)
    else
        state.lastActionMessage = string.format("%s，获得 %d 经验", sourceLabel or "获得经验", gain)
    end
    local currentThreshold = getExpThreshold(newLevel)
    state.levelProgressExp = math.max(0, (state.partyExp or 0) - currentThreshold)
    state.nextLevelExp = newLevel >= cap and 0 or getExpToNextLevel(newLevel)
    return gain
end

local function buildStarterRoster(runState, heroIds)
    local roster = {}
    for _, heroId in ipairs(heroIds or {}) do
        local heroInfo = HeroData.GetHeroInfo(heroId)
        local attrs = HeroData.CalculateHeroAttributes(heroId, STARTER_LEVEL, STARTER_STAR)
        if heroInfo and attrs then
            roster[#roster + 1] = {
                rosterId = allocateRosterId(runState),
                heroId = heroId,
                name = HeroData.GetHeroName(heroId),
                classId = heroInfo.Class or 0,
                level = attrs.level or STARTER_LEVEL,
                star = attrs.star or STARTER_STAR,
                maxHp = attrs.maxHp,
                currentHp = attrs.maxHp,
                isDead = false,
                ultimateCharges = 1,
                ultimateChargesMax = 1,
                -- Persisted skill cooldowns across battles. Map: skillId -> rounds remaining.
                skillCooldowns = {},
                source = "starter",
            }
        end
    end
    return roster
end

local function resetRunState()
    return {
        phase = "map",
        chapterId = 101,
        currentNodeId = nil,
        selectedNextNodeId = nil,
        visitedNodeIds = {},
        availableNextNodeIds = {},
        gold = 0,
        food = 0,
        teamRoster = {},
        benchRoster = {},
        relicIds = {},
        blessingIds = {},
        rewardState = nil,
        eventState = nil,
        shopState = nil,
        campState = nil,
        chapterResult = nil,
        lastActionMessage = "",
        partyLevel = STARTER_LEVEL,
        partyExp = 0,
        levelProgressExp = 0,
        levelCap = CHAPTER_LEVEL_CAP,
        shopRefreshCount = 0,
        shopSoldMap = {},
        pendingRecruitHeroId = nil,
        maxHeroCount = 5,
        battleEncounterId = nil,
        battleRewardGroupId = nil,
        rewardReturnMode = "map",
        nextRosterId = 1,
    }
end

state = resetRunState()
cachedBattleSnapshot = nil

local function refreshAvailableNodes()
    local available = RoguelikeMap.GetAvailableNextNodeIds(state.currentNodeId, state.visitedNodeIds, state.chapterId)
    state.availableNextNodeIds = available
    if #available == 1 then
        state.selectedNextNodeId = available[1]
    elseif not contains(available, state.selectedNextNodeId) then
        state.selectedNextNodeId = nil
    end
end

local function enterNode(nodeId)
    local node = RunNodePool.GetNode(nodeId)
    if not node then
        return false, "node_not_found"
    end
    state.currentNodeId = nodeId
    state.visitedNodeIds[nodeId] = true
    state.lastActionMessage = ""

    if node.nodeType == "battle_normal" or node.nodeType == "battle_elite" or node.nodeType == "boss" then
        local encounter = RunEncounterGroup.GetEncounter(node.encounterId)
        if not encounter then
            return false, "encounter_not_found"
        end
        local ok, snapshotOrReason = RoguelikeBattleBridge.StartBattle(state, encounter)
        if not ok then
            state.phase = "failed"
            state.chapterResult = { success = false, reason = tostring(snapshotOrReason or "battle_init_failed") }
            return false, snapshotOrReason
        end
        cachedBattleSnapshot = snapshotOrReason
        state.phase = "battle"
        state.battleEncounterId = node.encounterId
        state.battleRewardGroupId = node.rewardGroupId
        return true
    end

    if node.nodeType == "event" then
        local event = RoguelikeEvent.GetEvent(node.eventId)
        if not event then
            return false, "event_not_found"
        end
        state.phase = "event"
        state.eventState = deepCopyTable(event)
        return true
    end

    if node.nodeType == "shop" then
        state.phase = "shop"
        state.shopState = RoguelikeShop.BuildShopState(state, node.shopId)
        return true
    end

    if node.nodeType == "camp" then
        state.phase = "camp"
        state.campState = RoguelikeCamp.BuildCampState(node.campId, state)
        return true
    end

    return false, "unsupported_node"
end

local function openReward(groupId)
    local rewardState = RoguelikeReward.GenerateRewardState(groupId)
    if not rewardState then
        return false, "reward_group_not_found"
    end
    state.phase = "reward"
    state.rewardState = rewardState
    return true
end

local function openBattleRecruitReward()
    local rewardState = RoguelikeReward.GenerateRecruitRewardState(state, 3)
    if not rewardState then
        return false, "battle_recruit_unavailable"
    end
    state.phase = "reward"
    state.rewardState = rewardState
    return true
end

local function leaveNodeBackToMap()
    state.rewardState = nil
    state.eventState = nil
    state.shopState = nil
    state.campState = nil
    cachedBattleSnapshot = nil
    state.phase = "map"
    state.battleEncounterId = nil
    state.battleRewardGroupId = nil
    state.rewardReturnMode = "map"
    refreshAvailableNodes()
end

local function evaluateFailureIfNoAlive()
    local anyAlive = false
    for _, hero in ipairs(state.teamRoster or {}) do
        if not hero.isDead and (hero.currentHp or 0) > 0 then
            anyAlive = true
            break
        end
    end
    if not anyAlive then
        state.phase = "failed"
        state.chapterResult = { success = false, reason = "team_wipe" }
        return true
    end
    return false
end

local function canManageRoster()
    return state.phase == "map" or state.phase == "shop" or state.phase == "event" or state.phase == "camp"
end

local function findRosterIndex(roster, rosterId)
    local targetId = tonumber(rosterId)
    if not targetId then
        return nil
    end
    for index, hero in ipairs(roster or {}) do
        if tonumber(hero.rosterId) == targetId then
            return index, hero
        end
    end
    return nil
end

local function refreshContextState()
    local node = RunNodePool.GetNode(state.currentNodeId)
    if state.phase == "shop" and node then
        state.shopState = RoguelikeShop.BuildShopState(state, node.shopId)
    elseif state.phase == "camp" and node then
        state.campState = RoguelikeCamp.BuildCampState(node.campId, state)
    end
end

function RoguelikeRun.StartRun(config)
    state = resetRunState()
    cachedBattleSnapshot = nil

    local chapterId = tonumber((config or {}).chapterId) or 101
    local chapter = RoguelikeMap.GetChapter(chapterId)
    if not chapter then
        chapterId = 101
        chapter = RoguelikeMap.GetChapter(chapterId)
    end
    state.chapterId = chapterId
    state.gold = chapter.startGold or 0
    state.food = chapter.startFood or 0
    state.maxHeroCount = chapter.maxHeroCount or 5
    state.partyLevel = STARTER_LEVEL
    state.partyExp = 0
    state.levelProgressExp = 0
    state.levelCap = tonumber(chapter.targetMaxLevel) or CHAPTER_LEVEL_CAP
    state.nextLevelExp = getExpToNextLevel(STARTER_LEVEL)

    local starterHeroIds = (config or {}).starterHeroIds or { 900005, 900007, 900002 }
    state.teamRoster = buildStarterRoster(state, starterHeroIds)
    state.benchRoster = {}
    refreshAvailableNodes()
    return RoguelikeRun.GetSnapshot()
end

function RoguelikeRun.RestartRun(config)
    return RoguelikeRun.StartRun(config)
end

function RoguelikeRun.GetSnapshot()
    local battleSnapshot = nil
    if state.phase == "battle" then
        battleSnapshot = RoguelikeBattleBridge.GetSnapshot()
    end
    return RoguelikeSnapshot.Build(state, battleSnapshot)
end

function RoguelikeRun.ChoosePath(nodeId)
    if state.phase ~= "map" then
        return false, "not_in_map"
    end
    local targetId = tonumber(nodeId)
    if not targetId then
        return false, "invalid_node"
    end
    if not contains(state.availableNextNodeIds, targetId) then
        return false, "node_not_available"
    end
    state.selectedNextNodeId = targetId
    state.lastActionMessage = "已选择路径"
    return true
end

function RoguelikeRun.EnterCurrentNode()
    if state.phase ~= "map" then
        return false, "not_in_map"
    end
    local nodeId = state.selectedNextNodeId
    if not nodeId then
        return false, "no_selected_node"
    end
    return enterNode(nodeId)
end

function RoguelikeRun.Tick(deltaMs)
    if state.phase ~= "battle" then
        return {}
    end
    local events = RoguelikeBattleBridge.Tick(deltaMs)
    cachedBattleSnapshot = RoguelikeBattleBridge.GetSnapshot()
    local resolved = RoguelikeBattleBridge.ResolveBattle(state, RunEncounterGroup.GetEncounter(state.battleEncounterId))
    if resolved then
        if evaluateFailureIfNoAlive() then
            return events or {}
        end

        if resolved.won then
            local node = RunNodePool.GetNode(state.currentNodeId)
            if node then
                grantRunExp(getNodeExp(node.nodeType), "战斗胜利")
            end
            if node and node.nodeType == "boss" then
                local chapter = RoguelikeMap.GetChapter(state.chapterId) or {}
                local clearRewards = chapter.chapterClearRewards or {}
                state.gold = (state.gold or 0) + (clearRewards.gold or 0)
                state.rewardReturnMode = "chapter_result"
                openBattleRecruitReward()
                return events or {}
            end

            state.rewardReturnMode = "map"
            openBattleRecruitReward()
        else
            state.phase = "failed"
            state.chapterResult = {
                success = false,
                reason = "battle_lost",
                battleResult = resolved.result,
            }
        end
    end
    return events or {}
end

function RoguelikeRun.QueueBattleCommand(command)
    if state.phase ~= "battle" then
        return false
    end
    return RoguelikeBattleBridge.QueueCommand(command)
end

function RoguelikeRun.ChooseReward(index)
    if state.phase ~= "reward" then
        return false, "not_in_reward"
    end
    local ok, reason = RoguelikeReward.ApplyReward(state, state.rewardState, tonumber(index) or 0)
    if not ok then
        return false, reason
    end
    if state.rewardReturnMode == "chapter_result" then
        local chapter = RoguelikeMap.GetChapter(state.chapterId) or {}
        local clearRewards = chapter.chapterClearRewards or {}
        if (clearRewards.healPct or 0) > 0 then
            for _, hero in ipairs(state.teamRoster or {}) do
                if not hero.isDead then
                    local heal = math.floor((hero.maxHp or 0) * clearRewards.healPct)
                    hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
                end
            end
        end
        state.phase = "chapter_result"
        state.rewardState = nil
        state.chapterResult = {
            success = true,
            reason = "boss_defeated",
            gold = state.gold,
            relicCount = #(state.relicIds or {}),
            blessingCount = #(state.blessingIds or {}),
        }
        return true
    end
    if state.rewardReturnMode == "shop" then
        local node = RunNodePool.GetNode(state.currentNodeId)
        state.phase = "shop"
        state.rewardState = nil
        state.shopState = RoguelikeShop.BuildShopState(state, node.shopId)
        state.rewardReturnMode = "map"
        return true
    end
    leaveNodeBackToMap()
    return true
end

function RoguelikeRun.ChooseEventOption(optionId)
    if state.phase ~= "event" then
        return false, "not_in_event"
    end

    local node = RunNodePool.GetNode(state.currentNodeId)
    local eventId = node and node.eventId or nil
    local ok, resultOrReason = RoguelikeEvent.ResolveOption(state, eventId, tonumber(optionId) or 0)
    if not ok then
        return false, resultOrReason
    end

    local result = resultOrReason or {}
    if result.kind == "done" then
        if node then
            grantRunExp(getNodeExp(node.nodeType), "完成事件")
        end
        leaveNodeBackToMap()
        return true
    end
    if result.kind == "reward_group" then
        return openReward(result.rewardGroupId)
    end
    if result.kind == "blessing" then
        state.blessingIds = state.blessingIds or {}
        addUnique(state.blessingIds, result.blessingId)
        if node then
            grantRunExp(getNodeExp(node.nodeType), "完成事件")
        end
        leaveNodeBackToMap()
        return true
    end
    if result.kind == "relic" then
        state.relicIds = state.relicIds or {}
        addUnique(state.relicIds, result.relicId)
        if node then
            grantRunExp(getNodeExp(node.nodeType), "完成事件")
        end
        leaveNodeBackToMap()
        return true
    end
    if result.kind == "recruit" then
        local added, reason = RoguelikeReward.AddRecruit(state, result.heroId)
        if not added then
            return false, reason
        end
        if node then
            grantRunExp(getNodeExp(node.nodeType), "完成事件")
        end
        leaveNodeBackToMap()
        return true
    end
    if result.kind == "battle" then
        -- Start event battle as a battle phase; after victory, open specified reward group.
        state.phase = "battle"
        state.battleEncounterId = result.encounterId
        state.battleRewardGroupId = result.rewardGroupId
        local encounter = RunEncounterGroup.GetEncounter(result.encounterId)
        local ok2, reason2 = RoguelikeBattleBridge.StartBattle(state, encounter)
        if not ok2 then
            state.phase = "failed"
            state.chapterResult = { success = false, reason = tostring(reason2 or "event_battle_failed") }
            return false, reason2
        end
        return true
    end

    return false, "unsupported_event_result"
end

function RoguelikeRun.ShopBuy(goodsId)
    if state.phase ~= "shop" then
        return false, "not_in_shop"
    end
    local node = RunNodePool.GetNode(state.currentNodeId)
    local ok, reason = RoguelikeShop.Buy(state, node.shopId, tonumber(goodsId) or 0)
    if not ok then
        return false, reason
    end
    if type(reason) == "table" and reason.kind == "recruit" then
        local added, addReason = RoguelikeReward.AddRecruit(state, reason.heroId, { forceBench = true })
        if not added then
            return false, addReason
        end
    end
    state.shopState = RoguelikeShop.BuildShopState(state, node.shopId)
    return true
end

function RoguelikeRun.ShopRefresh()
    if state.phase ~= "shop" then
        return false, "not_in_shop"
    end
    local node = RunNodePool.GetNode(state.currentNodeId)
    local ok, reason = RoguelikeShop.Refresh(state, node.shopId)
    if not ok then
        return false, reason
    end
    state.shopState = RoguelikeShop.BuildShopState(state, node.shopId)
    return true
end

function RoguelikeRun.ShopLeave()
    if state.phase ~= "shop" then
        return false, "not_in_shop"
    end
    local node = RunNodePool.GetNode(state.currentNodeId)
    if node then
        grantRunExp(getNodeExp(node.nodeType), "完成商店节点")
    end
    leaveNodeBackToMap()
    return true
end

function RoguelikeRun.CampChoose(actionId)
    if state.phase ~= "camp" then
        return false, "not_in_camp"
    end
    local node = RunNodePool.GetNode(state.currentNodeId)
    local ok, reason = RoguelikeCamp.ApplyAction(state, node.campId, tonumber(actionId) or 0)
    if not ok then
        return false, reason
    end
    grantRunExp(getNodeExp(node.nodeType), "完成营地节点")
    leaveNodeBackToMap()
    return true
end

function RoguelikeRun.PromoteBenchHero(benchRosterId)
    if not canManageRoster() then
        return false, "roster_locked"
    end

    local benchIndex, benchHero = findRosterIndex(state.benchRoster, benchRosterId)
    if not benchIndex or not benchHero then
        return false, "bench_hero_not_found"
    end
    if #(state.teamRoster or {}) >= (state.maxHeroCount or 5) then
        return false, "team_full"
    end

    table.remove(state.benchRoster, benchIndex)
    state.teamRoster[#state.teamRoster + 1] = benchHero
    state.lastActionMessage = "候补已直接上阵"
    refreshContextState()
    return true
end

function RoguelikeRun.SwapBenchWithTeam(benchRosterId, teamRosterId)
    if not canManageRoster() then
        return false, "roster_locked"
    end

    local benchIndex, benchHero = findRosterIndex(state.benchRoster, benchRosterId)
    local teamIndex, teamHero = findRosterIndex(state.teamRoster, teamRosterId)
    if not benchIndex or not benchHero then
        return false, "bench_hero_not_found"
    end
    if not teamIndex or not teamHero then
        return false, "team_hero_not_found"
    end

    state.teamRoster[teamIndex] = benchHero
    state.benchRoster[benchIndex] = teamHero
    state.lastActionMessage = string.format("%s 替换 %s 上阵", benchHero.name or "候补", teamHero.name or "队员")
    refreshContextState()
    return true
end

return RoguelikeRun
