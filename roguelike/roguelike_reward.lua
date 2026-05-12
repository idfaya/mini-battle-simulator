local RunRewardPool = require("config.roguelike.run_reward_pool")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local RunRecruitPool = require("config.roguelike.run_recruit_pool")
local HeroData = require("config.hero_data")
local FeatConfig = require("config.feat_config")
local FeatBuildConfig = require("config.feat_build_config")
local ClassBuildProgression = require("config.class_build_progression")
local HeroBuild = require("modules.hero_build")
local BattleEvent = require("core.battle_event")
local RoguelikeRoster = require("roguelike.roguelike_roster")

local RoguelikeReward = {}
local RECRUIT_LEVEL = 1
local RECRUIT_STAR = 1
local PROMOTION_REQUIRED_LEVELS = {
    mid = 3,
    high = 6,
}
local EQUIPMENT_RARITY_TIER = {
    common = 1,
    rare = 2,
    boss = 3,
}

local function allocateRosterId(runState)
    runState.nextRosterId = (runState.nextRosterId or 1)
    local rosterId = runState.nextRosterId
    runState.nextRosterId = rosterId + 1
    return rosterId
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function containsHeroId(roster, heroId)
    for _, hero in ipairs(roster or {}) do
        if tonumber(hero.heroId) == tonumber(heroId) then
            return true
        end
    end
    return false
end

local function collectAllUnits(runState)
    return RoguelikeRoster.GetOwnedUnits(runState)
end

local function getClassIdFromHeroId(heroId)
    local heroInfo = HeroData.GetHeroInfo(heroId)
    return tonumber(heroInfo and heroInfo.Class) or 0
end

local function containsClassId(roster, classId)
    for _, hero in ipairs(roster or {}) do
        if tonumber(hero.classId) == tonumber(classId) then
            return true
        end
    end
    return false
end

local function findClassUnit(runState, classId)
    for _, hero in ipairs(collectAllUnits(runState)) do
        if tonumber(hero.classId) == tonumber(classId) then
            return hero
        end
    end
    return nil
end

local function getActiveUnitCount(runState)
    return RoguelikeRoster.GetTeamUnitCount(runState)
end

local function hasFreeActiveSlot(runState)
    return getActiveUnitCount(runState) < (runState.maxHeroCount or 5)
end

local function getNextPromotionStage(stage)
    local current = HeroData.NormalizePromotionStage(stage)
    if current == "low" then
        return "mid"
    end
    if current == "mid" then
        return "high"
    end
    return "high"
end

local function normalizePendingPromotionTarget(stage)
    local value = HeroData.NormalizePromotionStage(stage)
    if value == "mid" or value == "high" then
        return value
    end
    return nil
end

local function getPromotionRequiredLevel(targetStage)
    return PROMOTION_REQUIRED_LEVELS[normalizePendingPromotionTarget(targetStage)] or 0
end

local function getPromotionStageLabel(stage)
    local value = HeroData.NormalizePromotionStage(stage)
    if value == "mid" then
        return "中阶"
    end
    if value == "high" then
        return "高阶"
    end
    return "低阶"
end

local function getCurrentLevel(unit)
    return math.max(1, tonumber(unit and unit.level) or 1)
end

local function isPromotionUnlocked(unit, targetStage)
    return getCurrentLevel(unit) >= getPromotionRequiredLevel(targetStage)
end

local function collectEquipmentPool(maxTier)
    local pool = {}
    for equipmentId, equipment in pairs(RunEquipmentConfig.EQUIPMENTS or {}) do
        local rarityTier = EQUIPMENT_RARITY_TIER[tostring(equipment and equipment.rarity or "common")] or 1
        if rarityTier <= maxTier then
            pool[#pool + 1] = tonumber(equipmentId)
        end
    end
    table.sort(pool)
    return pool
end

local function chooseEquipmentId(maxTier)
    local pool = collectEquipmentPool(maxTier)
    if #pool <= 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

local function rollBattleEquipmentId(nodeType, encounter)
    local resolvedNodeType = tostring(nodeType or "")
    if resolvedNodeType == "battle_normal" then
        if math.random() > 0.35 then
            return nil
        end
        local rareChance = 0.20
        local maxTier = math.random() <= rareChance and 2 or 1
        return chooseEquipmentId(maxTier)
    end
    if resolvedNodeType == "battle_elite" then
        local rarityBonus = math.max(0, tonumber(encounter and encounter.eliteBonus and encounter.eliteBonus.rewardRarityBonus) or 0)
        local roll = math.random()
        local rareThreshold = math.min(0.75, 0.30 + rarityBonus * 0.10)
        local bossThreshold = math.min(0.35, math.max(0, (rarityBonus - 1) * 0.10))
        if roll <= bossThreshold then
            return chooseEquipmentId(3)
        end
        if roll <= (bossThreshold + rareThreshold) then
            return chooseEquipmentId(2)
        end
        return chooseEquipmentId(1)
    end
    return nil
end

local function applyPromotionStage(unit, afterStage, source)
    local beforeStage = HeroData.NormalizePromotionStage(unit and unit.promotionStage)
    local targetStage = HeroData.NormalizePromotionStage(afterStage or getNextPromotionStage(beforeStage))
    local oldMaxHp = tonumber(unit and unit.maxHp) or 1
    local oldCurrentHp = tonumber(unit and unit.currentHp) or 0
    local isDead = unit and (unit.isDead == true or oldCurrentHp <= 0 or unit.teamState == "dead") or false
    HeroData.RefreshClassUnit(unit, {
        promotionStage = targetStage,
        clearPromotionPendingTarget = true,
        teamState = unit.teamState,
        currentHp = isDead and 0 or math.max(1, oldCurrentHp + ((tonumber(unit.maxHp) or oldMaxHp) - oldMaxHp)),
        isDead = isDead,
        source = source or unit.source,
    })
    return beforeStage, targetStage
end

local function buildPromotionCardPreview(ownedUnit)
    local before = HeroData.NormalizePromotionStage(ownedUnit.promotionStage)
    local after = getNextPromotionStage(before)
    local requiredLevel = getPromotionRequiredLevel(after)
    local unlocked = isPromotionUnlocked(ownedUnit, after)
    local resultType = unlocked and "class_promotion" or "promotion_pending"
    local description = unlocked
        and (getPromotionStageLabel(before) .. " → " .. getPromotionStageLabel(after))
        or string.format("%s → %s（%d级解锁，当前%d级）",
            getPromotionStageLabel(before), getPromotionStageLabel(after), requiredLevel, getCurrentLevel(ownedUnit))
    return {
        resultType = resultType,
        teamState = ownedUnit.teamState or "active",
        promotionStageBefore = before,
        promotionStageAfter = after,
        promotionPendingTarget = unlocked and nil or after,
        requiredLevel = requiredLevel,
        summaryKey = HeroData.GetClassCardSummaryKey(tonumber(ownedUnit.classId) or 0, after),
        description = description,
    }
end

local function buildClassCardPreview(runState, classId)
    local ownedUnit = findClassUnit(runState, classId)
    if ownedUnit then
        return buildPromotionCardPreview(ownedUnit)
    end
    local teamState = hasFreeActiveSlot(runState) and "active" or "bench"
    return {
        resultType = "new_class_unit",
        teamState = teamState,
        promotionStageBefore = nil,
        promotionStageAfter = "low",
        promotionPendingTarget = nil,
        requiredLevel = nil,
        summaryKey = HeroData.GetClassCardSummaryKey(classId, "low"),
        description = "获得新职业单位 · 低阶",
    }
end

local function resolveExistingClassCard(runState, targetHero, source)
    local beforeStage = HeroData.NormalizePromotionStage(targetHero.promotionStage)
    if beforeStage == "high" then
        return false, "class_already_high"
    end
    local afterStage = getNextPromotionStage(beforeStage)
    if isPromotionUnlocked(targetHero, afterStage) then
        local oldStage, newStage = applyPromotionStage(targetHero, afterStage, source)
        BattleEvent.Publish("DebugCounterTiming", {
            stage = "roguelike_reward_class_card",
            source = "roguelike.roguelike_reward",
            data = {
                heroName = targetHero.name,
                heroId = targetHero.heroId,
                classId = targetHero.classId,
                promotionStageBefore = oldStage,
                promotionStageAfter = newStage,
                summaryKey = HeroData.GetClassCardSummaryKey(targetHero.classId, newStage),
            },
        })
        runState.lastActionMessage = string.format("%s 进阶：%s → %s",
            targetHero.name or "职业单位", getPromotionStageLabel(oldStage), getPromotionStageLabel(newStage))
        return true, "class_promotion"
    end
    targetHero.promotionPendingTarget = afterStage
    runState.lastActionMessage = string.format("%s 获得挂起进阶：达到 Lv%d 后升为%s",
        targetHero.name or "职业单位", getPromotionRequiredLevel(afterStage), getPromotionStageLabel(afterStage))
    return true, "promotion_pending"
end

local function weightedPick(entries, taken)
    local total = 0
    for index, entry in ipairs(entries or {}) do
        if not taken[index] then
            total = total + math.max(0, tonumber(entry.weight) or 0)
        end
    end
    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    local cursor = 0
    for index, entry in ipairs(entries or {}) do
        if not taken[index] then
            cursor = cursor + math.max(0, tonumber(entry.weight) or 0)
            if roll <= cursor then
                return index, entry
            end
        end
    end

    return nil
end

local function buildLabel(entry)
    if entry.rewardType == "gold" then
        return string.format("金币 +%d", entry.value or 0)
    end
    if entry.rewardType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(entry.refId)
        return equipment and equipment.name or ("装备 " .. tostring(entry.refId))
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.name or ("祝福 " .. tostring(entry.refId))
    end
    if entry.rewardType == "recruit" then
        return "招募 " .. HeroData.GetHeroName(entry.refId)
    end
    return tostring(entry.rewardType or "reward")
end

local function buildDescription(entry)
    if entry.rewardType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(entry.refId)
        return equipment and equipment.code or ""
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.code or ""
    end
    if entry.rewardType == "recruit" then
        return HeroData.GetClassName((HeroData.GetHeroInfo(entry.refId) or {}).Class or 0)
    end
    return ""
end

local function addUnique(list, value)
    if not contains(list, value) then
        list[#list + 1] = value
    end
end

local function isFighterBuildHero(hero)
    return tonumber(hero and hero.classId) == 2
end

local function getEligibleFeatPool(hero)
    if not isFighterBuildHero(hero) then
        return FeatConfig.GetEligibleFeats(hero.classId, (hero.level or 1) + 1, hero.feats)
    end
    local nextLevel = (hero.level or 1) + 1
    local entry = ClassBuildProgression.GetLevelEntry(hero.classId, nextLevel)
    if not entry then
        return {}
    end
    local used = {}
    for _, featId in ipairs(hero.feats or {}) do
        used[tonumber(featId) or 0] = true
    end
    local result = {}
    local added = {}

    for _, featId in ipairs(entry.fixed or {}) do
        local def = FeatBuildConfig.GetFeat(featId)
        local id = tonumber(def and def.id) or 0
        if id > 0 and not used[id] and not added[id] then
            result[#result + 1] = def
            added[id] = true
        end
    end

    if entry.choiceGroup then
        local featPool = FeatBuildConfig.GetFeatsByLevel(hero.classId, nextLevel, entry.choiceGroup)
        for _, def in ipairs(featPool) do
            local id = tonumber(def and def.id) or 0
            if id > 0 and not used[id] and not added[id] then
                result[#result + 1] = def
                added[id] = true
            end
        end
    end
    return result
end

local function createHeroRecord(runState, heroId)
    local classId = getClassIdFromHeroId(heroId)
    if classId <= 0 then
        return nil
    end
    local rosterId = allocateRosterId(runState)
    return HeroData.CreateClassUnit(classId, {
        rosterId = rosterId,
        unitId = string.format("class_unit_%d_%d", classId, rosterId),
        promotionStage = "low",
        level = math.max(RECRUIT_LEVEL, tonumber(runState.partyLevel) or RECRUIT_LEVEL),
        exp = 0,
        teamState = hasFreeActiveSlot(runState) and "active" or "bench",
        source = "reward",
    })
end

function RoguelikeReward.AddRecruit(runState, heroId, options)
    local recruitOptions = options or {}
    local classId = getClassIdFromHeroId(heroId)
    if classId <= 0 then
        return false, "invalid_recruit"
    end

    local existingUnit = findClassUnit(runState, classId)
    if existingUnit then
        local ok, reason = resolveExistingClassCard(runState, existingUnit, recruitOptions.forceBench and "recruit_bench" or "reward")
        if not ok then
            return false, reason
        end
        return true, existingUnit
    end

    local heroRecord = createHeroRecord(runState, heroId)
    if not heroRecord then
        return false, "invalid_recruit"
    end
    heroRecord.ultimateChargesMax = heroRecord.ultimateChargesMax or 1
    heroRecord.ultimateCharges = heroRecord.ultimateCharges or heroRecord.ultimateChargesMax

    if recruitOptions.forceBench then
        RoguelikeRoster.AddOwnedUnit(runState, heroRecord, "bench")
        runState.lastActionMessage = "新职业卡已加入候补"
        return true, heroRecord
    end

    if hasFreeActiveSlot(runState) then
        RoguelikeRoster.AddOwnedUnit(runState, heroRecord, "active")
        runState.lastActionMessage = "新职业卡已直接加入上阵队伍"
    else
        RoguelikeRoster.AddOwnedUnit(runState, heroRecord, "bench")
        runState.lastActionMessage = "新职业卡已加入候补"
    end

    return true, heroRecord
end

function RoguelikeReward.GenerateRecruitRewardState(runState, recruitPoolId, optionCount)
    local count = math.max(1, tonumber(optionCount) or 3)
    local poolConfig = recruitPoolId and RunRecruitPool.GetPool(recruitPoolId) or nil
    if poolConfig then
        count = math.max(1, tonumber(optionCount) or tonumber(poolConfig.optionCount) or 3)
    end
    local pool = (poolConfig and poolConfig.heroIds) or HeroData.GetAllHeroIds() or {}
    local classPool = {}
    local classSeen = {}
    for _, heroId in ipairs(pool) do
        local classId = getClassIdFromHeroId(heroId)
        if classId > 0 and not classSeen[classId] then
            classSeen[classId] = true
            classPool[#classPool + 1] = classId
        end
    end
    local candidates = {}
    for _, classId in ipairs(classPool) do
        local unit = findClassUnit(runState, classId)
        if not unit
            or (HeroData.NormalizePromotionStage(unit.promotionStage) ~= "high"
                and normalizePendingPromotionTarget(unit.promotionPendingTarget) == nil) then
            candidates[#candidates + 1] = classId
        end
    end
    if #candidates == 0 then
        candidates = classPool
    end

    local options = {}
    local picked = {}
    local pickedCount = 0
    while #options < count and pickedCount < #candidates do
        local idx = math.random(1, #candidates)
        local classId = candidates[idx]
        if not picked[classId] then
            local heroId = HeroData.GetRepresentativeHeroId(classId)
            local preview = buildClassCardPreview(runState, classId)
            picked[classId] = true
            pickedCount = pickedCount + 1
            options[#options + 1] = {
                rewardType = "recruit",
                refId = heroId,
                heroName = HeroData.GetClassName(classId),
                classId = classId,
                resultType = preview.resultType,
                teamState = preview.teamState,
                promotionStageBefore = preview.promotionStageBefore,
                promotionStageAfter = preview.promotionStageAfter,
                summaryKey = preview.summaryKey,
                label = "职业卡 " .. HeroData.GetClassName(classId),
                requiredLevel = preview.requiredLevel,
                promotionPendingTarget = preview.promotionPendingTarget,
                description = preview.description,
            }
        end
    end

    return {
        groupId = tonumber(recruitPoolId) or 0,
        kind = "node_recruit",
        options = options,
    }
end

-- ==========================================================================
-- Battle reward now resolves as "职业卡三选一"。
-- Compatibility note:
--   - Keep rewardState.kind = "battle_levelup" for existing external callers.
--   - Keep rewardType = "levelup" on options, but payload now carries class-card fields.
-- ==========================================================================

function RoguelikeReward.GenerateLevelUpRewardState(runState)
    local existing = {}
    local existingSeen = {}
    for _, unit in ipairs(collectAllUnits(runState)) do
        local classId = tonumber(unit.classId) or 0
        if classId > 0
            and HeroData.NormalizePromotionStage(unit.promotionStage) ~= "high"
            and normalizePendingPromotionTarget(unit.promotionPendingTarget) == nil
            and not existingSeen[classId] then
            existingSeen[classId] = true
            existing[#existing + 1] = classId
        end
    end

    local unowned = {}
    for _, classId in ipairs(HeroData.GetAllClassIds() or {}) do
        if not findClassUnit(runState, classId) then
            unowned[#unowned + 1] = classId
        end
    end

    if #existing == 0 and #unowned == 0 then
        return nil
    end

    local candidates = {}
    local picked = {}
    local function pickFromPool(pool, limit)
        local used = 0
        local guard = 0
        while used < limit and guard < #pool * 2 do
            guard = guard + 1
            local classId = pool[math.random(1, #pool)]
            if classId and not picked[classId] then
                picked[classId] = true
                candidates[#candidates + 1] = classId
                used = used + 1
            end
        end
    end

    pickFromPool(existing, math.min(2, #existing))
    if #candidates < 3 and #unowned > 0 then
        pickFromPool(unowned, math.min(3 - #candidates, #unowned))
    end
    if #candidates < 3 and #existing > 0 then
        pickFromPool(existing, math.min(3 - #candidates, #existing))
    end

    local options = {}
    for _, classId in ipairs(candidates) do
        local preview = buildClassCardPreview(runState, classId)
        local heroId = HeroData.GetRepresentativeHeroId(classId)
        local unit = findClassUnit(runState, classId)
        options[#options + 1] = {
            rewardType = "levelup",
            rosterId = unit and unit.rosterId or nil,
            heroName = HeroData.GetClassName(classId),
            classId = classId,
            nextLevel = HeroData.GetPromotionStageLevel(preview.promotionStageAfter),
            refId = heroId,
            featId = nil,
            featName = preview.resultType == "new_class_unit" and "新职业单位" or "同职业进阶",
            featCode = preview.resultType == "new_class_unit"
                and ("获得 " .. getPromotionStageLabel(preview.promotionStageAfter) .. " 职业单位")
                or preview.description,
            featTags = { preview.resultType },
            resultType = preview.resultType,
            teamState = preview.teamState,
            promotionStageBefore = preview.promotionStageBefore,
            promotionStageAfter = preview.promotionStageAfter,
            promotionPendingTarget = preview.promotionPendingTarget,
            requiredLevel = preview.requiredLevel,
            summaryKey = preview.summaryKey,
            label = string.format("职业卡：%s", HeroData.GetClassName(classId)),
            description = preview.description,
        }
    end

    if #options == 0 then
        return nil
    end

    return {
        groupId = 0,
        kind = "battle_levelup",
        options = options,
    }
end

function RoguelikeReward.ApplyLevelUpReward(runState, option)
    if not option or option.rewardType ~= "levelup" then
        return false, "invalid_levelup"
    end
    local classId = tonumber(option.classId) or getClassIdFromHeroId(option.refId)
    if classId <= 0 then
        return false, "class_not_found"
    end

    local targetHero = findClassUnit(runState, classId)
    if not targetHero then
        local teamState = hasFreeActiveSlot(runState) and "active" or "bench"
        local rosterId = allocateRosterId(runState)
        local created = HeroData.CreateClassUnit(classId, {
            rosterId = rosterId,
            unitId = string.format("class_unit_%d_%d", classId, rosterId),
            promotionStage = HeroData.NormalizePromotionStage(option.promotionStageAfter or "low"),
            level = math.max(RECRUIT_LEVEL, tonumber(runState.partyLevel) or RECRUIT_LEVEL),
            exp = 0,
            teamState = teamState,
            source = "battle_reward",
        })
        if not created then
            return false, "create_class_unit_failed"
        end
        if teamState == "active" then
            RoguelikeRoster.AddOwnedUnit(runState, created, "active")
        else
            RoguelikeRoster.AddOwnedUnit(runState, created, "bench")
        end
        runState.lastActionMessage = string.format("%s 已加入队伍（%s）",
            created.name or "职业单位", getPromotionStageLabel(created.promotionStage))
        return true
    end
    return resolveExistingClassCard(runState, targetHero, "battle_reward")
end

function RoguelikeReward.ResolvePendingPromotion(runState, unit, source)
    if type(unit) ~= "table" then
        return false
    end
    local targetStage = normalizePendingPromotionTarget(unit.promotionPendingTarget)
    if not targetStage or not isPromotionUnlocked(unit, targetStage) then
        return false
    end
    local oldStage, newStage = applyPromotionStage(unit, targetStage, source or "battle_level")
    runState.lastActionMessage = string.format("%s 达到等级门槛，自动进阶：%s → %s",
        unit.name or "职业单位", getPromotionStageLabel(oldStage), getPromotionStageLabel(newStage))
    return true
end

function RoguelikeReward.RollBattleEquipmentDrop(nodeType, encounter)
    return rollBattleEquipmentId(nodeType, encounter)
end

function RoguelikeReward.GetPromotionRequiredLevel(targetStage)
    return getPromotionRequiredLevel(targetStage)
end

function RoguelikeReward.GenerateRewardState(groupId)
    local group = RunRewardPool.GetGroup(groupId)
    if not group then
        return nil
    end

    local options = {}
    local taken = {}
    local required = ((group.constraints or {}).requireAtLeastOne) or {}

    for _, rewardType in ipairs(required) do
        for index, entry in ipairs(group.options or {}) do
            if entry.rewardType == rewardType and not taken[index] then
                taken[index] = true
                options[#options + 1] = {
                    rewardType = entry.rewardType,
                    refId = entry.refId,
                    value = entry.value,
                    label = buildLabel(entry),
                    description = buildDescription(entry),
                }
                break
            end
        end
    end

    while #options < (group.optionCount or 1) do
        local pickedIndex, entry = weightedPick(group.options, taken)
        if not pickedIndex or not entry then
            break
        end
        taken[pickedIndex] = true
        options[#options + 1] = {
            rewardType = entry.rewardType,
            refId = entry.refId,
            value = entry.value,
            label = buildLabel(entry),
            description = buildDescription(entry),
        }
    end

    return {
        groupId = groupId,
        kind = group.kind,
        options = options,
    }
end

function RoguelikeReward.ApplyReward(runState, rewardState, index)
    local option = rewardState and rewardState.options and rewardState.options[index] or nil
    if not option then
        return false, "invalid_reward"
    end

    if option.rewardType == "gold" then
        runState.gold = (runState.gold or 0) + (option.value or 0)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "equipment" then
        addUnique(runState.equipmentIds, option.refId)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "blessing" then
        addUnique(runState.blessingIds, option.refId)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "recruit" then
        local added, reason = RoguelikeReward.AddRecruit(runState, option.refId)
        if not added then
            return false, reason
        end
        if not runState.lastActionMessage or runState.lastActionMessage == "" then
            runState.lastActionMessage = option.label
        end
    elseif option.rewardType == "levelup" then
        local applied, reason = RoguelikeReward.ApplyLevelUpReward(runState, option)
        if not applied then
            return false, reason
        end
    else
        return false, "unsupported_reward"
    end

    return true
end

return RoguelikeReward
