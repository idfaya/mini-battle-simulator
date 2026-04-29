local RunRewardPool = require("config.roguelike.run_reward_pool")
local RunRelicConfig = require("config.roguelike.run_relic_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
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
    if entry.rewardType == "heal_pct" then
        return string.format("全队治疗 %.0f%%", (tonumber(entry.value) or 0) * 100)
    end
    if entry.rewardType == "relic" then
        local relic = RunRelicConfig.GetRelic(entry.refId)
        return relic and relic.name or ("Relic " .. tostring(entry.refId))
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
    if entry.rewardType == "relic" then
        local relic = RunRelicConfig.GetRelic(entry.refId)
        return relic and relic.code or ""
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

local function applyTeamHeal(runState, healPct)
    for _, hero in ipairs(runState.teamRoster or {}) do
        if not hero.isDead then
            local heal = math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0))
            hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
        end
    end
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
    if not entry or not entry.choiceGroup then
        return {}
    end
    local featPool = FeatBuildConfig.GetFeatsByLevel(hero.classId, nextLevel, entry.choiceGroup)
    local used = {}
    for _, featId in ipairs(hero.feats or {}) do
        used[tonumber(featId) or 0] = true
    end
    local result = {}
    for _, def in ipairs(featPool) do
        if not used[tonumber(def.id) or 0] then
            result[#result + 1] = def
        end
    end
    return result
end

local function createHeroRecord(runState, heroId)
    local recruitLevel = math.max(RECRUIT_LEVEL, tonumber(runState and runState.partyLevel) or RECRUIT_LEVEL)
    local attrs = HeroData.CalculateHeroAttributes(heroId, recruitLevel, RECRUIT_STAR)
    local heroInfo = HeroData.GetHeroInfo(heroId)
    if not attrs or not heroInfo then
        return nil
    end

    return {
        rosterId = allocateRosterId(runState),
        heroId = heroId,
        name = HeroData.GetHeroName(heroId),
        classId = heroInfo.Class or 0,
        level = attrs.level or recruitLevel,
        star = attrs.star or RECRUIT_STAR,
        maxHp = attrs.maxHp,
        currentHp = attrs.maxHp,
        isDead = false,
        feats = {},
        ownedSkills = {},
        skillLevels = {},
        source = "reward",
    }
end

function RoguelikeReward.AddRecruit(runState, heroId, options)
    local recruitOptions = options or {}
    local heroRecord = createHeroRecord(runState, heroId)
    if not heroRecord then
        return false, "invalid_recruit"
    end
    heroRecord.ultimateChargesMax = heroRecord.ultimateChargesMax or 1
    heroRecord.ultimateCharges = heroRecord.ultimateCharges or heroRecord.ultimateChargesMax

    if recruitOptions.forceBench then
        runState.benchRoster[#runState.benchRoster + 1] = heroRecord
        runState.lastActionMessage = "新招募已加入候补"
        return true, heroRecord
    end

    for index, rosterHero in ipairs(runState.teamRoster or {}) do
        if rosterHero.isDead or (tonumber(rosterHero.currentHp) or 0) <= 0 then
            runState.teamRoster[index] = heroRecord
            runState.lastActionMessage = "新招募已补入上阵空缺"
            return true, heroRecord
        end
    end

    if #(runState.teamRoster or {}) < (runState.maxHeroCount or 5) then
        runState.teamRoster[#runState.teamRoster + 1] = heroRecord
        runState.lastActionMessage = "新招募已直接加入上阵队伍"
    else
        runState.benchRoster[#runState.benchRoster + 1] = heroRecord
        runState.lastActionMessage = "新招募已加入候补"
    end

    return true, heroRecord
end

function RoguelikeReward.GenerateRecruitRewardState(runState, optionCount)
    local count = math.max(1, tonumber(optionCount) or 3)
    local pool = HeroData.GetAllHeroIds() or {}
    local candidates = {}
    for _, heroId in ipairs(pool) do
        if not containsHeroId(runState.teamRoster, heroId) and not containsHeroId(runState.benchRoster, heroId) then
            candidates[#candidates + 1] = heroId
        end
    end
    if #candidates < count then
        candidates = {}
        for _, heroId in ipairs(pool) do
            candidates[#candidates + 1] = heroId
        end
    end

    local options = {}
    local picked = {}
    while #options < count and #picked < #candidates do
        local idx = math.random(1, #candidates)
        local heroId = candidates[idx]
        if not picked[heroId] then
            picked[heroId] = true
            options[#options + 1] = {
                rewardType = "recruit",
                refId = heroId,
                label = "招募 " .. HeroData.GetHeroName(heroId),
                description = HeroData.GetClassName((HeroData.GetHeroInfo(heroId) or {}).Class or 0),
            }
        end
    end

    return {
        groupId = 0,
        kind = "battle_recruit",
        options = options,
    }
end

-- ==========================================================================
-- Level Up 3 选 1（一段式复合卡）
-- 每张卡 = { rosterId, heroName, nextLevel, featId, featName, featCode, featTags }
-- 约束：
--   1. 候选角色取存活且 level < levelCap 成员，落后者加权。
--   2. 3 张卡在 tag 上尽量互异，保证"攻/守/风险"视觉分化。
--   3. 每级池中必有至少 1 张 tag=risk 的代价型 feat（若候选池允许）。
-- ==========================================================================

local function pickEligibleHeroes(runState)
    local eligible = {}
    for _, hero in ipairs(runState.teamRoster or {}) do
        local level = tonumber(hero.level) or 1
        local cap = tonumber(runState.levelCap) or 20
        if not hero.isDead and (tonumber(hero.currentHp) or 0) > 0 and level < cap then
            eligible[#eligible + 1] = hero
        end
    end
    return eligible
end

local function pickHeroWithWeight(eligible)
    if #eligible == 0 then
        return nil
    end
    local minLevel = eligible[1].level or 1
    for _, hero in ipairs(eligible) do
        if (hero.level or 1) < minLevel then
            minLevel = hero.level or 1
        end
    end
    local total = 0
    local weights = {}
    for _, hero in ipairs(eligible) do
        local w = ((hero.level or 1) == minLevel) and 2 or 1
        weights[#weights + 1] = w
        total = total + w
    end
    local roll = math.random() * total
    local cursor = 0
    for index, hero in ipairs(eligible) do
        cursor = cursor + weights[index]
        if roll <= cursor then
            return hero
        end
    end
    return eligible[#eligible]
end

local function pickFeatForHero(hero, usedFeatIds, preferRisk, avoidTags)
    local featPool = getEligibleFeatPool(hero)
    if #featPool == 0 then
        return nil
    end

    local function hasTag(def, tag)
        for _, t in ipairs(def.tags or {}) do
            if t == tag then
                return true
            end
        end
        return false
    end

    local function hasAnyAvoided(def)
        for _, t in ipairs(def.tags or {}) do
            if avoidTags and avoidTags[t] then
                return true
            end
        end
        return false
    end

    -- 三轮筛选：首选 preferRisk 且未用过；次选不命中 avoidTags 的；兜底任意。
    local buckets = { {}, {}, {} }
    for _, def in ipairs(featPool) do
        if not usedFeatIds[def.id] then
            if preferRisk and hasTag(def, "risk") then
                buckets[1][#buckets[1] + 1] = def
            elseif not hasAnyAvoided(def) then
                buckets[2][#buckets[2] + 1] = def
            else
                buckets[3][#buckets[3] + 1] = def
            end
        end
    end

    for _, bucket in ipairs(buckets) do
        if #bucket > 0 then
            local total = 0
            for _, def in ipairs(bucket) do
                total = total + math.max(1, tonumber(def.weight) or 1)
            end
            local roll = math.random() * total
            local cursor = 0
            for _, def in ipairs(bucket) do
                cursor = cursor + math.max(1, tonumber(def.weight) or 1)
                if roll <= cursor then
                    return def
                end
            end
        end
    end
    return nil
end

local function buildLevelUpOption(hero, featDef)
    return {
        rewardType = "levelup",
        rosterId = hero.rosterId,
        heroName = hero.name,
        classId = hero.classId,
        nextLevel = (hero.level or 1) + 1,
        refId = featDef.id,
        featId = featDef.id,
        label = string.format("%s Lv.%d → Lv.%d：%s",
            hero.name or "?", hero.level or 1, (hero.level or 1) + 1, featDef.name or "?"),
        description = featDef.code or featDef.description or "",
        featName = featDef.name,
        featCode = featDef.code or featDef.description or "",
        featTags = featDef.tags or {},
    }
end

function RoguelikeReward.GenerateLevelUpRewardState(runState)
    local eligible = pickEligibleHeroes(runState)
    if #eligible == 0 then
        return nil
    end

    local options = {}
    local usedFeatIds = {}
    local avoidTags = {}

    for cardIndex = 1, 3 do
        local hero = pickHeroWithWeight(eligible) or eligible[1]
        local featDef = pickFeatForHero(hero, usedFeatIds, false, avoidTags)
        if not featDef then
            -- 该角色无可用 feat，尝试其他角色。
            for _, alt in ipairs(eligible) do
                if alt.rosterId ~= hero.rosterId then
                    featDef = pickFeatForHero(alt, usedFeatIds, false, avoidTags)
                    if featDef then
                        hero = alt
                        break
                    end
                end
            end
        end
        if not featDef then
            break
        end

        usedFeatIds[featDef.id] = true
        for _, tag in ipairs(featDef.tags or {}) do
            avoidTags[tag] = true
        end
        options[#options + 1] = buildLevelUpOption(hero, featDef)
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

-- 升级单个成员并应用 feat（由 Run 层在 ChooseReward 调用）。
function RoguelikeReward.ApplyLevelUpReward(runState, option)
    if not option or option.rewardType ~= "levelup" then
        return false, "invalid_levelup"
    end

    local targetHero = nil
    for _, hero in ipairs(runState.teamRoster or {}) do
        if tonumber(hero.rosterId) == tonumber(option.rosterId) then
            targetHero = hero
            break
        end
    end
    if not targetHero then
        return false, "hero_not_found"
    end
    if targetHero.isDead then
        return false, "hero_dead"
    end

    local featDef = isFighterBuildHero(targetHero) and FeatBuildConfig.GetFeat(option.featId) or FeatConfig.GetFeat(option.featId)
    if not featDef then
        return false, "feat_not_found"
    end

    local newLevel = math.min(tonumber(runState.levelCap) or 20, (targetHero.level or 1) + 1)
    local oldLevel = targetHero.level or 1

    targetHero.feats = targetHero.feats or {}
    targetHero.feats[#targetHero.feats + 1] = featDef.id
    targetHero.level = newLevel

    if isFighterBuildHero(targetHero) then
        local buildState = HeroBuild.CompileBuild(targetHero.classId, newLevel, targetHero.feats)
        local builtHero = HeroData.ConvertToHeroData(targetHero.heroId, newLevel, 1, {
            buildState = buildState,
            buildFeatIds = targetHero.feats,
        })
        if builtHero then
            local oldMaxHp = tonumber(targetHero.maxHp) or 1
            local oldCurrentHp = tonumber(targetHero.currentHp) or 0
            targetHero.maxHp = builtHero.maxHp or oldMaxHp
            local deltaHp = targetHero.maxHp - oldMaxHp
            targetHero.currentHp = math.max(1, math.min(targetHero.maxHp, oldCurrentHp + deltaHp))
            targetHero.atk = builtHero.atk
            targetHero.def = builtHero.def
            targetHero.ac = builtHero.ac
            targetHero.hit = builtHero.hit
            targetHero.spellDC = builtHero.spellDC
            targetHero.saveFort = builtHero.saveFort
            targetHero.saveRef = builtHero.saveRef
            targetHero.saveWill = builtHero.saveWill
            targetHero.speed = builtHero.speed
            targetHero.critRate = builtHero.critRate
            targetHero.blockRate = builtHero.blockRate
            targetHero.healBonus = builtHero.healBonus
            targetHero.featMods = buildState.statMods or {}
            targetHero.buildState = buildState
            targetHero.ownedSkills = {}
            targetHero.skillLevels = {}
            for _, skillCfg in ipairs(builtHero.skillsConfig or {}) do
                targetHero.ownedSkills[#targetHero.ownedSkills + 1] = skillCfg.skillId
                targetHero.skillLevels[skillCfg.skillId] = tonumber(skillCfg.level) or 1
            end
            -- #region debug-point A:roguelike-reward-fighter-build
            BattleEvent.Publish("DebugCounterTiming", {
                stage = "roguelike_reward_fighter_build",
                source = "roguelike.roguelike_reward",
                data = {
                    heroName = targetHero.name,
                    heroId = targetHero.heroId,
                    level = targetHero.level,
                    featId = featDef.id,
                    featName = featDef.name,
                    feats = targetHero.feats,
                    passiveSkills = buildState.passiveSkills,
                    activeSkills = buildState.activeSkills,
                },
            })
            -- #endregion
        end

        runState.lastActionMessage = string.format("%s 升至 Lv.%d，获得「%s」",
            targetHero.name or "?", targetHero.level or oldLevel, featDef.name or "?")
        return true
    end

    -- 重建属性：基底 + class grant(仅本次升级新增的等级段) + 全部 feats。
    local baseAttrs = HeroData.CalculateHeroAttributes(targetHero.heroId, newLevel, 1)
    if baseAttrs then
        local grantMods, grantUnlockSkills, grantUpgradeSkills =
            HeroData.CollectClassLevelGrants(targetHero.classId, oldLevel, newLevel)
        local featMods, featUnlockSkills, featUpgradeSkills, riskHooks =
            HeroData.ApplyFeats(targetHero.feats)
        local final = HeroData.MergeAttrMods(baseAttrs, featMods, grantMods)

        local oldMaxHp = tonumber(targetHero.maxHp) or 1
        local oldCurrentHp = tonumber(targetHero.currentHp) or 0
        targetHero.maxHp = final.maxHp or oldMaxHp
        local deltaHp = targetHero.maxHp - oldMaxHp
        targetHero.currentHp = math.max(1, math.min(targetHero.maxHp, oldCurrentHp + deltaHp))
        targetHero.atk = final.atk
        targetHero.def = final.def
        targetHero.ac = final.ac
        targetHero.hit = final.hit
        targetHero.spellDC = final.spellDC
        targetHero.saveFort = final.saveFort
        targetHero.saveRef = final.saveRef
        targetHero.saveWill = final.saveWill
        targetHero.speed = final.speed
        targetHero.critRate = final.critRate
        targetHero.blockRate = final.blockRate
        targetHero.healBonus = final.healBonus
        targetHero.featMods = featMods
        targetHero.riskHooks = riskHooks

        -- 合并技能解锁/升级。
        targetHero.ownedSkills = targetHero.ownedSkills or {}
        local ownedSet = {}
        for _, sid in ipairs(targetHero.ownedSkills) do
            ownedSet[sid] = true
        end
        for _, sid in ipairs(grantUnlockSkills) do
            if not ownedSet[sid] then
                targetHero.ownedSkills[#targetHero.ownedSkills + 1] = sid
                ownedSet[sid] = true
            end
        end
        for _, sid in ipairs(featUnlockSkills) do
            if not ownedSet[sid] then
                targetHero.ownedSkills[#targetHero.ownedSkills + 1] = sid
                ownedSet[sid] = true
            end
        end
        targetHero.skillLevels = targetHero.skillLevels or {}
        for sid, lv in pairs(grantUpgradeSkills) do
            targetHero.skillLevels[sid] = math.max(targetHero.skillLevels[sid] or 0, lv)
        end
        for sid, lv in pairs(featUpgradeSkills) do
            targetHero.skillLevels[sid] = math.max(targetHero.skillLevels[sid] or 0, lv)
        end
    end

    runState.lastActionMessage = string.format("%s 升至 Lv.%d，获得「%s」",
        targetHero.name or "?", targetHero.level or oldLevel, featDef.name or "?")
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
    elseif option.rewardType == "heal_pct" then
        applyTeamHeal(runState, option.value)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "relic" then
        addUnique(runState.relicIds, option.refId)
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
