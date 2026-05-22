local RoguelikeMap = require("roguelike.roguelike_map")
local FloorState = require("roguelike.floor_state")
local RoguelikeBattleBridge = require("roguelike.roguelike_battle_bridge")
local RoguelikeReward = require("roguelike.roguelike_reward")
local RoguelikeEvent = require("roguelike.roguelike_event")
local RoguelikeShop = require("roguelike.roguelike_shop")
local RoguelikeCamp = require("roguelike.roguelike_camp")
local RoguelikeSnapshot = require("roguelike.roguelike_snapshot")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local RunBattleConfig = require("config.roguelike.run_battle_config")
local RunBattleProfile = require("config.roguelike.run_battle_profile")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")
local HeroData = require("config.hero_data")
local ClassRoleConfig = require("config.tables.classes")
local RoguelikeBattleResolver = require("roguelike.roguelike_battle_resolver")
local FeatPicker = require("roguelike.feat_picker")
local BuildConstraints = require("roguelike.build_constraints")
local LevelCurve = require("config.roguelike.level_curve")

local RoguelikeRun = {}
local state = nil
local cachedBattleSnapshot = nil
local STARTER_LEVEL = LevelCurve.STARTER_LEVEL
-- 5e growth: no star progression.
local STARTER_STAR = 1
local CHAPTER_LEVEL_CAP = LevelCurve.CHAPTER_LEVEL_CAP
local DEFAULT_STARTER_TEAM_SIZE = 4
local DEFAULT_STARTER_FRONT_COUNT = 2

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

local function getExpThreshold(level)
    return LevelCurve.GetExpThreshold(level)
end

local function getExpToNextLevel(level)
    return LevelCurve.GetExpToNextLevel(level, state and state.levelCap or CHAPTER_LEVEL_CAP)
end

local function getLevelForExp(exp, cap)
    return LevelCurve.GetLevelForExp(exp, cap or CHAPTER_LEVEL_CAP)
end

local function cloneArray(input)
    local result = {}
    for index, value in ipairs(input or {}) do
        result[index] = value
    end
    return result
end

local function mergeLastBattleSummary(fields)
    state.lastBattleSummary = state.lastBattleSummary or {}
    for key, value in pairs(fields or {}) do
        state.lastBattleSummary[key] = value
    end
end

local function grantBattleEquipmentDrop(node, battleProfile)
    local equipmentId = RoguelikeReward.RollBattleEquipmentDrop(node and node.nodeType or nil, battleProfile)
    if not equipmentId then
        return nil
    end
    local ok = BuildConstraints.AddEquipment(state, equipmentId)
    if not ok then
        return nil
    end
    return equipmentId
end

-- 战斗祝福掉落：唯一入库 + 去重。规则由 RollBattleBlessingDrop 决定（精英 50% / boss 必掉）。
local function grantBattleBlessingDrop(node, battleProfile)
    local blessingId = RoguelikeReward.RollBattleBlessingDrop(node and node.nodeType or nil, battleProfile)
    if not blessingId then
        return nil
    end
    local ok = BuildConstraints.AddBlessing(state, blessingId)
    if not ok then
        return nil
    end
    return blessingId
end

-- 战斗节点掉落入口：装备 + 祝福各最多 1 件。
-- 规则映射（设计文档：character_progression_design.md 阶段 2）：
--   battle_normal : 装备 0 / 祝福 0
--   battle_elite  : 装备 1 / 祝福 50%
--   boss          : 装备 1（boss tier）/ 祝福 1（boss tier）
local function grantBattleLoot(node, battleProfile)
    if not node then
        return { equipmentDropCount = 0, blessingDropCount = 0 }
    end
    local equipmentDropCount = 0
    if grantBattleEquipmentDrop(node, battleProfile) then
        equipmentDropCount = 1
    end
    local blessingDropCount = 0
    if grantBattleBlessingDrop(node, battleProfile) then
        blessingDropCount = 1
    end
    return {
        equipmentDropCount = equipmentDropCount,
        blessingDropCount = blessingDropCount,
    }
end

local function grantBattleExp(battle)
    local expReward = math.max(0, math.floor(tonumber(battle and battle.expReward) or 0))
    state.lastBattleExpReward = expReward
    -- 队伍升级三选一通道：unit.exp 已废弃，所有战斗经验全部进入 state.partyExp。
    -- 个人升级仅通过 FeatPicker 选中后 +1 实现，不再按存活分配 EXP。
    if expReward > 0 then
        state.partyExp = (state.partyExp or 0) + expReward
        state.lastActionMessage = string.format("战斗胜利，队伍获得 %d 经验", expReward)
    end
    return expReward
end

-- 队伍当前应处的等级 = 在 partyExp 跨越的最大阈值；不再按存活成员等级平均。
-- 设计 §3 新模型：partyLevel = 累计三选一次数 + 1，与 hero level cap（state.levelCap=chapter.targetMaxLevel）解耦。
-- 以 LevelCurve.CHAPTER_LEVEL_CAP（≈32）作为 partyLevel 上限，4 人队 Lv8 累计需 partyLevel≈29。
local function recalcPartyLevel()
    local exp = math.max(0, math.floor(tonumber(state.partyExp) or 0))
    local partyCap = LevelCurve.CHAPTER_LEVEL_CAP
    local level = STARTER_LEVEL
    for lv = STARTER_LEVEL + 1, partyCap do
        if exp >= getExpThreshold(lv) then
            level = lv
        else
            break
        end
    end
    state.partyLevel = level
    local currentThreshold = getExpThreshold(level)
    state.levelProgressExp = math.max(0, exp - currentThreshold)
    state.nextLevelExp = getExpToNextLevel(level)
    return level
end

local function buildStarterRoster(runState, heroIds)
    local roster = {}
    for _, heroId in ipairs(heroIds or {}) do
        local heroInfo = HeroData.GetHeroInfo(heroId)
        local classId = tonumber(heroInfo and heroInfo.Class) or 0
        if classId > 0 then
            local rosterId = allocateRosterId(runState)
            local unit = HeroData.CreateClassUnit(classId, {
                rosterId = rosterId,
                unitId = string.format("class_unit_%d_%d", classId, rosterId),
                level = STARTER_LEVEL,
                teamState = "active",
                source = "starter",
                ultimateCharges = 1,
                ultimateChargesMax = 1,
                skillCooldowns = {},
            })
            if unit then
                roster[#roster + 1] = unit
            end
        end
    end
    return roster
end

local function shuffleArray(list)
    for index = #list, 2, -1 do
        local swapIndex = math.random(1, index)
        list[index], list[swapIndex] = list[swapIndex], list[index]
    end
    return list
end

local function buildRandomStarterHeroIds()
    local frontPool = {}
    local backPool = {}
    for _, classId in ipairs(HeroData.GetAllClassIds() or {}) do
        local heroId = tonumber(HeroData.GetRepresentativeHeroId(classId)) or 0
        if heroId > 0 then
            if ClassRoleConfig.PreferFrontRow(classId) then
                frontPool[#frontPool + 1] = heroId
            else
                backPool[#backPool + 1] = heroId
            end
        end
    end

    shuffleArray(frontPool)
    shuffleArray(backPool)

    local picked = {}
    for index = 1, math.min(DEFAULT_STARTER_FRONT_COUNT, #frontPool) do
        picked[#picked + 1] = frontPool[index]
    end
    for index = 1, math.min(DEFAULT_STARTER_TEAM_SIZE - #picked, #backPool) do
        picked[#picked + 1] = backPool[index]
    end

    if #picked < DEFAULT_STARTER_TEAM_SIZE then
        local seen = {}
        for _, heroId in ipairs(picked) do
            seen[heroId] = true
        end
        local fallbackPool = {}
        for _, hero in ipairs(HeroData.GetPlayableHeroes() or {}) do
            local heroId = tonumber(hero and hero.AllyID) or 0
            if heroId > 0 and not seen[heroId] then
                fallbackPool[#fallbackPool + 1] = heroId
            end
        end
        shuffleArray(fallbackPool)
        for _, heroId in ipairs(fallbackPool) do
            picked[#picked + 1] = heroId
            if #picked >= DEFAULT_STARTER_TEAM_SIZE then
                break
            end
        end
    end

    return picked
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
        ownedUnits = {},
        teamRoster = {},
        benchRoster = {},
        equipmentIds = {},
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
        maxHeroCount = 5,
        currentBattleId = nil,
        currentBattleConfig = nil,
        lastBattleSummary = nil,
        dungeonState = nil,
        seed = nil,
        rewardReturnMode = "map",
        nextRosterId = 1,
    }
end

state = resetRunState()
cachedBattleSnapshot = nil

local function refreshAvailableNodes()
    local available = RoguelikeMap.GetAvailableNextNodeIds(state.currentNodeId, state.visitedNodeIds, state.chapterId, state.dungeonState)
    state.availableNextNodeIds = available
    if #available == 1 then
        state.selectedNextNodeId = available[1]
    elseif not contains(available, state.selectedNextNodeId) then
        state.selectedNextNodeId = nil
    end
end

local function getNode(nodeId)
    return RoguelikeMap.GetNode(nodeId, state and state.dungeonState or nil)
end

local function enterNode(nodeId)
    local node = getNode(nodeId)
    if not node then
        return false, "node_not_found"
    end
    state.currentNodeId = nodeId
    state.visitedNodeIds[nodeId] = true
    state.lastActionMessage = ""
    state.lastBattleSummary = nil

    if state.dungeonState then
        state.dungeonState.currentRoomId = nodeId
    end

    if node.nodeType == "stair_down" then
        if not state.dungeonState then
            return false, "no_dungeon_state"
        end
        -- dungeon §4.2：楼梯房进入后弹出选择，可使用楼梯（上/下楼）或路过（仅作通路）。
        state.phase = "stair"
        state.stairState = {
            direction = "down",
            nodeId = nodeId,
            currentFloorDepth = state.dungeonState.currentFloorDepth,
        }
        return true
    end

    if node.nodeType == "stair_up" then
        if not state.dungeonState then
            return false, "no_dungeon_state"
        end
        state.phase = "stair"
        state.stairState = {
            direction = "up",
            nodeId = nodeId,
            currentFloorDepth = state.dungeonState.currentFloorDepth,
        }
        return true
    end

    if node.nodeType == "equip" or node.nodeType == "empty" then
        if state.dungeonState then
            FloorState.MarkRoomCleared(state.dungeonState, nodeId)
        end
        state.phase = "map"
        refreshAvailableNodes()
        return true
    end

    if node.nodeType == "battle_normal" or node.nodeType == "battle_elite" or node.nodeType == "boss" then
        local battle, battleProfile, resolveReason = RoguelikeBattleResolver.ResolveNodeBattle(state, node)
        if not battle or not battleProfile then
            return false, resolveReason or "battle_not_found"
        end
        local ok, snapshotOrReason = RoguelikeBattleBridge.StartBattle(state, battle, battleProfile)
        if not ok then
            state.phase = "failed"
            state.chapterResult = { success = false, reason = tostring(snapshotOrReason or "battle_init_failed") }
            return false, snapshotOrReason
        end
        cachedBattleSnapshot = snapshotOrReason
        state.phase = "battle"
        state.currentBattleId = tonumber(battleProfile and battleProfile.id) or tonumber(battle and battle.id)
        state.currentBattleConfig = battle
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

local function leaveNodeBackToMap()
    -- shop 房豁免 cleared，可重复进入；其余房间在离开时落 cleared 标记。
    if state.dungeonState and state.currentNodeId then
        local node = getNode(state.currentNodeId)
        if node and node.nodeType ~= "shop" then
            FloorState.MarkRoomCleared(state.dungeonState, state.currentNodeId)
        end
    end
    state.rewardState = nil
    state.eventState = nil
    state.shopState = nil
    state.campState = nil
    cachedBattleSnapshot = nil
    state.phase = "map"
    state.currentBattleId = nil
    state.currentBattleConfig = nil
    state.rewardReturnMode = "map"
    refreshAvailableNodes()
end

local function enterChapterResult()
    local chapter = RoguelikeMap.GetChapter(state.chapterId) or {}
    local clearRewards = chapter.chapterClearRewards or {}
    if (clearRewards.healPct or 0) > 0 then
        for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(state)) do
            if not hero.isDead then
                local heal = math.floor((hero.maxHp or 0) * clearRewards.healPct)
                hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
            end
        end
    end
    -- 章 1/2 boss 通关：切下一章并重生地牢；金币已在 Tick 里加，避免 double-count。
    if state.chapterId < 103 then
        local nextChapterId = state.chapterId + 1
        local nextChapter = RoguelikeMap.GetChapter(nextChapterId)
        if nextChapter then
            state.chapterId = nextChapterId
            state.levelCap = tonumber(nextChapter.targetMaxLevel) or state.levelCap
            local dungeonState, reason = RoguelikeMap.GenerateChapterMap(nextChapterId, state.seed or 0)
            if not dungeonState then
                state.phase = "failed"
                state.chapterResult = { success = false, reason = "next_chapter_gen_failed:" .. tostring(reason) }
                return
            end
            state.dungeonState = dungeonState
            state.currentNodeId = dungeonState.currentRoomId
            state.visitedNodeIds = state.currentNodeId and { [state.currentNodeId] = true } or {}
            state.selectedNextNodeId = nil
            state.rewardState = nil
            state.eventState = nil
            state.shopState = nil
            state.campState = nil
            state.chapterResult = nil
            state.phase = "map"
            refreshAvailableNodes()
            return
        end
    end
    -- 章 3 boss 通关：终局
    state.phase = "chapter_result"
    state.rewardState = nil
    state.chapterResult = {
        success = true,
        reason = "boss_defeated",
        gold = state.gold,
        equipmentCount = #(state.equipmentIds or {}),
        blessingCount = #(state.blessingIds or {}),
    }
end

local function evaluateFailureIfNoAlive()
    local anyAlive = false
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(state)) do
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

local function refreshContextState()
    local node = getNode(state.currentNodeId)
    if state.phase == "shop" and node then
        state.shopState = RoguelikeShop.BuildShopState(state, node.shopId)
    elseif state.phase == "camp" and node then
        state.campState = RoguelikeCamp.BuildCampState(node.campId, state)
    end
end

function RoguelikeRun.StartRun(config)
    state = resetRunState()
    cachedBattleSnapshot = nil
    RunEnemyGroup.ResetRuntimeGroups()
    local seed = tonumber((config or {}).seed)
    state.seed = seed or 0
    if seed then
        math.randomseed(seed)
    end

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
    if chapter.mapGenProfileId then
        local dungeonState, reason = RoguelikeMap.GenerateChapterMap(chapterId, state.seed or 0)
        if not dungeonState then
            error("failed to generate roguelike map: " .. tostring(reason))
        end
        state.dungeonState = dungeonState
        if dungeonState.currentRoomId then
            state.currentNodeId = dungeonState.currentRoomId
            state.visitedNodeIds = { [state.currentNodeId] = true }
        end
    end

    local starterHeroIds = cloneArray((config or {}).starterHeroIds)
    if #starterHeroIds == 0 then
        starterHeroIds = buildRandomStarterHeroIds()
    end
    state.ownedUnits = buildStarterRoster(state, starterHeroIds)
    RoguelikeRoster.RefreshLegacyViews(state)
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
    local resolved = RoguelikeBattleBridge.ResolveBattle(
        state,
        state.currentBattleConfig or RunBattleConfig.GetBattle(tonumber(state.currentBattleId)),
        RunBattleProfile.GetBattleProfile(tonumber(state.currentBattleId))
    )
    if resolved then
        if evaluateFailureIfNoAlive() then
            return events or {}
        end

        if resolved.won then
            local node = getNode(state.currentNodeId)
            local battle = state.currentBattleConfig or RunBattleConfig.GetBattle(tonumber(state.currentBattleId))
            local battleProfile = RunBattleProfile.GetBattleProfile(tonumber(state.currentBattleId))
            -- 战斗胜利显式管道：节点金币（已由 ResolveBattle 写入）→ 节点掉落 → partyExp →
            -- FeatPicker 升级三选一 → 战斗后休整 → 进入下一房间。
            local lootSummary = grantBattleLoot(node, battleProfile)
            local expReward = grantBattleExp(battle)
            -- BeginSession 内部根据 partyExp 与各 hero.level 推导 pendingPicks，并写回 state.partyLevel；
            -- 此处保留 recalcPartyLevel 调用，是为了同步 levelProgressExp / nextLevelExp 到当前阈值，
            -- 以便 UI 即时刷新进度条。两个 partyLevel 写入是一致结果（前后等价）。
            local session = FeatPicker.BeginSession(state)
            recalcPartyLevel()
            mergeLastBattleSummary({
                expReward = expReward or 0,
                levelUps = {},
                equipmentDropCount = lootSummary.equipmentDropCount or 0,
                blessingDropCount = lootSummary.blessingDropCount or 0,
            })

            -- 启动升级三选一会话；若产生 session 则停在 reward 阶段，由 ChooseReward 链推进；
            -- 若未跨等级则继续后续 rest+前进。
            if session then
                if node and node.nodeType == "boss" then
                    local chapter = RoguelikeMap.GetChapter(state.chapterId) or {}
                    local clearRewards = chapter.chapterClearRewards or {}
                    state.gold = (state.gold or 0) + (clearRewards.gold or 0)
                    state.rewardReturnMode = "chapter_result"
                else
                    state.rewardReturnMode = "map"
                end
                state.phase = "reward"
                return events or {}
            end

            -- 无升级会话：直接做战斗后休整，再前进/进入章节结算。
            RoguelikeBattleBridge.ApplyPostBattleRest(state)
            if node and node.nodeType == "boss" then
                local chapter = RoguelikeMap.GetChapter(state.chapterId) or {}
                local clearRewards = chapter.chapterClearRewards or {}
                state.gold = (state.gold or 0) + (clearRewards.gold or 0)
                enterChapterResult()
                return events or {}
            end

            state.rewardReturnMode = "map"
            leaveNodeBackToMap()
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

    local rewardKind = state.rewardState and state.rewardState.kind or nil
    -- 升级三选一会话由 FeatPicker 处理，且可能链式触发下一会话；
    -- 仅在 session 完全消费完毕后再进入战斗后休整 + 推进路线。
    if rewardKind == "feat_levelup" then
        local ok, result = FeatPicker.Pick(state, tonumber(index) or 0)
        if not ok then
            return false, result
        end
        recalcPartyLevel()
        if state.featPickerSession then
            -- 还有挂起会话，继续停在 reward 阶段。
            state.phase = "reward"
            return true
        end
        -- session 已耗尽：补做战斗后休整，再按 returnMode 路由。
        RoguelikeBattleBridge.ApplyPostBattleRest(state)
        if state.rewardReturnMode == "chapter_result" then
            enterChapterResult()
            return true
        end
        leaveNodeBackToMap()
        return true
    end

    local ok, reason = RoguelikeReward.ApplyReward(state, state.rewardState, tonumber(index) or 0)
    if not ok then
        return false, reason
    end
    recalcPartyLevel()
    if state.rewardReturnMode == "chapter_result" then
        enterChapterResult()
        return true
    end
    if state.rewardReturnMode == "shop" then
        local node = getNode(state.currentNodeId)
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

    local node = getNode(state.currentNodeId)
    local eventId = node and node.eventId or nil
    local ok, resultOrReason = RoguelikeEvent.ResolveOption(state, eventId, tonumber(optionId) or 0)
    if not ok then
        return false, resultOrReason
    end

    local result = resultOrReason or {}
    if result.kind == "done" then
        leaveNodeBackToMap()
        return true
    end
    if result.kind == "reward_group" then
        return openReward(result.rewardGroupId)
    end
    if result.kind == "blessing" then
        BuildConstraints.AddBlessing(state, result.blessingId)
        leaveNodeBackToMap()
        return true
    end
    if result.kind == "equipment" then
        BuildConstraints.AddEquipment(state, result.equipmentId)
        leaveNodeBackToMap()
        return true
    end
    if result.kind == "battle" then
        state.phase = "battle"
        local battleId = tonumber(result.battleId)
        local battle = RunBattleConfig.GetBattle(battleId)
        if not battle then
            state.phase = "failed"
            state.chapterResult = { success = false, reason = "event_battle_not_found" }
            return false, "event_battle_not_found"
        end
        state.currentBattleId = battleId
        local battleProfile = RunBattleProfile.GetBattleProfile(battleId)
        state.currentBattleConfig = battle
        local ok2, reason2 = RoguelikeBattleBridge.StartBattle(state, battle, battleProfile)
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
    local node = getNode(state.currentNodeId)
    local ok, reason = RoguelikeShop.Buy(state, node.shopId, tonumber(goodsId) or 0)
    if not ok then
        return false, reason
    end
    state.shopState = RoguelikeShop.BuildShopState(state, node.shopId)
    return true
end

function RoguelikeRun.ShopRefresh()
    if state.phase ~= "shop" then
        return false, "not_in_shop"
    end
    local node = getNode(state.currentNodeId)
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
    leaveNodeBackToMap()
    return true
end

function RoguelikeRun.CampChoose(actionId)
    if state.phase ~= "camp" then
        return false, "not_in_camp"
    end
    local node = getNode(state.currentNodeId)
    local ok, reason = RoguelikeCamp.ApplyAction(state, node.campId, tonumber(actionId) or 0)
    if not ok then
        return false, reason
    end
    leaveNodeBackToMap()
    return true
end

-- dungeon §4.2：cleared camp 重入时若所有 action 都不可用，允许玩家直接离开（仅作通路）。
function RoguelikeRun.CampLeave()
    if state.phase ~= "camp" then
        return false, "not_in_camp"
    end
    leaveNodeBackToMap()
    return true
end

-- 使用楼梯：根据 stairState.direction 触发上/下楼，并把当前房标 cleared。
function RoguelikeRun.StairUse()
    if state.phase ~= "stair" then
        return false, "not_in_stair"
    end
    if not state.dungeonState then
        return false, "no_dungeon_state"
    end
    local stair = state.stairState or {}
    local direction = stair.direction or "down"
    local prevNodeId = stair.nodeId or state.currentNodeId
    local ok, reason = FloorState.UseStair(state.dungeonState, direction)
    if not ok then
        return false, reason
    end
    if direction == "down" and prevNodeId then
        FloorState.MarkRoomCleared(state.dungeonState, prevNodeId)
    end
    state.visitedNodeIds = {}
    state.currentNodeId = state.dungeonState.currentRoomId
    state.visitedNodeIds[state.currentNodeId] = true
    state.stairState = nil
    state.phase = "map"
    refreshAvailableNodes()
    return true
end

-- 路过楼梯：不上下楼，把楼梯房当通路（标 cleared 后回 map）。
function RoguelikeRun.StairLeave()
    if state.phase ~= "stair" then
        return false, "not_in_stair"
    end
    state.stairState = nil
    leaveNodeBackToMap()
    return true
end

function RoguelikeRun.PromoteBenchHero(benchRosterId)
    if not canManageRoster() then
        return false, "roster_locked"
    end

    local ok, reason = RoguelikeRoster.PromoteBenchHero(state, benchRosterId)
    if not ok then
        return false, reason
    end
    state.lastActionMessage = "候补已直接上阵"
    refreshContextState()
    return true
end

function RoguelikeRun.SwapBenchWithTeam(benchRosterId, teamRosterId)
    if not canManageRoster() then
        return false, "roster_locked"
    end

    local ok, benchHero, teamHero = RoguelikeRoster.SwapBenchWithTeam(state, benchRosterId, teamRosterId)
    if not ok then
        return false, benchHero
    end
    state.lastActionMessage = string.format("%s 替换 %s 上阵", benchHero.name or "候补", teamHero.name or "队员")
    refreshContextState()
    return true
end

return RoguelikeRun

