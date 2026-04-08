local JSON = require("utils.json")
local SkillRglConfig = require("config.skill_rgl_config")
local RglHeroData = {}

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

local heroInfoMap = {}
local heroesByClass = {}
local heroesByFaction = {}
local heroesByQuality = {}
local allHeroes = {}
local playableHeroes = {}

local QUALITY_MULTIPLIERS = {
    [1] = 1.0,
    [2] = 1.1,
    [3] = 1.2,
    [4] = 1.35,
    [5] = 1.5,
    [6] = 1.7,
}

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
                level = skillItem.array[2]
            })
        end
    end
    return skills
end

local function LoadHeroInfo()
    local file = OpenConfigFile("res_rgl_hero.json")
    if not file then
        print("[RglHeroData] Failed to open res_rgl_hero.json")
        return
    end

    local content = file:read("*a")
    file:close()

    local data = JSON.JsonDecode(content)
    if not data then
        print("[RglHeroData] Failed to parse res_rgl_hero.json")
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

    print(string.format("[RglHeroData] Loaded %d RGL heroes", #data))
end

local function Init()
    LoadHeroInfo()
end

function RglHeroData.GetHeroInfo(heroId)
    return heroInfoMap[heroId]
end

function RglHeroData.GetAllHeroes()
    return allHeroes
end

function RglHeroData.GetPlayableHeroes()
    return playableHeroes
end

function RglHeroData.GetHeroesByClass(class)
    return heroesByClass[class] or {}
end

function RglHeroData.GetHeroesByFaction(faction)
    return heroesByFaction[faction] or {}
end

function RglHeroData.GetHeroesByQuality(quality)
    return heroesByQuality[quality] or {}
end

function RglHeroData.GetHeroName(heroId)
    local hero = heroInfoMap[heroId]
    if hero then
        return hero.Name or ("RglHero_" .. tostring(heroId))
    end
    return "Unknown"
end

function RglHeroData.CalculateHeroAttributes(heroId, level, star)
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
        faction = hero.Faction
    }
end

function RglHeroData.ConvertToHeroData(heroId, level, star)
    local hero = heroInfoMap[heroId]
    if not hero then
        return nil
    end

    local attrs = RglHeroData.CalculateHeroAttributes(heroId, level, star)
    if not attrs then
        return nil
    end

    local skillsConfig = {}
    if hero.ParsedSkills and #hero.ParsedSkills > 0 then
        for _, skillInfo in ipairs(hero.ParsedSkills) do
            local classId = skillInfo.classId
            local skillLevel = skillInfo.level or 1

            local rglSkill = nil
            local actualSkillId = classId * 100 + skillLevel

            local levels = SkillRglConfig.GetSkillLevels(classId)
            if levels and #levels > 0 then
                for _, lvlCfg in ipairs(levels) do
                    if lvlCfg.SkillLevel == skillLevel then
                        rglSkill = lvlCfg
                        actualSkillId = lvlCfg.ID or actualSkillId
                        break
                    end
                end
            end

            if not rglSkill then
                rglSkill = SkillRglConfig.GetSkillConfig(actualSkillId)
            end

            if rglSkill then
                local skillType = E_SKILL_TYPE_PASSIVE
                if rglSkill.Type == 1 then
                    skillType = E_SKILL_TYPE_NORMAL
                elseif rglSkill.Type == 2 then
                    skillType = E_SKILL_TYPE_ACTIVE
                elseif rglSkill.Type == 3 then
                    skillType = E_SKILL_TYPE_ULTIMATE
                end

                table.insert(skillsConfig, {
                    skillId = actualSkillId,
                    classId = classId,
                    skillType = skillType,
                    name = rglSkill.Name or ("RglSkill_" .. actualSkillId),
                    skillCost = rglSkill.Cost or 0
                })
            else
                table.insert(skillsConfig, {
                    skillId = actualSkillId,
                    classId = classId,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "RglSkill_" .. actualSkillId,
                    skillCost = 0
                })
            end
        end
    end

    local heroData = {
        id = heroId,
        modelId = hero.ModelID,
        name = RglHeroData.GetHeroName(heroId),
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
        isRgl = true
    }

    return heroData
end

Init()

return RglHeroData