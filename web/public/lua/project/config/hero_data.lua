local JSON = require("utils.json")
local SkillConfig = require("config.skill_config")
local ClassRoleConfig = require("config.class_role_config")

local HeroData = {}

local heroInfoMap = {}
local heroesByClass = {}
local heroesByFaction = {}
local heroesByQuality = {}
local allHeroes = {}
local playableHeroes = {}
local initialized = false

local QUALITY_NAMES = {
    [1] = "Common",
    [2] = "Good",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legend",
    [6] = "Myth",
}

-- True 5e-style role templates.
-- Values are band anchors for T1..T5 (Lv1-10, 11-20, 21-30, 31-40, 41-50).
-- We interpolate inside each band instead of reusing the legacy base+growth curve.
local HERO_ROLE_TEMPLATES = {
    [1] = { -- A1 追击流
        hp = { 42, 54, 66, 78, 90 },
        atk = { 8, 10, 11, 13, 15 },
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
    [2] = { -- D1 格挡流
        hp = { 64, 82, 100, 118, 136 },
        atk = { 7, 8, 9, 10, 11 },
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
        atk = { 8, 10, 11, 12, 14 },
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
        atk = { 7, 8, 10, 11, 12 },
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
        atk = { 8, 9, 10, 11, 12 },
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
        atk = { 5, 6, 7, 8, 9 },
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
        atk = { 5, 6, 7, 8, 9 },
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
        atk = { 5, 6, 7, 8, 9 },
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
        atk = { 5, 6, 7, 8, 9 },
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
    default = {
        hp = { 50, 62, 74, 86, 98 },
        atk = { 6, 7, 8, 9, 10 },
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

local function GetStarMultiplier(star)
    return 1.0 + math.max(0, (tonumber(star) or 1) - 1) * 0.04
end

local HERO_LEVEL_MAX = 20
-- 5e-ish tier boundaries (inclusive start, exclusive end)
-- T1: 1-4, T2: 5-10, T3: 11-16, T4: 17-20
local HERO_TIER_STARTS = { 1, 5, 11, 17, HERO_LEVEL_MAX + 1 }

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
        atk = GetInterpolatedTemplateValue(tpl.atk, level),
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
        return hero.Name or ("Hero_" .. tostring(heroId))
    end
    return "Unknown"
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

function HeroData.CalculateHeroAttributes(heroId, level, star)
    Init()
    local hero = heroInfoMap[heroId]
    if not hero then
        return nil
    end

    local level = math.max(1, math.min(HERO_LEVEL_MAX, tonumber(level) or 1))
    local quality = hero.BaseQuality or hero.Quality or 1
    local starMultiplier = GetStarMultiplier(star)
    local template = GetTemplateStats(hero.Class, level)

    local finalHp = math.max(1, math.floor(template.hp * starMultiplier))
    local finalAtk = math.max(1, math.floor(template.atk * starMultiplier))
    local finalDef = math.max(0, math.floor(template.def * starMultiplier))
    local finalSpd = math.max(60, math.floor(template.speed))

    return {
        hp = finalHp,
        maxHp = finalHp,
        atk = finalAtk,
        def = finalDef,
        spd = finalSpd,
        speed = finalSpd,
        critRate = template.critRate or 0,
        blockRate = template.blockRate or 0,
        healBonus = template.healBonus or 0,
        ac = math.max(10, math.floor(template.ac)),
        hit = math.max(0, math.floor(template.hit)),
        spellDC = math.max(10, math.floor(template.spellDC)),
        saveFort = math.max(0, math.floor(template.saveFort)),
        saveRef = math.max(0, math.floor(template.saveRef)),
        saveWill = math.max(0, math.floor(template.saveWill)),
        level = level,
        star = star,
        quality = quality,
        class = hero.Class,
        faction = hero.Faction,
    }
end

function HeroData.ConvertToHeroData(heroId, level, star)
    Init()
    local hero = heroInfoMap[heroId]
    if not hero then
        return nil
    end

    local attrs = HeroData.CalculateHeroAttributes(heroId, level, star)
    if not attrs then
        return nil
    end

    local skillsConfig = {}
    if hero.ParsedSkills and #hero.ParsedSkills > 0 then
        for _, skillInfo in ipairs(hero.ParsedSkills) do
            local classId = skillInfo.classId
            local skillLevel = skillInfo.level or 1
            local skillConfig, actualSkillId = ResolveSkillConfig(classId, skillLevel)

            if skillConfig then
                local skillType = E_SKILL_TYPE_PASSIVE
                if skillConfig.Type == 1 then
                    skillType = E_SKILL_TYPE_NORMAL
                elseif skillConfig.Type == 2 then
                    skillType = E_SKILL_TYPE_ACTIVE
                elseif skillConfig.Type == 3 then
                    skillType = E_SKILL_TYPE_ULTIMATE
                end

                table.insert(skillsConfig, {
                    skillId = actualSkillId,
                    classId = classId,
                    skillType = skillType,
                    name = skillConfig.Name or ("Skill_" .. actualSkillId),
                    skillCost = skillConfig.Cost or 0,
                })
            else
                table.insert(skillsConfig, {
                    skillId = actualSkillId,
                    classId = classId,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "Skill_" .. actualSkillId,
                    skillCost = 0,
                })
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
        atk = attrs.atk,
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
        skillsConfig = skillsConfig,
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
                    { key = 2, value = heroData.atk },
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

return HeroData
