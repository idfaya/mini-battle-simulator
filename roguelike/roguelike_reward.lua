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

local RoguelikeReward = {}
local RECRUIT_LEVEL = 1
local RECRUIT_STAR = 1

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
    local result = {}
    for _, hero in ipairs(runState.teamRoster or {}) do
        result[#result + 1] = hero
    end
    for _, hero in ipairs(runState.benchRoster or {}) do
        result[#result + 1] = hero
    end
    return result
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
    return #(runState.teamRoster or {})
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

local function buildClassCardPreview(runState, classId)
    local ownedUnit = findClassUnit(runState, classId)
    if ownedUnit then
        local before = HeroData.NormalizePromotionStage(ownedUnit.promotionStage)
        local after = getNextPromotionStage(before)
        return {
            resultType = "class_promotion",
            teamState = ownedUnit.teamState or "active",
            promotionStageBefore = before,
            promotionStageAfter = after,
            summaryKey = HeroData.GetClassCardSummaryKey(classId, after),
        }
    end
    local teamState = hasFreeActiveSlot(runState) and "active" or "bench"
    return {
        resultType = "new_class_unit",
        teamState = teamState,
        promotionStageBefore = nil,
        promotionStageAfter = "low",
        summaryKey = HeroData.GetClassCardSummaryKey(classId, "low"),
    }
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
        return equipment and equipment.name or ("Equipment " .. tostring(entry.refId))
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.name or ("Blessing " .. tostring(entry.refId))
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
        local beforeStage = HeroData.NormalizePromotionStage(existingUnit.promotionStage)
        if beforeStage == "high" then
            return false, "class_already_high"
        end
        local afterStage = getNextPromotionStage(beforeStage)
        local oldMaxHp = tonumber(existingUnit.maxHp) or 1
        local oldCurrentHp = tonumber(existingUnit.currentHp) or 0
        local isDead = existingUnit.isDead == true or oldCurrentHp <= 0 or existingUnit.teamState == "dead"
        HeroData.RefreshClassUnit(existingUnit, {
            promotionStage = afterStage,
            teamState = existingUnit.teamState,
            currentHp = isDead and 0 or math.max(1, oldCurrentHp + ((tonumber(existingUnit.maxHp) or oldMaxHp) - oldMaxHp)),
            isDead = isDead,
            source = recruitOptions.forceBench and "recruit_bench" or "reward",
        })
        runState.lastActionMessage = string.format("%s 进阶至%s", existingUnit.name or "职业单位", getPromotionStageLabel(afterStage))
        return true, existingUnit
    end

    local heroRecord = createHeroRecord(runState, heroId)
    if not heroRecord then
        return false, "invalid_recruit"
    end
    heroRecord.ultimateChargesMax = heroRecord.ultimateChargesMax or 1
    heroRecord.ultimateCharges = heroRecord.ultimateCharges or heroRecord.ultimateChargesMax

    if recruitOptions.forceBench then
        heroRecord.teamState = "bench"
        runState.benchRoster[#runState.benchRoster + 1] = heroRecord
        runState.lastActionMessage = "新职业卡已加入候补"
        return true, heroRecord
    end

    if hasFreeActiveSlot(runState) then
        heroRecord.teamState = "active"
        runState.teamRoster[#runState.teamRoster + 1] = heroRecord
        runState.lastActionMessage = "新职业卡已直接加入上阵队伍"
    else
        heroRecord.teamState = "bench"
        runState.benchRoster[#runState.benchRoster + 1] = heroRecord
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
        if not unit or HeroData.NormalizePromotionStage(unit.promotionStage) ~= "high" then
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
                description = preview.resultType == "new_class_unit"
                    and ("获得新职业单位 · " .. getPromotionStageLabel(preview.promotionStageAfter))
                    or (getPromotionStageLabel(preview.promotionStageBefore) .. " → " .. getPromotionStageLabel(preview.promotionStageAfter)),
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
    for _, unit in ipairs(runState.teamRoster or {}) do
        local classId = tonumber(unit.classId) or 0
        if classId > 0 and HeroData.NormalizePromotionStage(unit.promotionStage) ~= "high" and not existingSeen[classId] then
            existingSeen[classId] = true
            existing[#existing + 1] = classId
        end
    end
    for _, unit in ipairs(runState.benchRoster or {}) do
        local classId = tonumber(unit.classId) or 0
        if classId > 0 and HeroData.NormalizePromotionStage(unit.promotionStage) ~= "high" and not existingSeen[classId] then
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
                or (getPromotionStageLabel(preview.promotionStageBefore) .. " → " .. getPromotionStageLabel(preview.promotionStageAfter)),
            featTags = { preview.resultType == "new_class_unit" and "new_class_unit" or "class_promotion" },
            resultType = preview.resultType,
            teamState = preview.teamState,
            promotionStageBefore = preview.promotionStageBefore,
            promotionStageAfter = preview.promotionStageAfter,
            summaryKey = preview.summaryKey,
            label = string.format("职业卡：%s", HeroData.GetClassName(classId)),
            description = preview.resultType == "new_class_unit"
                and ("获得新职业单位 · " .. getPromotionStageLabel(preview.promotionStageAfter))
                or (getPromotionStageLabel(preview.promotionStageBefore) .. " → " .. getPromotionStageLabel(preview.promotionStageAfter)),
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
            runState.teamRoster[#runState.teamRoster + 1] = created
        else
            runState.benchRoster[#runState.benchRoster + 1] = created
        end
        runState.lastActionMessage = string.format("%s 已加入队伍（%s）",
            created.name or "职业单位", getPromotionStageLabel(created.promotionStage))
        return true
    end

    local beforeStage = HeroData.NormalizePromotionStage(targetHero.promotionStage)
    if beforeStage == "high" then
        return false, "class_already_high"
    end
    local afterStage = HeroData.NormalizePromotionStage(option.promotionStageAfter or getNextPromotionStage(beforeStage))
    local oldMaxHp = tonumber(targetHero.maxHp) or 1
    local oldCurrentHp = tonumber(targetHero.currentHp) or 0
    local isDead = targetHero.isDead == true or oldCurrentHp <= 0 or targetHero.teamState == "dead"
    HeroData.RefreshClassUnit(targetHero, {
        promotionStage = afterStage,
        teamState = targetHero.teamState,
        currentHp = isDead and 0 or math.max(1, oldCurrentHp + ((tonumber(targetHero.maxHp) or oldMaxHp) - oldMaxHp)),
        isDead = isDead,
        source = "battle_reward",
    })

    BattleEvent.Publish("DebugCounterTiming", {
        stage = "roguelike_reward_class_card",
        source = "roguelike.roguelike_reward",
        data = {
            heroName = targetHero.name,
            heroId = targetHero.heroId,
            classId = targetHero.classId,
            promotionStageBefore = beforeStage,
            promotionStageAfter = afterStage,
            summaryKey = option.summaryKey,
        },
    })

    runState.lastActionMessage = string.format("%s 进阶：%s → %s",
        targetHero.name or "职业单位", getPromotionStageLabel(beforeStage), getPromotionStageLabel(afterStage))
    return true
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
