local JSON = require("utils.json")
local SkillConfig = require("config.skill_config")

local HeroData = {}

local heroInfoMap = {}
local heroesByClass = {}
local heroesByFaction = {}
local heroesByQuality = {}
local allHeroes = {}
local playableHeroes = {}
local initialized = false

local CLASS_NAMES = {
    [1] = "Front",
    [2] = "Mid",
    [3] = "Back",
}

local QUALITY_NAMES = {
    [1] = "Common",
    [2] = "Good",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legend",
    [6] = "Myth",
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
    return 1.0 + (star - 1) * 0.15
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
    return CLASS_NAMES[class] or "Unknown"
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

    local baseHp = hero.HpBaseNum or 1000
    local baseAtk = hero.AtkBaseNum or 100
    local baseDef = hero.DefBaseNum or 50
    local baseSpd = 100
    local quality = hero.BaseQuality or hero.Quality or 1
    local starMultiplier = GetStarMultiplier(star)

    local hpGrowthRate = 0.06 + quality * 0.008
    local atkGrowthRate = 0.05 + quality * 0.006
    local defGrowthRate = 0.04 + quality * 0.005
    local levelDiff = math.max(0, level - 1)

    local hpGrowth = math.floor(baseHp * hpGrowthRate * levelDiff)
    local atkGrowth = math.floor(baseAtk * atkGrowthRate * levelDiff)
    local defGrowth = math.floor(baseDef * defGrowthRate * levelDiff)

    local finalHp = math.floor((baseHp + hpGrowth) * starMultiplier)
    local finalAtk = math.floor((baseAtk + atkGrowth) * starMultiplier)
    local finalDef = math.floor((baseDef + defGrowth) * starMultiplier)
    local finalSpd = baseSpd + math.floor(level * 0.5)

    return {
        hp = finalHp,
        maxHp = finalHp,
        atk = finalAtk,
        def = finalDef,
        spd = finalSpd,
        speed = finalSpd,
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
        table.insert(leftHeroes, { id = heroes[i].AllyID, level = 50, star = 5, wpType = i })
    end
    for i = 4, 6 do
        table.insert(rightHeroes, { id = heroes[i].AllyID, level = 50, star = 5, wpType = i - 3 })
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
        print(string.format("ID: %d | Name: %s | Class: %s | Quality: %s",
            hero.AllyID,
            heroData.name,
            HeroData.GetClassName(hero.Class),
            HeroData.GetQualityName(hero.BaseQuality or hero.Quality or 1)))
    end
end

Init()

return HeroData
