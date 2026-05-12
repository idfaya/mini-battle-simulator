local JSON = require("utils.json")
local SkillConfig = require("config.skill_config")
local ClassRoleConfig = require("config.class_role_config")
local SkillRuntimeConfig = require("config.skill_runtime_config")
local ClassBuildProgression = require("config.class_build_progression")
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

---@class HeroRoleTemplate
---@field hp integer[]
---@field def integer[]
---@field speed integer[]
---@field ac integer[]
---@field hit integer[]
---@field spellDC integer[]
---@field saveFort integer[]
---@field saveRef integer[]
---@field saveWill integer[]
---@field critRate integer
---@field blockRate integer
---@field healBonus integer|nil

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

-- True 5e-style role templates.
-- Values are band anchors for T1..T4 (Lv1-4, 5-10, 11-16, 17-20).
-- We interpolate inside each band instead of reusing the legacy base+growth curve.
---@type table<integer|string, HeroRoleTemplate>
local HERO_ROLE_TEMPLATES = {
    [1] = { -- A1 追击流
        hp = { 42, 54, 66, 78, 90 },
        def = { 2, 3, 3, 4, 4 },
        speed = { 102, 103, 104, 105, 106 },
        ac = { 16, 17, 18, 19, 20 },
        hit = { 7, 8, 9, 10, 11 },
        spellDC = { 12, 12, 13, 13, 14 },
        saveFort = { 3, 4, 4, 5, 5 },
        saveRef = { 5, 6, 7, 8, 9 },
        saveWill = { 2, 3, 4, 5, 6 },
        critRate = 1000, blockRate = 500,
    },
    [2] = { -- Fighter 前线战士
        hp = { 64, 82, 100, 118, 136 },
        def = { 4, 5, 6, 7, 8 },
        speed = { 91, 92, 93, 94, 95 },
        ac = { 18, 19, 20, 21, 22 },
        hit = { 5, 6, 7, 8, 9 },
        spellDC = { 12, 13, 13, 14, 15 },
        saveFort = { 5, 6, 7, 8, 9 },
        saveRef = { 2, 3, 4, 5, 6 },
        saveWill = { 3, 4, 5, 6, 7 },
        critRate = 300, blockRate = 2000,
    },
    [3] = { -- S1 连击流
        hp = { 48, 60, 72, 84, 96 },
        def = { 2, 3, 3, 4, 4 },
        speed = { 105, 106, 107, 108, 109 },
        ac = { 17, 18, 19, 20, 21 },
        hit = { 7, 8, 9, 10, 11 },
        spellDC = { 12, 12, 13, 13, 14 },
        saveFort = { 3, 4, 5, 6, 7 },
        saveRef = { 5, 6, 7, 8, 9 },
        saveWill = { 2, 3, 4, 5, 6 },
        critRate = 800, blockRate = 500,
    },
    [4] = { -- B1 战意流
        hp = { 68, 88, 108, 126, 145 },
        def = { 3, 4, 5, 5, 6 },
        speed = { 94, 95, 96, 97, 98 },
        ac = { 16, 17, 18, 19, 20 },
        hit = { 5, 6, 7, 8, 9 },
        spellDC = { 12, 13, 13, 14, 15 },
        saveFort = { 4, 5, 6, 7, 8 },
        saveRef = { 2, 3, 4, 5, 6 },
        saveWill = { 3, 4, 5, 6, 7 },
        critRate = 500, blockRate = 1000,
    },
    [5] = { -- T1 毒爆流
        hp = { 50, 63, 76, 89, 102 },
        def = { 2, 3, 3, 4, 4 },
        speed = { 98, 99, 100, 101, 102 },
        ac = { 15, 16, 17, 18, 19 },
        hit = { 6, 7, 8, 9, 10 },
        spellDC = { 13, 14, 15, 16, 17 },
        saveFort = { 3, 4, 5, 6, 7 },
        saveRef = { 4, 5, 6, 7, 8 },
        saveWill = { 2, 3, 4, 5, 6 },
        critRate = 500, blockRate = 800,
    },
    [6] = { -- H1 圣光流
        hp = { 44, 56, 68, 80, 92 },
        def = { 2, 3, 3, 4, 4 },
        speed = { 98, 99, 100, 101, 102 },
        ac = { 14, 15, 16, 16, 17 },
        hit = { 3, 4, 5, 5, 6 },
        spellDC = { 14, 15, 16, 17, 18 },
        saveFort = { 2, 3, 4, 5, 6 },
        saveRef = { 2, 3, 4, 5, 6 },
        saveWill = { 5, 6, 7, 8, 9 },
        critRate = 300, blockRate = 500, healBonus = 800,
    },
    [7] = { -- M1 火法
        hp = { 38, 48, 58, 68, 78 },
        def = { 1, 2, 2, 3, 3 },
        speed = { 100, 101, 102, 103, 104 },
        ac = { 13, 13, 14, 15, 15 },
        hit = { 3, 3, 4, 4, 5 },
        spellDC = { 15, 16, 17, 18, 19 },
        saveFort = { 2, 3, 4, 5, 6 },
        saveRef = { 3, 4, 5, 6, 7 },
        saveWill = { 4, 5, 6, 7, 8 },
        critRate = 500, blockRate = 300,
    },
    [8] = { -- M2 冰法
        hp = { 42, 53, 64, 75, 86 },
        def = { 2, 2, 3, 3, 4 },
        speed = { 98, 99, 100, 101, 102 },
        ac = { 14, 14, 15, 15, 16 },
        hit = { 3, 3, 4, 4, 5 },
        spellDC = { 14, 15, 16, 17, 18 },
        saveFort = { 3, 4, 5, 6, 7 },
        saveRef = { 3, 4, 5, 6, 7 },
        saveWill = { 3, 4, 5, 6, 7 },
        critRate = 400, blockRate = 500,
    },
    [9] = { -- M3 雷法
        hp = { 39, 49, 59, 69, 80 },
        def = { 1, 2, 2, 3, 3 },
        speed = { 101, 102, 103, 104, 105 },
        ac = { 13, 13, 14, 15, 15 },
        hit = { 3, 3, 4, 4, 5 },
        spellDC = { 15, 16, 17, 18, 19 },
        saveFort = { 2, 3, 4, 5, 6 },
        saveRef = { 4, 5, 6, 7, 8 },
        saveWill = { 3, 4, 5, 6, 7 },
        critRate = 800, blockRate = 300,
    },
    [10] = { -- Barbarian 狂怒前线
        hp = { 72, 92, 112, 132, 152 },
        def = { 3, 4, 5, 6, 7 },
        speed = { 92, 93, 94, 95, 96 },
        ac = { 15, 16, 17, 18, 19 },
        hit = { 5, 6, 7, 8, 9 },
        spellDC = { 10, 10, 11, 11, 12 },
        saveFort = { 6, 7, 8, 9, 10 },
        saveRef = { 2, 3, 4, 5, 6 },
        saveWill = { 3, 4, 5, 6, 7 },
        critRate = 600, blockRate = 800,
    },
    default = {
        hp = { 50, 62, 74, 86, 98 },
        def = { 2, 3, 3, 4, 4 },
        speed = { 98, 99, 100, 101, 102 },
        ac = { 15, 16, 17, 18, 19 },
        hit = { 5, 6, 7, 8, 9 },
        spellDC = { 13, 14, 15, 16, 17 },
        saveFort = { 3, 4, 5, 6, 7 },
        saveRef = { 3, 4, 5, 6, 7 },
        saveWill = { 3, 4, 5, 6, 7 },
        critRate = 500, blockRate = 500,
    },
}

-- 5e ability scores per hero (STR/DEX/CON/INT/WIS/CHA).
-- These are used for true 5e HP (hit die + CON mod per level).
---@type table<integer, HeroAbilityScores>
local HERO_ABILITY_SCORES = {
    [900001] = { str = 10, dex = 20, con = 14, int = 8,  wis = 14, cha = 10 }, -- Monk
    [900002] = { str = 8,  dex = 14, con = 12, int = 16, wis = 10, cha = 10 }, -- Sorcerer
    [900003] = { str = 8,  dex = 14, con = 12, int = 16, wis = 10, cha = 10 }, -- Wizard
    [900004] = { str = 8,  dex = 14, con = 12, int = 16, wis = 10, cha = 10 }, -- Warlock
    [900005] = { str = 20, dex = 10, con = 16, int = 8,  wis = 12, cha = 10 }, -- Fighter
    [900006] = { str = 10, dex = 20, con = 14, int = 10, wis = 10, cha = 12 }, -- Rogue
    [900007] = { str = 10, dex = 12, con = 14, int = 10, wis = 16, cha = 10 }, -- Cleric
    [900008] = { str = 10, dex = 20, con = 13, int = 10, wis = 14, cha = 10 }, -- Ranger
    [900009] = { str = 20, dex = 10, con = 14, int = 8,  wis = 10, cha = 14 }, -- Paladin
    [900010] = { str = 20, dex = 12, con = 18, int = 8,  wis = 12, cha = 10 }, -- Barbarian
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
        if skillConfig.Type == 1 then
            resolvedType = E_SKILL_TYPE_NORMAL
        elseif skillConfig.Type == 2 then
            resolvedType = E_SKILL_TYPE_ACTIVE
        elseif skillConfig.Type == 3 then
            resolvedType = E_SKILL_TYPE_LIMITED
            resolvedCost = skillConfig.Cost or 100
        end
    end
    return resolvedType, resolvedCost
end

local function resolveSkillDisplayName(skillId, skillConfig)
    local runtimeEntry = SkillRuntimeConfig.Get(skillId)
    if runtimeEntry and runtimeEntry.name and runtimeEntry.name ~= "" then
        return runtimeEntry.name
    end
    if skillConfig and skillConfig.Name and skillConfig.Name ~= "" then
        return skillConfig.Name
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
    -- Fallback defaults by stream: melee favors STR/CON; casters favor INT/WIS.
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

local function OpenConfigFile(fileName)
    local paths = {
        "config/" .. fileName,
        "../config/" .. fileName,
    }

    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            return file
        end
    end

    return nil
end

local HERO_LEVEL_MAX = 20
local PROMOTION_STAGE_TO_LEVEL = {
    -- promotion_stage only provides the minimum combat level fallback.
    -- Real class_unit.level from Run exp growth must not be overwritten.
    low = 3,
    mid = 5,
    high = 7,
}
local PROMOTION_STAGE_ORDER = {
    low = 1,
    mid = 2,
    high = 3,
}
-- 5e-ish tier boundaries (inclusive start, exclusive end)
-- T1: 1-4, T2: 5-10, T3: 11-16, T4: 17-20
---@type integer[]
local HERO_TIER_STARTS = { 1, 5, 11, 17, HERO_LEVEL_MAX + 1 }

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

local function GetTier(level)
    local lv = tonumber(level) or 1
    lv = math.max(1, math.min(HERO_LEVEL_MAX, lv))
    if lv >= HERO_TIER_STARTS[4] then return 4 end
    if lv >= HERO_TIER_STARTS[3] then return 3 end
    if lv >= HERO_TIER_STARTS[2] then return 2 end
    return 1
end

local function GetRoleTemplate(classId)
    return HERO_ROLE_TEMPLATES[tonumber(classId) or 0] or HERO_ROLE_TEMPLATES.default
end

local function GetInterpolatedTemplateValue(series, level)
    if type(series) ~= "table" or #series == 0 then
        return 0
    end
    local lv = math.max(1, math.min(HERO_LEVEL_MAX, tonumber(level) or 1))
    -- We only use the first 4 anchors as T1..T4 even if the table has more values.
    local a1 = tonumber(series[1]) or 0
    local a2 = tonumber(series[2]) or a1
    local a3 = tonumber(series[3]) or a2
    local a4 = tonumber(series[4]) or a3

    local tier = GetTier(lv)
    if tier == 1 then
        local progress = (lv - HERO_TIER_STARTS[1]) / (HERO_TIER_STARTS[2] - HERO_TIER_STARTS[1])
        return a1 + (a2 - a1) * progress
    elseif tier == 2 then
        local progress = (lv - HERO_TIER_STARTS[2]) / (HERO_TIER_STARTS[3] - HERO_TIER_STARTS[2])
        return a2 + (a3 - a2) * progress
    elseif tier == 3 then
        local progress = (lv - HERO_TIER_STARTS[3]) / (HERO_TIER_STARTS[4] - HERO_TIER_STARTS[3])
        return a3 + (a4 - a3) * progress
    end
    return a4
end

local function GetTemplateStats(classId, level)
    local tpl = GetRoleTemplate(classId)
    return {
        hp = GetInterpolatedTemplateValue(tpl.hp, level),
        def = GetInterpolatedTemplateValue(tpl.def, level),
        speed = GetInterpolatedTemplateValue(tpl.speed, level),
        ac = GetInterpolatedTemplateValue(tpl.ac, level),
        hit = GetInterpolatedTemplateValue(tpl.hit, level),
        spellDC = GetInterpolatedTemplateValue(tpl.spellDC, level),
        saveFort = GetInterpolatedTemplateValue(tpl.saveFort, level),
        saveRef = GetInterpolatedTemplateValue(tpl.saveRef, level),
        saveWill = GetInterpolatedTemplateValue(tpl.saveWill, level),
        critRate = tpl.critRate or 0,
        blockRate = tpl.blockRate or 0,
        healBonus = tpl.healBonus or 0,
    }
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
    local file = OpenConfigFile("res_hero.json")
    if not file then
        print("[HeroData] Failed to open res_hero.json")
        return
    end

    local content = file:read("*a")
    file:close()

    local data = JSON.JsonDecode(content)
    if not data then
        print("[HeroData] Failed to parse res_hero.json")
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
    if not SkillConfig.GetSkillConfig(80001001) then
        SkillConfig.Init()
    end
end

local function ResolveSkillConfig(classId, skillLevel)
    EnsureSkillConfigReady()

    local levels = SkillConfig.GetSkillLevels(classId)
    if levels and #levels > 0 then
        for _, levelConfig in ipairs(levels) do
            if levelConfig.SkillLevel == skillLevel then
                return levelConfig, levelConfig.ID
            end
        end
    end

    local actualSkillId = classId * 10 + skillLevel
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
    local template = GetTemplateStats(hero.Class, level)

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
    local finalDef = math.max(0, math.floor(template.def))
    local finalSpd = math.max(60, math.floor(template.speed))
    local finalAc = math.max(10, calculateArmorClass(hero.Class, dexMod, conMod, wisMod, level))
    local finalHit = math.max(0, prof + getAttackAbilityMod(hero.Class, strMod, dexMod, intMod, wisMod))
    local finalSpellDC = math.max(8, 8 + prof + getSpellAbilityMod(hero.Class, intMod, wisMod, chaMod))
    local finalSaveFort = conMod + (isSaveProficient(hero.Class, "fort") and prof or 0)
    local finalSaveRef = dexMod + (isSaveProficient(hero.Class, "ref") and prof or 0)
    local finalSaveWill = wisMod + (isSaveProficient(hero.Class, "will") and prof or 0)

    return {
        hp = finalHp,
        maxHp = finalHp,
        atk = finalHit,
        def = finalDef,
        spd = finalSpd,
        speed = finalSpd,
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
        critRate = template.critRate or 0,
        blockRate = template.blockRate or 0,
        healBonus = template.healBonus or 0,
        ac = finalAc,
        hit = finalHit,
        spellDC = finalSpellDC,
        saveFort = finalSaveFort,
        saveRef = finalSaveRef,
        saveWill = finalSaveWill,
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
    if ClassBuildProgression.GetProgression(hero.Class) and not buildState then
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
                            classId = config.ClassID,
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
        def = attrs.def,
        hp = attrs.hp,
        maxHp = attrs.maxHp,
        spd = attrs.spd,
        speed = attrs.speed,
        ac = attrs.ac,
        hit = attrs.hit,
        spellDC = attrs.spellDC,
        saveFort = attrs.saveFort,
        saveRef = attrs.saveRef,
        saveWill = attrs.saveWill,
        critRate = attrs.critRate,
        blockRate = attrs.blockRate,
        healBonus = attrs.healBonus,
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
                    { key = 3, value = heroData.def },
                    { key = 4, value = heroData.speed or 100 },
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

local FeatConfig = require("config.feat_config")
local FeatBuildConfig = require("config.feat_build_config")
local ClassLevelGrants = require("config.class_level_grants")

local STAT_KEYS = {
    "maxHp", "atk", "def", "ac", "hit", "spellDC",
    "saveFort", "saveRef", "saveWill", "speed",
    "critRate", "blockRate", "healBonus",
}

local function addStat(target, key, delta)
    if not delta or delta == 0 then
        return
    end
    if key == "atk" then
        -- 5e single-source offense: fold legacy atk bonuses into hit.
        key = "hit"
    end
    target[key] = (target[key] or 0) + delta
end

---@param featIds integer[]|nil
---@return table<string, integer> featMods
---@return integer[] unlockSkills
---@return table<integer, integer> upgradeSkills
---@return table[] riskHooks
function HeroData.ApplyFeats(featIds)
    local mods = {}
    local unlockSkills = {}
    local upgradeSkills = {}
    local riskHooks = {}

    for _, featId in ipairs(featIds or {}) do
        local def = FeatConfig.GetFeat(featId)
        if def then
            for _, eff in ipairs(def.effects or {}) do
                if eff.type == "stat_add" then
                    for _, key in ipairs(STAT_KEYS) do
                        addStat(mods, key, tonumber(eff[key]))
                    end
                elseif eff.type == "stat_mult" then
                    -- 用千分比制与现有 critRate/blockRate 对齐（直接相加）。
                    for _, key in ipairs(STAT_KEYS) do
                        addStat(mods, key, tonumber(eff[key]))
                    end
                elseif eff.type == "unlock_skill" then
                    if eff.skillId then
                        unlockSkills[#unlockSkills + 1] = eff.skillId
                    end
                elseif eff.type == "upgrade_skill" then
                    if eff.skillId then
                        local lv = tonumber(eff.skillLevel) or 2
                        upgradeSkills[eff.skillId] = math.max(upgradeSkills[eff.skillId] or 0, lv)
                    end
                elseif eff.type == "passive" then
                    if eff.passiveId then
                        unlockSkills[#unlockSkills + 1] = eff.passiveId
                    end
                elseif eff.type == "risk_modifier" then
                    riskHooks[#riskHooks + 1] = {
                        featId = featId,
                        onBattleStart = eff.onBattleStart,
                        onTurnStart = eff.onTurnStart,
                        grant = eff.grant or {},
                    }
                    -- 代价型 feat 的"换取"部分直接进入 mods，使战斗期间稳定生效。
                    for key, val in pairs(eff.grant or {}) do
                        addStat(mods, key, tonumber(val))
                    end
                end
            end
        end
    end

    return mods, unlockSkills, upgradeSkills, riskHooks
end

---@param classId integer
---@param fromLevel integer  -- 不含
---@param toLevel integer    -- 含
---@return table<string, integer> grantMods
---@return integer[] unlockSkills
---@return table<integer, integer> upgradeSkills
function HeroData.CollectClassLevelGrants(classId, fromLevel, toLevel)
    local mods = {}
    local unlockSkills = {}
    local upgradeSkills = {}
    local grants = ClassLevelGrants.GetGrantsInRange(classId, (tonumber(fromLevel) or 0) + 1, toLevel)
    for _, entry in ipairs(grants) do
        for key, val in pairs(entry.statBonus or {}) do
            addStat(mods, key, tonumber(val))
        end
        for _, skillId in ipairs(entry.unlockSkills or {}) do
            unlockSkills[#unlockSkills + 1] = skillId
        end
        for skillId, lv in pairs(entry.upgradeSkills or {}) do
            upgradeSkills[skillId] = math.max(upgradeSkills[skillId] or 0, tonumber(lv) or 1)
        end
    end
    return mods, unlockSkills, upgradeSkills
end

---合并 feat 与 class grant 的 mods 到基底属性上，返回最终属性。
---@param baseAttrs table
---@param featMods table<string, integer>
---@param grantMods table<string, integer>
---@return table finalAttrs
function HeroData.MergeAttrMods(baseAttrs, featMods, grantMods)
    local final = {}
    for k, v in pairs(baseAttrs or {}) do
        final[k] = v
    end
    local sources = { featMods or {}, grantMods or {} }
    for _, src in ipairs(sources) do
        for _, key in ipairs(STAT_KEYS) do
            local delta = src[key]
            if delta and delta ~= 0 then
                if key == "maxHp" then
                    local oldMax = final.maxHp or 1
                    final.maxHp = math.max(1, oldMax + delta)
                    if final.maxHp < oldMax then
                        final.hp = math.max(1, math.min(final.maxHp, final.hp or final.maxHp))
                    else
                        final.hp = final.hp or final.maxHp
                    end
                else
                    final[key] = (final[key] or 0) + delta
                end
            end
        end
    end
    if final.hit ~= nil then
        final.atk = final.hit
    end
    return final
end

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
    local selected = {}
    if not ClassBuildProgression.GetProgression(classId) then
        return selected
    end
    local maxLevel = math.max(1, tonumber(level) or 1)
    for stageLevel = 1, maxLevel do
        local entry = ClassBuildProgression.GetLevelEntry(classId, stageLevel)
        if entry and entry.choiceGroup then
            local pool = sortFeatDefs(FeatBuildConfig.GetFeatsByLevel(classId, stageLevel, entry.choiceGroup) or {})
            if pool[1] and pool[1].id then
                selected[#selected + 1] = pool[1].id
            end
        end
    end
    return selected
end

local function collectCanonicalFeatSelections(classId, level)
    if ClassBuildProgression.GetProgression(classId) then
        return collectCanonicalBuildSelections(classId, level)
    end
    local selected = {}
    local maxLevel = math.max(1, tonumber(level) or 1)
    for stageLevel = 2, maxLevel do
        local pool = FeatConfig.GetEligibleFeats(classId, stageLevel, selected)
        if #pool > 0 then
            sortFeatDefs(pool)
            local picked = nil
            for _, feat in ipairs(pool) do
                if tonumber(feat.minLevel) == stageLevel then
                    picked = feat
                    break
                end
            end
            picked = picked or pool[1]
            if picked and picked.id then
                selected[#selected + 1] = picked.id
            end
        end
    end
    return selected
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
    local level = getPromotionStageLevel(promotionStage)
    return collectCanonicalFeatSelections(classId, level)
end

function HeroData.GetClassCardSummaryKey(classId, promotionStage)
    return string.format("class_%d_%s", tonumber(classId) or 0, normalizePromotionStage(promotionStage))
end

function HeroData.BuildClassUnitHeroData(classId, promotionStage, explicitLevel)
    Init()
    local resolvedClassId = tonumber(classId) or 0
    local heroId = HeroData.GetRepresentativeHeroId(resolvedClassId)
    if not heroId then
        return nil
    end

    local stage = normalizePromotionStage(promotionStage)
    local level = math.floor(tonumber(explicitLevel) or getPromotionStageLevel(stage))
    level = math.max(1, level)
    local abilityScores = buildPromotionAbilityScores(resolvedClassId, heroId, stage)
    local selectedFeatIds = collectCanonicalFeatSelections(resolvedClassId, level)

    if ClassBuildProgression.GetProgression(resolvedClassId) then
        local buildState = HeroBuild.TryCompileBuild(resolvedClassId, level, selectedFeatIds)
        local builtHero = HeroData.ConvertToHeroData(heroId, level, 1, {
            abilityScores = abilityScores,
            buildState = buildState,
            buildFeatIds = selectedFeatIds,
        })
        if builtHero then
            builtHero.selectedFeatIds = cloneArray(selectedFeatIds)
            builtHero.promotionStage = stage
        end
        return builtHero
    end

    local builtHero = HeroData.ConvertToHeroData(heroId, level, 1, {
        abilityScores = abilityScores,
    })
    if not builtHero then
        return nil
    end

    local grantMods, grantUnlockSkills, grantUpgradeSkills =
        HeroData.CollectClassLevelGrants(resolvedClassId, 0, level)
    local featMods, featUnlockSkills, featUpgradeSkills =
        HeroData.ApplyFeats(selectedFeatIds)
    local final = HeroData.MergeAttrMods(HeroData.CalculateHeroAttributes(heroId, level, 1, {
        abilityScores = abilityScores,
    }), featMods, grantMods)

    if final then
        builtHero.hp = final.hp or builtHero.hp
        builtHero.maxHp = final.maxHp or builtHero.maxHp
        builtHero.atk = final.hit or builtHero.atk
        builtHero.def = final.def or builtHero.def
        builtHero.ac = final.ac or builtHero.ac
        builtHero.hit = final.hit or builtHero.hit
        builtHero.spellDC = final.spellDC or builtHero.spellDC
        builtHero.saveFort = final.saveFort or builtHero.saveFort
        builtHero.saveRef = final.saveRef or builtHero.saveRef
        builtHero.saveWill = final.saveWill or builtHero.saveWill
        builtHero.speed = final.speed or builtHero.speed
        builtHero.spd = builtHero.speed
        builtHero.critRate = final.critRate or builtHero.critRate
        builtHero.blockRate = final.blockRate or builtHero.blockRate
        builtHero.healBonus = final.healBonus or builtHero.healBonus
    end

    local ownedSkills = {}
    local ownedSet = {}
    for _, sid in ipairs(grantUnlockSkills or {}) do
        if not ownedSet[sid] then
            ownedSet[sid] = true
            ownedSkills[#ownedSkills + 1] = sid
        end
    end
    for _, sid in ipairs(featUnlockSkills or {}) do
        if not ownedSet[sid] then
            ownedSet[sid] = true
            ownedSkills[#ownedSkills + 1] = sid
        end
    end
    local skillLevels = {}
    for sid, lv in pairs(grantUpgradeSkills or {}) do
        skillLevels[sid] = math.max(skillLevels[sid] or 0, tonumber(lv) or 1)
    end
    for sid, lv in pairs(featUpgradeSkills or {}) do
        skillLevels[sid] = math.max(skillLevels[sid] or 0, tonumber(lv) or 1)
    end

    builtHero = HeroData.ConvertToHeroData(heroId, level, 1, {
        abilityScores = abilityScores,
        ownedSkills = ownedSkills,
        skillLevels = skillLevels,
    }) or builtHero
    builtHero.selectedFeatIds = cloneArray(selectedFeatIds)
    builtHero.ownedSkills = cloneArray(ownedSkills)
    builtHero.skillLevels = cloneMap(skillLevels)
    builtHero.promotionStage = stage
    return builtHero
end

function HeroData.CreateClassUnit(classId, options)
    Init()
    local resolvedClassId = tonumber(classId) or 0
    local stage = options and options.promotionStage or "low"
    local level = tonumber(options and options.level) or getPromotionStageLevel(stage)
    local heroData = HeroData.BuildClassUnitHeroData(resolvedClassId, stage, level)
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
    local promotionPendingTarget = options and options.promotionPendingTarget or nil
    if promotionPendingTarget ~= nil then
        promotionPendingTarget = normalizePromotionStage(promotionPendingTarget)
        if promotionPendingTarget ~= "mid" and promotionPendingTarget ~= "high" then
            promotionPendingTarget = nil
        end
    end
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
        exp = tonumber(options and options.exp) or 0,
        star = 1,
        teamState = teamState,
        promotionStage = heroData.promotionStage or normalizePromotionStage(options and options.promotionStage or "low"),
        promotionPendingTarget = promotionPendingTarget,
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
        def = heroData.def,
        ac = heroData.ac,
        hit = heroData.hit,
        spellDC = heroData.spellDC,
        saveFort = heroData.saveFort,
        saveRef = heroData.saveRef,
        saveWill = heroData.saveWill,
        speed = heroData.speed,
        critRate = heroData.critRate,
        blockRate = heroData.blockRate,
        healBonus = heroData.healBonus,
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
    local exp = patch.exp
    if exp == nil then
        exp = classUnit.exp
    end
    local ultimateCharges = patch.ultimateCharges
    if ultimateCharges == nil then
        ultimateCharges = classUnit.ultimateCharges
    end
    local ultimateChargesMax = patch.ultimateChargesMax
    if ultimateChargesMax == nil then
        ultimateChargesMax = classUnit.ultimateChargesMax
    end
    local promotionPendingTarget = classUnit.promotionPendingTarget
    if patch.clearPromotionPendingTarget == true then
        promotionPendingTarget = nil
    elseif patch.promotionPendingTarget ~= nil then
        promotionPendingTarget = patch.promotionPendingTarget
    end
    local rebuilt = HeroData.CreateClassUnit(classUnit.classId, {
        rosterId = classUnit.rosterId,
        unitId = classUnit.unitId,
        promotionStage = patch.promotionStage or classUnit.promotionStage,
        level = patch.level or classUnit.level,
        teamState = patch.teamState or classUnit.teamState,
        currentHp = currentHp,
        isDead = patch.isDead,
        exp = exp,
        battleSlot = patch.battleSlot or classUnit.battleSlot,
        source = patch.source or classUnit.source,
        promotionPendingTarget = promotionPendingTarget,
        ultimateCharges = ultimateCharges,
        ultimateChargesMax = ultimateChargesMax,
        skillCooldowns = patch.skillCooldowns or classUnit.skillCooldowns,
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
    local heroData = HeroData.BuildClassUnitHeroData(classUnit.classId, classUnit.promotionStage, classUnit.level)
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
