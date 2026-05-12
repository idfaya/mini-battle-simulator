local RoguelikeMap = require("roguelike.roguelike_map")
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
local ClassRoleConfig = require("config.class_role_config")
local FeatConfig = require("config.feat_config")
local FeatBuildConfig = require("config.feat_build_config")
local SkillRuntimeConfig = require("config.skill_runtime_config")
local RoguelikeBattleResolver = require("roguelike.roguelike_battle_resolver")

local RoguelikeRun = {}
local state = nil
local cachedBattleSnapshot = nil
local STARTER_LEVEL = 1
-- 5e growth: no star progression.
local STARTER_STAR = 1
local CHAPTER_LEVEL_CAP = 10
local DEFAULT_STARTER_TEAM_SIZE = 4
local DEFAULT_STARTER_FRONT_COUNT = 2
local LEVEL_EXP_THRESHOLDS = {
    [1] = 0,
    [2] = 8,
    [3] = 20,
    [4] = 36,
    [5] = 58,
    [6] = 86,
    [7] = 120,
    [8] = 160,
    [9] = 208,
    [10] = 264,
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
    return LEVEL_EXP_THRESHOLDS[lv] or LEVEL_EXP_THRESHOLDS[CHAPTER_LEVEL_CAP] or 0
end

local function getExpToNextLevel(level)
    local lv = math.max(1, tonumber(level) or 1)
    if lv >= (state and state.levelCap or CHAPTER_LEVEL_CAP) then
        return 0
    end
    return math.max(1, getExpThreshold(lv + 1) - getExpThreshold(lv))
end

local function getNodeExp(_nodeType)
    -- Non-battle node exp is reserved by design; current MVP only grants battle.expReward.
    return 0
end

local function getLevelForExp(exp, cap)
    local current = STARTER_LEVEL
    local levelCap = math.max(STARTER_LEVEL, tonumber(cap) or CHAPTER_LEVEL_CAP)
    local totalExp = math.max(0, math.floor(tonumber(exp) or 0))
    for lv = STARTER_LEVEL + 1, levelCap do
        if totalExp >= getExpThreshold(lv) then
            current = lv
        else
            break
        end
    end
    return current
end

local LEVELUP_STAT_FIELDS = {
    { key = "maxHp", label = "HP上限", format = "flat" },
    { key = "def", label = "防御", format = "flat" },
    { key = "ac", label = "护甲等级", format = "flat" },
    { key = "hit", label = "命中", format = "flat" },
    { key = "spellDC", label = "法术DC", format = "flat" },
    { key = "saveFort", label = "强韧豁免", format = "flat" },
    { key = "saveRef", label = "敏捷豁免", format = "flat" },
    { key = "saveWill", label = "意志豁免", format = "flat" },
    { key = "speed", label = "速度", format = "flat" },
    { key = "critRate", label = "暴击率", format = "bp_pct" },
    { key = "blockRate", label = "格挡率", format = "bp_pct" },
    { key = "healBonus", label = "治疗加成", format = "bp_pct" },
}

local function cloneArray(input)
    local result = {}
    for index, value in ipairs(input or {}) do
        result[index] = value
    end
    return result
end

local function resolveFeatEntry(featId)
    return FeatBuildConfig.GetFeat(featId) or FeatConfig.GetFeat(featId)
end

local function resolveOwnedFeatIds(unitOrState)
    if type(unitOrState) ~= "table" then
        return {}
    end
    if type(unitOrState.buildState) == "table" and type(unitOrState.buildState.featIds) == "table" then
        return cloneArray(unitOrState.buildState.featIds)
    end
    return cloneArray(unitOrState.feats or unitOrState.selectedFeatIds)
end

local function captureUnitLevelState(unit)
    if type(unit) ~= "table" then
        return nil
    end
    local stats = {}
    for _, field in ipairs(LEVELUP_STAT_FIELDS) do
        stats[field.key] = tonumber(unit[field.key]) or 0
    end
    return {
        rosterId = tonumber(unit.rosterId) or 0,
        unitId = unit.unitId,
        heroName = unit.name or "职业单位",
        classId = tonumber(unit.classId) or 0,
        level = tonumber(unit.level) or STARTER_LEVEL,
        promotionStage = HeroData.NormalizePromotionStage(unit.promotionStage),
        stats = stats,
        feats = resolveOwnedFeatIds(unit),
    }
end

local function buildLevelUpStatChanges(beforeState, afterUnit)
    local changes = {}
    local beforeStats = beforeState and beforeState.stats or {}
    for _, field in ipairs(LEVELUP_STAT_FIELDS) do
        local afterValue = tonumber(afterUnit and afterUnit[field.key]) or 0
        local beforeValue = tonumber(beforeStats[field.key]) or 0
        local delta = afterValue - beforeValue
        if delta ~= 0 then
            changes[#changes + 1] = {
                key = field.key,
                label = field.label,
                format = field.format,
                delta = delta,
                before = beforeValue,
                after = afterValue,
            }
        end
    end
    return changes
end

local function buildLevelUpFeatChanges(beforeState, afterUnit)
    local result = {}
    local ownedBefore = {}
    for _, featId in ipairs(resolveOwnedFeatIds(beforeState)) do
        ownedBefore[tonumber(featId) or 0] = true
    end
    for _, featId in ipairs(resolveOwnedFeatIds(afterUnit)) do
        local id = tonumber(featId) or 0
        if id > 0 and not ownedBefore[id] then
            local feat = resolveFeatEntry(id)
            result[#result + 1] = {
                featId = id,
                name = feat and feat.name or ("Feat " .. tostring(id)),
                description = feat and (feat.description or feat.code) or "",
            }
        end
    end
    return result
end

local function buildLevelUpSkillCardsFromFeats(gainedFeats)
    local cards = {}
    local seen = {}
    for _, featGain in ipairs(gainedFeats or {}) do
        local feat = resolveFeatEntry(featGain.featId)
        for _, effect in ipairs((feat and feat.effects) or {}) do
            local skillId = nil
            if effect.type == "grant_skill" then
                skillId = tonumber(effect.skill) or 0
            elseif effect.type == "replace_skill" then
                skillId = tonumber(effect.newSkill) or 0
            end
            if skillId and skillId > 0 and not seen[skillId] then
                seen[skillId] = true
                local skill = SkillRuntimeConfig.Get(skillId)
                if skill and skill.hidden ~= true then
                    cards[#cards + 1] = {
                        skillId = skillId,
                        name = skill.name or ("Skill " .. tostring(skillId)),
                        runtimeKind = skill.runtimeKind or "active",
                    }
                end
            end
        end
    end
    return cards
end

local function buildLevelUpDetail(beforeState, afterUnit)
    if not beforeState or not afterUnit then
        return nil
    end
    local gainedFeats = buildLevelUpFeatChanges(beforeState, afterUnit)
    return {
        rosterId = beforeState.rosterId,
        unitId = beforeState.unitId,
        heroName = beforeState.heroName,
        classId = beforeState.classId,
        levelBefore = tonumber(beforeState.level) or STARTER_LEVEL,
        levelAfter = tonumber(afterUnit.level) or STARTER_LEVEL,
        promotionStageBefore = beforeState.promotionStage,
        promotionStageAfter = HeroData.NormalizePromotionStage(afterUnit.promotionStage),
        statChanges = buildLevelUpStatChanges(beforeState, afterUnit),
        gainedFeats = gainedFeats,
        gainedSkillCards = buildLevelUpSkillCardsFromFeats(gainedFeats),
    }
end

local function buildLevelUpDetails(beforeState, afterUnit)
    if not beforeState or not afterUnit then
        return {}
    end
    local finalLevel = tonumber(afterUnit.level) or STARTER_LEVEL
    local finalStage = HeroData.NormalizePromotionStage(afterUnit.promotionStage)
    local currentState = deepCopyTable(beforeState)
    local details = {}
    for targetLevel = (tonumber(beforeState.level) or STARTER_LEVEL) + 1, finalLevel do
        local targetStage = currentState.promotionStage
        if targetStage == "low"
            and (finalStage == "mid" or finalStage == "high")
            and targetLevel >= HeroData.GetPromotionStageLevel("mid") then
            targetStage = "mid"
        end
        if targetStage == "mid"
            and finalStage == "high"
            and targetLevel >= HeroData.GetPromotionStageLevel("high") then
            targetStage = "high"
        end

        local stepUnit
        if targetLevel == finalLevel then
            stepUnit = afterUnit
        else
            stepUnit = HeroData.CreateClassUnit(beforeState.classId, {
                rosterId = beforeState.rosterId,
                unitId = beforeState.unitId,
                promotionStage = targetStage,
                level = targetLevel,
                teamState = "active",
                source = "battle_level_preview",
            })
            if stepUnit then
                stepUnit.rosterId = beforeState.rosterId
                stepUnit.unitId = beforeState.unitId
                stepUnit.name = beforeState.heroName
            end
        end

        if stepUnit then
            local detail = buildLevelUpDetail(currentState, stepUnit)
            if detail then
                details[#details + 1] = detail
                currentState = captureUnitLevelState(stepUnit) or currentState
            end
        end
    end
    return details
end

local function mergeLastBattleSummary(fields)
    state.lastBattleSummary = state.lastBattleSummary or {}
    for key, value in pairs(fields or {}) do
        state.lastBattleSummary[key] = value
    end
end

local function refreshUnitLevel(unit, newLevel, newExp)
    if not unit then
        return false
    end
    local oldLevel = tonumber(unit.level) or STARTER_LEVEL
    local oldMaxHp = tonumber(unit.maxHp) or 1
    local oldCurrentHp = tonumber(unit.currentHp) or 0
    local isDead = unit.isDead == true or oldCurrentHp <= 0 or unit.teamState == "dead"
    HeroData.RefreshClassUnit(unit, {
        level = newLevel,
        exp = newExp,
        currentHp = oldCurrentHp,
        isDead = isDead,
        teamState = unit.teamState,
        promotionStage = unit.promotionStage,
        source = unit.source,
    })
    if not isDead then
        local deltaHp = (tonumber(unit.maxHp) or oldMaxHp) - oldMaxHp
        unit.currentHp = math.max(1, math.min(unit.maxHp or oldCurrentHp, oldCurrentHp + math.max(0, deltaHp)))
        unit.hp = unit.currentHp
    end
    return (tonumber(unit.level) or oldLevel) > oldLevel
end

local function shouldOpenBattleClassCardReward(node)
    if not node then
        return false
    end
    return node.nodeType == "battle_elite" or node.nodeType == "boss"
end

local function grantBattleEquipmentDrop(node, battleProfile)
    local equipmentId = RoguelikeReward.RollBattleEquipmentDrop(node and node.nodeType or nil, battleProfile)
    if not equipmentId then
        return nil
    end
    state.equipmentIds = state.equipmentIds or {}
    addUnique(state.equipmentIds, equipmentId)
    return equipmentId
end

local function grantBattleLoot(node, battleProfile)
    if not node then
        return 0
    end
    local rollCount = 0
    if node.nodeType == "battle_normal" then
        rollCount = 1
    elseif node.nodeType == "battle_elite" then
        rollCount = math.max(1, tonumber(battleProfile and battleProfile.eliteBonus and battleProfile.eliteBonus.equipmentRoll) or 1)
    end
    local dropCount = 0
    for _ = 1, rollCount do
        if grantBattleEquipmentDrop(node, battleProfile) then
            dropCount = dropCount + 1
        end
    end
    return dropCount
end

local function grantBattleExp(battle)
    local expReward = math.max(0, math.floor(tonumber(battle and battle.expReward) or 0))
    state.lastBattleExpReward = expReward
    state.lastLevelUpUnits = {}
    state.lastBattleLevelUpDetails = {}
    if expReward <= 0 then
        return {}
    end
    local leveledUnits = {}
    local levelUpDetails = {}
    local recipients = 0
    for _, unit in ipairs(RoguelikeRoster.GetTeamUnits(state)) do
        if unit.teamState == "active" and unit.isDead ~= true and (tonumber(unit.currentHp) or 0) > 0 then
            local oldLevel = tonumber(unit.level) or STARTER_LEVEL
            local beforeState = captureUnitLevelState(unit)
            local newExp = (tonumber(unit.exp) or 0) + expReward
            local newLevel = getLevelForExp(newExp, state.levelCap)
            refreshUnitLevel(unit, newLevel, newExp)
            RoguelikeReward.ResolvePendingPromotion(state, unit, "battle_level")
            recipients = recipients + 1
            if newLevel > oldLevel then
                leveledUnits[#leveledUnits + 1] = unit.unitId or unit.name or tostring(unit.rosterId)
                for _, detail in ipairs(buildLevelUpDetails(beforeState, unit)) do
                    levelUpDetails[#levelUpDetails + 1] = detail
                end
            end
        end
    end
    state.partyExp = (state.partyExp or 0) + expReward
    state.lastLevelUpUnits = leveledUnits
    state.lastBattleLevelUpDetails = levelUpDetails
    if recipients <= 0 then
        return levelUpDetails
    end
    if #leveledUnits > 0 then
        state.lastActionMessage = string.format("战斗胜利，获得 %d 经验，%d 名单位升级", expReward, #leveledUnits)
    else
        state.lastActionMessage = string.format("战斗胜利，获得 %d 经验", expReward)
    end
    return levelUpDetails
end

local function grantRunExp(amount, sourceLabel)
    local gain = math.max(0, math.floor(tonumber(amount) or 0))
    if gain <= 0 then
        return 0
    end
    state.partyExp = (state.partyExp or 0) + gain
    state.lastActionMessage = string.format("%s，获得 %d 经验", sourceLabel or "获得经验", gain)
    return gain
end

local function recalcRecommendedLevel()
    -- 推荐等级 = 存活成员等级的平均值，向下取整；用于敌人缩放与新兵接入基准。
    local total, count = 0, 0
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(state)) do
        if not hero.isDead then
            total = total + (tonumber(hero.level) or 1)
            count = count + 1
        end
    end
    if count == 0 then
        state.partyLevel = STARTER_LEVEL
    else
        state.partyLevel = math.max(STARTER_LEVEL, math.floor(total / count))
    end
    local sampleExp = 0
    local sampleCount = 0
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(state)) do
        if not hero.isDead then
            sampleExp = sampleExp + (tonumber(hero.exp) or 0)
            sampleCount = sampleCount + 1
        end
    end
    if sampleCount > 0 then
        sampleExp = math.floor(sampleExp / sampleCount)
    end
    local currentThreshold = getExpThreshold(state.partyLevel or STARTER_LEVEL)
    state.levelProgressExp = math.max(0, sampleExp - currentThreshold)
    state.nextLevelExp = getExpToNextLevel(state.partyLevel or STARTER_LEVEL)
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
                promotionStage = "low",
                level = STARTER_LEVEL,
                exp = 0,
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
        pendingRecruitHeroId = nil,
        maxHeroCount = 5,
        currentBattleId = nil,
        currentBattleConfig = nil,
        lastBattleSummary = nil,
        mapState = nil,
        seed = nil,
        rewardReturnMode = "map",
        nextRosterId = 1,
    }
end

state = resetRunState()
cachedBattleSnapshot = nil

local function refreshAvailableNodes()
    local available = RoguelikeMap.GetAvailableNextNodeIds(state.currentNodeId, state.visitedNodeIds, state.chapterId, state.mapState)
    state.availableNextNodeIds = available
    if #available == 1 then
        state.selectedNextNodeId = available[1]
    elseif not contains(available, state.selectedNextNodeId) then
        state.selectedNextNodeId = nil
    end
end

local function getNode(nodeId)
    return RoguelikeMap.GetNode(nodeId, state and state.mapState or nil)
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

    if node.nodeType == "recruit" then
        local rewardState = RoguelikeReward.GenerateRecruitRewardState(state, node.recruitPoolId)
        if not rewardState or #(rewardState.options or {}) == 0 then
            return false, "recruit_unavailable"
        end
        state.phase = "reward"
        state.rewardState = rewardState
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

local function openBattleLevelUpReward()
    local rewardState = RoguelikeReward.GenerateLevelUpRewardState(state)
    if not rewardState or #(rewardState.options or {}) == 0 then
        -- 无可升级成员（全员已到等级上限），直接返回地图。
        return false, "levelup_unavailable"
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
        local mapState, reason = RoguelikeMap.GenerateChapterMap(chapterId, state.seed or 0)
        if not mapState then
            error("failed to generate roguelike map: " .. tostring(reason))
        end
        state.mapState = mapState
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
            local levelUpDetails = grantBattleExp(battle)
            local equipmentDropCount = grantBattleLoot(node, battleProfile)
            recalcRecommendedLevel()
            mergeLastBattleSummary({
                expReward = state.lastBattleExpReward or 0,
                levelUps = levelUpDetails or {},
                equipmentDropCount = equipmentDropCount or 0,
            })
            if node and node.nodeType == "boss" then
                local chapter = RoguelikeMap.GetChapter(state.chapterId) or {}
                local clearRewards = chapter.chapterClearRewards or {}
                state.gold = (state.gold or 0) + (clearRewards.gold or 0)
                state.rewardReturnMode = "chapter_result"
                local opened = shouldOpenBattleClassCardReward(node) and openBattleLevelUpReward()
                if not opened then
                    enterChapterResult()
                end
                return events or {}
            end

            state.rewardReturnMode = "map"
            local opened = shouldOpenBattleClassCardReward(node) and openBattleLevelUpReward()
            if not opened then
                leaveNodeBackToMap()
            end
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
    recalcRecommendedLevel()
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
    if result.kind == "equipment" then
        state.equipmentIds = state.equipmentIds or {}
        addUnique(state.equipmentIds, result.equipmentId)
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
    local node = getNode(state.currentNodeId)
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
    local node = getNode(state.currentNodeId)
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
