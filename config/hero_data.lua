local ConfigJsonLoader = require("config.json_loader")
local SkillConfig = require("config.tables.skills")
local ClassRoleConfig = require("config.tables.classes")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local Ability5e = require("modules.ability_5e")

---@class HeroAbilityScores
---@field str integer
---@field dex integer
---@field con integer
---@field int integer
---@field wis integer
---@field cha integer

local HeroData = {}

local heroInfoMap = {}
local heroesByClass = {}
local heroesByFaction = {}
local heroesByQuality = {}
local representativeHeroIdByClass = {}
local allHeroes = {}
local playableHeroes = {}
local initialized = false

---@type table<integer, string>
local QUALITY_NAMES = {
    [1] = "Common",
    [2] = "Good",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legend",
    [6] = "Myth",
}

-- 5e ability scores per hero (STR/DEX/CON/INT/WIS/CHA).
-- These are used for true 5e HP (hit die + CON mod per level).
---@type table<integer, HeroAbilityScores>
-- Lv1 主属性按 5e 点购上限（主属性 16 / +3），随等级由 Build/Feat 抬升；勿在此写 18–20。
local HERO_ABILITY_SCORES = {
    [900001] = { str = 10, dex = 16, con = 14, int = 8,  wis = 14, cha = 10 }, -- Monk
    [900002] = { str = 8,  dex = 14, con = 12, int = 16, wis = 10, cha = 10 }, -- Sorcerer
    [900003] = { str = 8,  dex = 14, con = 12, int = 16, wis = 10, cha = 10 }, -- Wizard
    [900004] = { str = 8,  dex = 14, con = 12, int = 16, wis = 10, cha = 10 }, -- Warlock
    [900005] = { str = 16, dex = 12, con = 14, int = 8,  wis = 12, cha = 10 }, -- Fighter
    [900006] = { str = 10, dex = 16, con = 14, int = 10, wis = 10, cha = 12 }, -- Rogue
    [900007] = { str = 10, dex = 12, con = 14, int = 10, wis = 16, cha = 10 }, -- Cleric
    [900008] = { str = 10, dex = 16, con = 13, int = 10, wis = 14, cha = 10 }, -- Ranger
    [900009] = { str = 16, dex = 10, con = 14, int = 8,  wis = 10, cha = 14 }, -- Paladin
    [900010] = { str = 16, dex = 12, con = 16, int = 8,  wis = 12, cha = 10 }, -- Barbarian
}

local function clampAbility(score)
    return Ability5e.ClampAbility(score)
end

local function resolveSkillTypeFromConfigs(skillId, skillConfig)
    local runtimeEntry = SkillRuntimeConfig.Get(skillId)
    if runtimeEntry then
        local runtimeData = runtimeEntry.runtimeData or {}
        if runtimeData.skillType ~= nil then
            return runtimeData.skillType, runtimeData.skillCost or 0
        end
        if runtimeEntry.runtimeKind == "passive" then
            return E_SKILL_TYPE_PASSIVE, 0
        end
        if runtimeEntry.runtimeKind == "active" then
            return E_SKILL_TYPE_ACTIVE, 0
        end
    end

    local resolvedType = E_SKILL_TYPE_PASSIVE
    local resolvedCost = 0
    if skillConfig then
        if skillConfig.skillType == 1 then
            resolvedType = E_SKILL_TYPE_NORMAL
        elseif skillConfig.skillType == 2 then
            resolvedType = E_SKILL_TYPE_ACTIVE
        elseif skillConfig.skillType == 3 then
            resolvedType = E_SKILL_TYPE_LIMITED
            resolvedCost = skillConfig.skillCost or 100
        end
    end
    return resolvedType, resolvedCost
end

local function resolveSkillDisplayName(skillId, skillConfig)
    local runtimeEntry = SkillRuntimeConfig.Get(skillId)
    if runtimeEntry and runtimeEntry.name and runtimeEntry.name ~= "" then
        return runtimeEntry.name
    end
    if skillConfig and skillConfig.name and skillConfig.name ~= "" then
        return skillConfig.name
    end
    return "Skill_" .. tostring(skillId)
end

local function getAbilityMod(score)
    return Ability5e.GetAbilityMod(score)
end

local function getHeroAbilityScores(heroId, classId)
    local preset = HERO_ABILITY_SCORES[tonumber(heroId) or 0]
    if preset then
        return preset
    end
    -- Fallback：与 HERO_ABILITY_SCORES 同档（主属性 14–16）。
    local isMelee = ClassRoleConfig.IsMelee(classId)
    if isMelee then
        return { str = 14, dex = 12, con = 14, int = 10, wis = 10, cha = 10 }
    end
    return { str = 8, dex = 14, con = 12, int = 14, wis = 12, cha = 10 }
end

local function getClassHitDie(classId)
    return Ability5e.GetClassHitDie(classId)
end

local function getHitDieAvg(hitDie)
    return Ability5e.GetHitDieAvg(hitDie)
end

local function calculate5eHp(level, hitDie, conMod)
    return Ability5e.Calculate5eHp(level, hitDie, conMod)
end

local function getProficiencyBonus(level)
    return Ability5e.GetProficiencyBonus(level)
end

local function getAttackAbilityMod(classId, strMod, dexMod, intMod, wisMod)
    return Ability5e.GetAttackAbilityMod(classId, {
        str = strMod, dex = dexMod, int = intMod, wis = wisMod,
    })
end

local function getSpellAbilityMod(classId, intMod, wisMod, chaMod)
    return Ability5e.GetSpellAbilityMod(classId, {
        int = intMod, wis = wisMod, cha = chaMod,
    })
end

local function isSaveProficient(classId, saveType)
    return Ability5e.IsSaveProficient(classId, saveType)
end

local function calculateArmorClass(classId, dexMod, conMod, wisMod, level)
    return Ability5e.CalculateArmorClass(classId, {
        dex = dexMod, con = conMod, wis = wisMod,
    })
end

local HERO_LEVEL_MAX = 20
local PROMOTION_STAGE_TO_LEVEL = {
    -- promotion_stage provides the minimum combat level fallback only.
    -- Real class_unit.level from Run exp growth must not be overwritten.
    low = 3,
    mid = 5,
    high = 7,
}
local PROMOTION_STAGE_TO_BUILD_LEVEL = {
    -- Build unlocks follow stage, not combat level.
    low = 1,
    mid = 3,
    high = 5,
}
local PROMOTION_STAGE_ORDER = {
    low = 1,
    mid = 2,
    high = 3,
}
local function normalizePromotionStage(stage)
    local value = tostring(stage or "low")
    if value ~= "mid" and value ~= "high" then
        return "low"
    end
    return value
end

local function getPromotionStageLevel(stage)
    return PROMOTION_STAGE_TO_LEVEL[normalizePromotionStage(stage)] or 1
end

local function getPromotionStageBuildLevel(stage)
    return PROMOTION_STAGE_TO_BUILD_LEVEL[normalizePromotionStage(stage)] or 1
end

local function getCharacterGroup(classId)
    if ClassRoleConfig.IsMelee(classId) then
        return "physical"
    end
    return "caster"
end

local function cloneArray(list)
    local result = {}
    for i, value in ipairs(list or {}) do
        result[i] = value
    end
    return result
end

local function cloneMap(map)
    local result = {}
    for key, value in pairs(map or {}) do
        result[key] = value
    end
    return result
end

local function ParseSkillIDs(skillData)
    local skills = {}
    if type(skillData) ~= "table" then
        return skills
    end

    for _, skillItem in ipairs(skillData) do
        if skillItem and skillItem.array and #skillItem.array >= 2 then
            table.insert(skills, {
                classId = skillItem.array[1],
                level = skillItem.array[2],
            })
        end
    end

    return skills
end

local function LoadHeroInfo()
    local data, err = ConfigJsonLoader.Load("data/heroes.json", { expectedType = "table" })
    if not data then
        print("[HeroData] " .. tostring(err))
        return
    end

    for _, hero in ipairs(data) do
        hero.ParsedSkills = ParseSkillIDs(hero.SkillIDs)
        hero.ParsedInitSkills = ParseSkillIDs(hero.InitializeSkills)

        heroInfoMap[hero.AllyID] = hero
        table.insert(allHeroes, hero)

        if not heroesByClass[hero.Class] then
            heroesByClass[hero.Class] = {}
        end
        table.insert(heroesByClass[hero.Class], hero)

        if not heroesByFaction[hero.Faction] then
            heroesByFaction[hero.Faction] = {}
        end
        table.insert(heroesByFaction[hero.Faction], hero)

        local quality = hero.BaseQuality or hero.Quality or 1
        if not heroesByQuality[quality] then
            heroesByQuality[quality] = {}
        end
        table.insert(heroesByQuality[quality], hero)

        if hero.IsHero == 1 then
            table.insert(playableHeroes, hero)
            if not representativeHeroIdByClass[hero.Class] then
                representativeHeroIdByClass[hero.Class] = hero.AllyID
            end
        end
    end

    print(string.format("[HeroData] Loaded %d heroes", #data))
end

local function EnsureSkillConfigReady()
    if not SkillConfig.GetSkillConfig(80001011) then
        SkillConfig.Init()
    end
end

local function ResolveSkillConfig(classId, skillLevel)
    EnsureSkillConfigReady()

    local actualSkillId = (tonumber(classId) or 0) * 10 + (tonumber(skillLevel) or 0)
    return SkillConfig.GetSkillConfig(actualSkillId), actualSkillId
end

local function Init()
    if initialized then
        return
    end

    EnsureSkillConfigReady()
    LoadHeroInfo()
    initialized = true
end

function HeroData.Init()
    Init()
    return true
end

function HeroData.GetHeroInfo(heroId)
    Init()
    return heroInfoMap[heroId]
end

function HeroData.GetHero(heroId, level, star)
    return HeroData.ConvertToHeroData(heroId, level, star)
end

function HeroData.GetHeroName(heroId)
    Init()
    local hero = heroInfoMap[heroId]
    if hero then
        local className = ClassRoleConfig.GetName(hero.Class)
        if className and className ~= "" and className ~= "未知" then
            return className
        end
        return hero.Name or ("Hero_" .. tostring(heroId))
    end
    return "未知"
end

function HeroData.GetAllyName(heroId)
    return HeroData.GetHeroName(heroId)
end

function HeroData.GetAllHeroes()
    Init()
    return allHeroes
end

function HeroData.GetPlayableHeroes()
    Init()
    return playableHeroes
end

function HeroData.GetAllHeroIds()
    Init()
    local ids = {}
    for _, hero in ipairs(playableHeroes) do
        table.insert(ids, hero.AllyID)
    end
    return ids
end

function HeroData.GetHeroesByClass(class)
    Init()
    return heroesByClass[class] or {}
end

function HeroData.GetPlayableHeroesByClass(class)
    return HeroData.GetHeroesByClass(class)
end

function HeroData.GetHeroesByFaction(faction)
    Init()
    return heroesByFaction[faction] or {}
end

function HeroData.GetHeroesByQuality(quality)
    Init()
    return heroesByQuality[quality] or {}
end

function HeroData.GetPlayableHeroesByQuality(quality)
    return HeroData.GetHeroesByQuality(quality)
end

function HeroData.GetClassName(class)
    return ClassRoleConfig.GetName(class)
end

function HeroData.GetQualityName(quality)
    return QUALITY_NAMES[quality] or "Unknown"
end

function HeroData.CalculateHeroAttributes(heroId, level, star, override)
    Init()
    local hero = heroInfoMap[heroId]
    if not hero then
        return nil
    end

    local level = math.max(1, math.min(HERO_LEVEL_MAX, tonumber(level) or 1))
    local quality = hero.BaseQuality or hero.Quality or 1

    -- 5e growth: level drives progression; star no longer affects stats.
    local abilities = (override and override.abilityScores) or getHeroAbilityScores(heroId, hero.Class)
    local str = clampAbility(abilities.str)
    local dex = clampAbility(abilities.dex)
    local con = clampAbility(abilities.con)
    local intl = clampAbility(abilities.int)
    local wis = clampAbility(abilities.wis)
    local cha = clampAbility(abilities.cha)
    local strMod = getAbilityMod(str)
    local dexMod = getAbilityMod(dex)
    local conMod = getAbilityMod(con)
    local intMod = getAbilityMod(intl)
    local wisMod = getAbilityMod(wis)
    local chaMod = getAbilityMod(cha)
    local hitDie = getClassHitDie(hero.Class)
    local prof = getProficiencyBonus(level)
    local finalHp = calculate5eHp(level, hitDie, conMod)
    local finalAc = math.max(10, math.floor(calculateArmorClass(hero.Class, dexMod, conMod, wisMod, level)))
    local finalHit = math.max(0, prof + getAttackAbilityMod(hero.Class, strMod, dexMod, intMod, wisMod))
    local finalSpellAttack = math.max(0, prof + getSpellAbilityMod(hero.Class, intMod, wisMod, chaMod))
    local finalSpellDC = math.max(8, 8 + prof + getSpellAbilityMod(hero.Class, intMod, wisMod, chaMod))
    local finalSaveCon = conMod + (isSaveProficient(hero.Class, "con") and prof or 0)
    local finalSaveDex = dexMod + (isSaveProficient(hero.Class, "dex") and prof or 0)
    local finalSaveWis = wisMod + (isSaveProficient(hero.Class, "wis") and prof or 0)

    return {
        hp = finalHp,
        maxHp = finalHp,
        atk = finalHit,
        str = str,
        dex = dex,
        con = con,
        int = intl,
        wis = wis,
        cha = cha,
        strMod = strMod,
        dexMod = dexMod,
        conMod = conMod,
        intMod = intMod,
        wisMod = wisMod,
        chaMod = chaMod,
        hitDie = hitDie,
        proficiencyBonus = prof,
        ac = finalAc,
        hit = finalHit,
        spellAttack = finalSpellAttack,
        spellDC = finalSpellDC,
        saveCon = finalSaveCon,
        saveDex = finalSaveDex,
        saveWis = finalSaveWis,
        level = level,
        star = 1,
        quality = quality,
        class = hero.Class,
        faction = hero.Faction,
    }
end

---@class HeroSkillOverride
---@field ownedSkills integer[]|nil     -- 强制解锁的技能 ID（通常来自 feat / class grants）
---@field skillLevels table<integer, integer>|nil -- 可选：skillId(或ClassID) -> SkillLevel，用于生成/替换实际 skillId

function HeroData.ConvertToHeroData(heroId, level, star, override)
    Init()
    local hero = heroInfoMap[heroId]
    if not hero then
        return nil
    end

    local attrs = HeroData.CalculateHeroAttributes(heroId, level, star, override)
    if not attrs then
        return nil
    end

    local buildState = override and override.buildState or nil
    if ClassBuildProgression.HasClass(hero.Class) and not buildState then
        buildState = HeroBuild.TryCompileBuild(hero.Class, level, override and override.buildFeatIds or {})
    end

    if buildState and type(buildState.statMods) == "table" then
        for key, delta in pairs(buildState.statMods) do
            local numDelta = tonumber(delta) or 0
            if numDelta ~= 0 then
                local resolvedKey = (key == "atk") and "hit" or key
                if resolvedKey == "maxHp" then
                    attrs.maxHp = math.max(1, (attrs.maxHp or 1) + numDelta)
                    attrs.hp = math.max(1, math.min(attrs.maxHp, (attrs.hp or attrs.maxHp) + numDelta))
                else
                    attrs[resolvedKey] = (tonumber(attrs[resolvedKey]) or 0) + numDelta
                end
            end
        end
        attrs.atk = attrs.hit or attrs.atk
    end

    local skillsConfig = {}
    if buildState then
        skillsConfig = SkillRuntime.BuildSkillsConfig(buildState)
    end

    local forceUnlock = {}
    local overrideLevels = (override and override.skillLevels) or nil
    for _, sid in ipairs((override and override.ownedSkills) or {}) do
        forceUnlock[tonumber(sid) or 0] = true
    end

    -- Normalize "skillLevels" into force unlock of actual skill ids:
    -- 1) key = ClassID (ends with 0), value = SkillLevel => actual = ClassID*10 + SkillLevel
    -- 2) key = actual skill id (ends with 1..9): treat as force unlock of itself (ignore value)
    if type(overrideLevels) == "table" then
        for k, v in pairs(overrideLevels) do
            local key = tonumber(k) or 0
            local lv = tonumber(v) or 0
            if key > 0 then
                if (key % 10) == 0 and lv > 0 then
                    forceUnlock[key * 10 + lv] = true
                else
                    forceUnlock[key] = true
                end
            end
        end
    end

    if not buildState then
        local allowedSkillIds = {}
        if hero.ParsedSkills and #hero.ParsedSkills > 0 then
            for _, skillInfo in ipairs(hero.ParsedSkills) do
                local classId = skillInfo.classId
                local skillLevel = skillInfo.level or 1
                local skillConfig, actualSkillId = ResolveSkillConfig(classId, skillLevel)
                allowedSkillIds[actualSkillId] = true

                -- Skill unlock now follows level only (ignore UnlockStar in 5e growth mode).
                local canUnlock = true
                if skillConfig and skillConfig.UnlockLevel then
                    canUnlock = level >= (tonumber(skillConfig.UnlockLevel) or 1)
                end
                if forceUnlock[actualSkillId] then
                    canUnlock = true
                end

                local internalLevel = 1
                if type(overrideLevels) == "table" and overrideLevels[actualSkillId] then
                    internalLevel = math.max(1, tonumber(overrideLevels[actualSkillId]) or 1)
                end

                if skillConfig and canUnlock then
                    local skillType, skillCost = resolveSkillTypeFromConfigs(actualSkillId, skillConfig)

                    table.insert(skillsConfig, {
                        skillId = actualSkillId,
                        classId = classId,
                        skillType = skillType,
                        level = internalLevel,
                        name = resolveSkillDisplayName(actualSkillId, skillConfig),
                        skillCost = skillCost,
                    })
                elseif canUnlock then
                    table.insert(skillsConfig, {
                        skillId = actualSkillId,
                        classId = classId,
                        skillType = E_SKILL_TYPE_NORMAL,
                        level = internalLevel,
                        name = "Skill_" .. actualSkillId,
                        skillCost = 0,
                    })
                end
            end
        end

        -- Ensure forced skills that belong to the hero's 4-slot list are present even if normally locked.
        -- This keeps the skill list stable (no extra slots), but allows feats to unlock early.
        for skillId in pairs(forceUnlock) do
            if allowedSkillIds[skillId] then
                local already = false
                for _, entry in ipairs(skillsConfig) do
                    if entry.skillId == skillId then
                        already = true
                        break
                    end
                end
                if not already then
                    local config = SkillConfig.GetSkillConfig(skillId)
                    if config then
                        local skillType, skillCost = resolveSkillTypeFromConfigs(skillId, config)
                        local internalLevel = 1
                        if type(overrideLevels) == "table" and overrideLevels[skillId] then
                            internalLevel = math.max(1, tonumber(overrideLevels[skillId]) or 1)
                        end
                        table.insert(skillsConfig, {
                            skillId = skillId,
                            classId = config.classGroupId or 0,
                            skillType = skillType,
                            level = internalLevel,
                            name = resolveSkillDisplayName(skillId, config),
                            skillCost = skillCost,
                        })
                    end
                end
            end
        end
    end

    return {
        id = heroId,
        modelId = hero.ModelID,
        name = HeroData.GetHeroName(heroId),
        level = level,
        star = star,
        quality = attrs.quality,
        class = hero.Class,
        faction = hero.Faction,
        atk = attrs.hit,
        hp = attrs.hp,
        maxHp = attrs.maxHp,
        ac = attrs.ac,
        hit = attrs.hit,
        spellAttack = attrs.spellAttack,
        spellDC = attrs.spellDC,
        saveCon = attrs.saveCon,
        saveDex = attrs.saveDex,
        saveWis = attrs.saveWis,
        str = attrs.str,
        dex = attrs.dex,
        con = attrs.con,
        int = attrs.int,
        wis = attrs.wis,
        cha = attrs.cha,
        strMod = attrs.strMod,
        dexMod = attrs.dexMod,
        conMod = attrs.conMod,
        intMod = attrs.intMod,
        wisMod = attrs.wisMod,
        chaMod = attrs.chaMod,
        hitDie = attrs.hitDie,
        proficiencyBonus = attrs.proficiencyBonus,
        skillsConfig = skillsConfig,
        buildState = buildState,
        config = hero,
    }
end

function HeroData.CreateBattleConfig(leftHeroes, rightHeroes, maxRound, seedArray)
    local config = {
        max_round = maxRound or 30,
        random_num = seedArray or {123456789, 362436069, 521288629, 88675123},
        unit_status = {
            attack_units = {
                pcs = {},
                collections = {},
                energy_data = { point = 0, point_limit = 10, bar = 0, bar_limit = 3 },
            },
            defend_units = {
                pcs = {},
                collections = {},
                energy_data = { point = 0, point_limit = 10, bar = 0, bar_limit = 3 },
            },
        },
    }

    local function AppendHero(targetList, heroInfo, uniqueId)
        local heroData = HeroData.ConvertToHeroData(heroInfo.id, heroInfo.level, heroInfo.star)
        if not heroData then
            return
        end

        table.insert(targetList, {
            config_id = heroInfo.id,
            unique_id = uniqueId,
            level = heroInfo.level or 1,
            wp_type = heroInfo.wpType or 1,
            wc_type = heroData.class or 1,
            enable = true,
            cast_priority = 1,
            skills = {},
            passive_skills = {},
            attribute_map = {
                attr_array = {
                    { key = 1, value = heroData.maxHp },
                    { key = 2, value = heroData.hit },
                },
            },
        })
    end

    for _, heroInfo in ipairs(leftHeroes or {}) do
        AppendHero(config.unit_status.attack_units.pcs, heroInfo, heroInfo.id)
    end
    for _, heroInfo in ipairs(rightHeroes or {}) do
        AppendHero(config.unit_status.defend_units.pcs, heroInfo, heroInfo.id + 1000)
    end

    return config
end

function HeroData.CreateTestBattleConfig()
    local heroes = HeroData.GetPlayableHeroes()
    if #heroes < 6 then
        error("Not enough playable heroes (need at least 6)")
    end

    local leftHeroes = {}
    local rightHeroes = {}
    for i = 1, 3 do
        table.insert(leftHeroes, { id = heroes[i].AllyID, level = HERO_LEVEL_MAX, star = 5, wpType = i })
    end
    for i = 4, 6 do
        table.insert(rightHeroes, { id = heroes[i].AllyID, level = HERO_LEVEL_MAX, star = 5, wpType = i - 3 })
    end

    return HeroData.CreateBattleConfig(leftHeroes, rightHeroes, 30)
end

function HeroData.PrintHeroList()
    local heroes = HeroData.GetPlayableHeroes()
    print("=== Playable Heroes ===")
    print(string.format("Total: %d", #heroes))
    print("")

    for _, hero in ipairs(heroes) do
        local heroData = HeroData.ConvertToHeroData(hero.AllyID, 1, 1)
        print(string.format("ID: %d | Name: %s | Style: %s | Quality: %s",
            hero.AllyID,
            heroData.name,
            HeroData.GetClassName(hero.Class),
            HeroData.GetQualityName(hero.BaseQuality or hero.Quality or 1)))
    end
end

Init()

-- ==========================================================================
-- Feat / Class Level Grant 聚合接口
-- 升级流程：基底属性 = CalculateHeroAttributes（模板曲线）
--           叠加顺序 = ClassLevelGrants（固有解锁）→ Feats（玩家选择）
-- ApplyFeats 返回一个纯数据的 featMods 表，由 Roguelike 层调用 applyRosterLevel 时合并。
-- ==========================================================================

local FeatBuildConfig = require("config.tables.feats")

local function sortFeatDefs(list)
    table.sort(list, function(a, b)
        local aid = tonumber(a and a.id) or 0
        local bid = tonumber(b and b.id) or 0
        if aid ~= bid then
            return aid < bid
        end
        return tostring(a and a.name or "") < tostring(b and b.name or "")
    end)
    return list
end

local function collectCanonicalBuildSelections(classId, level)
    if not ClassBuildProgression.HasClass(classId) then
        return {}
    end
    local maxLevel = math.max(1, tonumber(level) or 1)
    -- §5 单轨：直接走 GetCanonicalFeatChain 的拓扑顺序，去掉 Lv1 fixed（lv1FeatIds 由 hero_build 自动注入）。
    local lv1Set = {}
    for _, fid in ipairs(ClassBuildProgression.GetLv1FeatIds(classId)) do
        lv1Set[tonumber(fid) or 0] = true
    end
    local selections = {}
    for _, fid in ipairs(ClassBuildProgression.GetCanonicalFeatChain(classId, maxLevel)) do
        if not lv1Set[tonumber(fid) or 0] then
            selections[#selections + 1] = fid
        end
    end
    return selections
end

local function collectCanonicalFeatSelections(classId, level)
    return collectCanonicalBuildSelections(classId, level)
end

local function resolveClassUnitBuildLevel(promotionStage, combatLevel)
    local stage = normalizePromotionStage(promotionStage)
    local resolvedCombatLevel = math.max(1, tonumber(combatLevel) or getPromotionStageLevel(stage))
    local stageBuildLevel = getPromotionStageBuildLevel(stage)
    return math.max(stageBuildLevel, resolvedCombatLevel)
end

local function resolveClassUnitBuildState(classId, buildLevel, selectedFeatIds)
    local resolvedClassId = tonumber(classId) or 0
    local resolvedLevel = math.max(1, tonumber(buildLevel) or 1)
    local featIds = cloneArray(selectedFeatIds or {})
    local buildState = HeroBuild.TryCompileBuild(resolvedClassId, resolvedLevel, featIds)
    if buildState then
        return buildState, featIds
    end

    local canonicalFeatIds = collectCanonicalFeatSelections(resolvedClassId, resolvedLevel)
    buildState = HeroBuild.TryCompileBuild(resolvedClassId, resolvedLevel, canonicalFeatIds)
    return buildState, canonicalFeatIds
end

local function buildPromotionAbilityScores(classId, heroId, promotionStage)
    local base = getHeroAbilityScores(heroId, classId)
    local result = {
        str = base.str,
        dex = base.dex,
        con = base.con,
        int = base.int,
        wis = base.wis,
        cha = base.cha,
    }
    local profile = Ability5e.GetClassProfile(classId)
    local stage = normalizePromotionStage(promotionStage)
    local function addAbility(key, delta)
        if not key or key == "none" or delta == 0 then
            return
        end
        result[key] = clampAbility((tonumber(result[key]) or 10) + delta)
    end

    if PROMOTION_STAGE_ORDER[stage] >= PROMOTION_STAGE_ORDER.mid then
        addAbility(profile and profile.primary_ability or nil, 1)
        addAbility("con", 1)
    end
    if PROMOTION_STAGE_ORDER[stage] >= PROMOTION_STAGE_ORDER.high then
        addAbility(profile and profile.primary_ability or nil, 2)
        addAbility(profile and profile.spell_ability or nil, 1)
        addAbility("con", 1)
    end
    return result
end

function HeroData.GetRepresentativeHeroId(classId)
    Init()
    return representativeHeroIdByClass[tonumber(classId) or 0]
end

function HeroData.GetAllClassIds()
    Init()
    local result = {}
    for classId in pairs(representativeHeroIdByClass) do
        result[#result + 1] = tonumber(classId) or 0
    end
    table.sort(result)
    return result
end

function HeroData.NormalizePromotionStage(stage)
    return normalizePromotionStage(stage)
end

function HeroData.GetPromotionStageLevel(stage)
    return getPromotionStageLevel(stage)
end

function HeroData.GetCharacterGroup(classId)
    return getCharacterGroup(classId)
end

function HeroData.GetCanonicalStageFeatIds(classId, promotionStage)
    local buildLevel = getPromotionStageBuildLevel(promotionStage)
    return collectCanonicalFeatSelections(classId, buildLevel)
end

function HeroData.GetClassCardSummaryKey(classId, promotionStage)
    return string.format("class_%d_%s", tonumber(classId) or 0, normalizePromotionStage(promotionStage))
end

function HeroData.BuildClassUnitHeroData(classId, promotionStage, explicitLevel, options)
    Init()
    local resolvedClassId = tonumber(classId) or 0
    local heroId = HeroData.GetRepresentativeHeroId(resolvedClassId)
    if not heroId then
        return nil
    end

    options = options or {}
    local stage = normalizePromotionStage(promotionStage)
    local combatLevel = math.floor(tonumber(explicitLevel) or getPromotionStageLevel(stage))
    combatLevel = math.max(1, combatLevel)
    local buildLevel = resolveClassUnitBuildLevel(stage, combatLevel)
    local abilityScores = buildPromotionAbilityScores(resolvedClassId, heroId, stage)
    local buildState, selectedFeatIds = resolveClassUnitBuildState(
        resolvedClassId,
        buildLevel,
        options.buildFeatIds
    )

    local builtHero = HeroData.ConvertToHeroData(heroId, combatLevel, 1, {
        abilityScores = abilityScores,
        buildState = buildState,
        buildFeatIds = selectedFeatIds,
    })
    if builtHero then
        builtHero.selectedFeatIds = cloneArray(selectedFeatIds)
        builtHero.promotionStage = stage
        builtHero.buildLevel = buildLevel
    end
    return builtHero
end

function HeroData.CreateClassUnit(classId, options)
    Init()
    local resolvedClassId = tonumber(classId) or 0
    local stage = options and options.promotionStage or "low"
    local level = tonumber(options and options.level) or getPromotionStageLevel(stage)
    local heroData = HeroData.BuildClassUnitHeroData(resolvedClassId, stage, level, {
        buildFeatIds = options and options.buildFeatIds,
    })
    if not heroData then
        return nil
    end

    local heroId = HeroData.GetRepresentativeHeroId(resolvedClassId)
    local heroInfo = heroId and HeroData.GetHeroInfo(heroId) or nil
    local currentHp = tonumber(options and options.currentHp)
    currentHp = currentHp or heroData.maxHp
    currentHp = math.max(0, math.min(heroData.maxHp or currentHp, currentHp))
    local teamState = tostring(options and options.teamState or "active")
    local isDead = (options and options.isDead) == true or currentHp <= 0 or teamState == "dead"
    if isDead then
        teamState = "dead"
        currentHp = 0
    end

    return {
        rosterId = options and options.rosterId or nil,
        unitId = options and options.unitId or nil,
        heroId = heroId,
        name = ClassRoleConfig.GetName(resolvedClassId),
        classId = resolvedClassId,
        className = ClassRoleConfig.GetName(resolvedClassId),
        characterGroup = getCharacterGroup(resolvedClassId),
        level = heroData.level,
        star = 1,
        teamState = teamState,
        promotionStage = heroData.promotionStage or normalizePromotionStage(options and options.promotionStage or "low"),
        battleSlot = options and options.battleSlot or "none",
        recommendedSlot = ClassRoleConfig.PreferFrontRow(resolvedClassId) and "front" or "back",
        skillPackageId = HeroData.GetClassCardSummaryKey(resolvedClassId, heroData.promotionStage or "low"),
        maxHp = heroData.maxHp,
        currentHp = currentHp,
        hp = currentHp,
        isDead = isDead,
        ultimateCharges = tonumber(options and options.ultimateCharges) or 1,
        ultimateChargesMax = tonumber(options and options.ultimateChargesMax) or 1,
        skillCooldowns = cloneMap(options and options.skillCooldowns or {}),
        source = options and options.source or "class_card",
        feats = cloneArray(heroData.selectedFeatIds),
        ownedSkills = cloneArray(heroData.ownedSkills),
        skillLevels = cloneMap(heroData.skillLevels),
        buildState = heroData.buildState,
        atk = heroData.hit,
        ac = heroData.ac,
        hit = heroData.hit,
        spellAttack = heroData.spellAttack,
        spellDC = heroData.spellDC,
        saveCon = heroData.saveCon,
        saveDex = heroData.saveDex,
        saveWis = heroData.saveWis,
        str = heroData.str,
        dex = heroData.dex,
        con = heroData.con,
        int = heroData.int,
        wis = heroData.wis,
        cha = heroData.cha,
        heroConfig = heroInfo,
    }
end

function HeroData.RefreshClassUnit(classUnit, updates)
    if type(classUnit) ~= "table" then
        return nil
    end
    local patch = updates or {}
    local currentHp = patch.currentHp
    if currentHp == nil then
        currentHp = classUnit.currentHp
    end
    local ultimateCharges = patch.ultimateCharges
    if ultimateCharges == nil then
        ultimateCharges = classUnit.ultimateCharges
    end
    local ultimateChargesMax = patch.ultimateChargesMax
    if ultimateChargesMax == nil then
        ultimateChargesMax = classUnit.ultimateChargesMax
    end
    local rebuilt = HeroData.CreateClassUnit(classUnit.classId, {
        rosterId = classUnit.rosterId,
        unitId = classUnit.unitId,
        promotionStage = patch.promotionStage or classUnit.promotionStage,
        level = patch.level or classUnit.level,
        teamState = patch.teamState or classUnit.teamState,
        currentHp = currentHp,
        isDead = patch.isDead,
        battleSlot = patch.battleSlot or classUnit.battleSlot,
        source = patch.source or classUnit.source,
        ultimateCharges = ultimateCharges,
        ultimateChargesMax = ultimateChargesMax,
        skillCooldowns = patch.skillCooldowns or classUnit.skillCooldowns,
        buildFeatIds = patch.buildFeatIds or classUnit.feats,
    })
    if not rebuilt then
        return nil
    end
    for key in pairs(classUnit) do
        classUnit[key] = nil
    end
    for key, value in pairs(rebuilt) do
        classUnit[key] = value
    end
    return classUnit
end

function HeroData.ConvertClassUnitToHeroData(classUnit)
    if type(classUnit) ~= "table" then
        return nil
    end
    local heroData = HeroData.BuildClassUnitHeroData(
        classUnit.classId,
        classUnit.promotionStage,
        classUnit.level,
        { buildFeatIds = classUnit.feats }
    )
    if not heroData then
        return nil
    end
    heroData.id = classUnit.heroId or heroData.id
    heroData.name = classUnit.name or heroData.name
    heroData.hp = math.max(0, math.min(heroData.maxHp or 1, tonumber(classUnit.currentHp) or heroData.maxHp or 1))
    heroData.ultimateChargesMax = tonumber(classUnit.ultimateChargesMax) or 1
    heroData.ultimateCharges = tonumber(classUnit.ultimateCharges)
    if heroData.ultimateCharges == nil then
        heroData.ultimateCharges = heroData.ultimateChargesMax
    end
    heroData.initialCooldowns = classUnit.skillCooldowns
    heroData.classUnit = classUnit
    return heroData
end

return HeroData
