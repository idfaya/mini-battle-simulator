local JSON = require("utils.json")
local SkillConfig = require("config.skill_config")

local EnemyData = {}

local enemyData = {}
local isLoaded = false
local skillConfigInited = false

local CLASS_NAMES = {
    [1] = "流派1",
    [2] = "流派2",
    [3] = "流派3",
}

local MONSTER_TYPE_NAMES = {
    [0] = "Normal",
    [1] = "Elite",
    [2] = "BOSS",
}

local STAR_MULTIPLIERS = {
    [1] = 1.0,
    [2] = 1.1,
    [3] = 1.2,
    [4] = 1.3,
    [5] = 1.5,
    [6] = 1.8,
    [7] = 2.2,
}

local function GetConfigFilePath(fileName)
    local paths = {
        "config/" .. fileName,
        "../config/" .. fileName,
    }

    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            return path
        end
    end

    return nil
end

local function GetSkillFamily(skillId)
    if not skillId then
        return nil
    end
    return math.floor(skillId / 10)
end

local function BuildScaledSkillIds(enemy, level)
    local result = {}
    local seen = {}

    local function Add(skillId)
        if not skillId or seen[skillId] then
            return
        end
        seen[skillId] = true
        table.insert(result, skillId)
    end

    local baseSkillIds = {}
    if enemy.SkillIDs then
        for _, skillId in ipairs(enemy.SkillIDs) do
            table.insert(baseSkillIds, skillId)
        end
    end
    if enemy.SkillIDsBossWarning then
        for _, skillId in ipairs(enemy.SkillIDsBossWarning) do
            table.insert(baseSkillIds, skillId)
        end
    end

    for _, skillId in ipairs(baseSkillIds) do
        Add(skillId)
    end

    local families = {}
    for _, skillId in ipairs(baseSkillIds) do
        local family = GetSkillFamily(skillId)
        if family then
            families[family] = true
        end
    end

    for family, _ in pairs(families) do
        Add(family * 10 + 1)
        if level >= 12 or (enemy.MonsterType or 0) >= 1 then
            Add(family * 10 + 2)
        end
        if level >= 24 or (enemy.MonsterType or 0) >= 1 then
            Add(family * 10 + 3)
        end
        if level >= 36 or (enemy.MonsterType or 0) >= 2 then
            Add(family * 10 + 4)
        end
    end

    return result
end

local function GetStarMultiplier(star)
    return STAR_MULTIPLIERS[star] or 1.0
end

local function loadJsonFile(filename)
    local file = io.open(filename, "r")
    if not file then
        print(string.format("[EnemyData] Cannot open: %s", filename))
        return nil
    end

    local content = file:read("*all")
    file:close()

    local success, result = pcall(JSON.JsonDecode, content)
    if not success then
        print(string.format("[EnemyData] JSON parse failed: %s", filename))
        return nil
    end

    return result
end

local function EnemyHasSkills(enemy)
    if not enemy then
        return false
    end
    if enemy.SkillIDs and #enemy.SkillIDs > 0 then
        return true
    end
    if enemy.SkillIDsBossWarning and #enemy.SkillIDsBossWarning > 0 then
        return true
    end
    return false
end

function EnemyData.Init()
    if isLoaded then
        return true
    end

    local enemyPath = GetConfigFilePath("res_enemy.json")
    local enemyArray = enemyPath and loadJsonFile(enemyPath) or nil
    if not enemyArray then
        print("[EnemyData] Failed to load res_enemy.json")
        return false
    end

    for _, enemy in ipairs(enemyArray) do
        if enemy.ID then
            enemyData[enemy.ID] = enemy
        end
    end

    print(string.format("[EnemyData] Loaded %d enemies", #enemyArray))
    isLoaded = true
    return true
end

function EnemyData.GetEnemy(enemyId)
    EnemyData.Init()
    return enemyData[enemyId]
end

function EnemyData.GetEnemyInfo(enemyId)
    return EnemyData.GetEnemy(enemyId)
end

function EnemyData.GetAllEnemies()
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(enemyData) do
        if type(id) == "number" then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetAllEnemyIds()
    EnemyData.Init()
    local ids = {}
    for id, _ in pairs(enemyData) do
        if type(id) == "number" then
            table.insert(ids, id)
        end
    end
    return ids
end

function EnemyData.GetEnemiesByLevel(level)
    local result = {}
    for _, enemy in ipairs(EnemyData.GetAllEnemies()) do
        if enemy.Level == level then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetEnemiesByClass(class)
    local result = {}
    for _, enemy in ipairs(EnemyData.GetAllEnemies()) do
        if enemy.Class == class then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetClassName(class)
    return CLASS_NAMES[class] or "Unknown"
end

function EnemyData.GetMonsterTypeName(monsterType)
    return MONSTER_TYPE_NAMES[monsterType] or "Unknown"
end

function EnemyData.ConvertToHeroData(enemyId, overrideLevel)
    if not skillConfigInited then
        SkillConfig.Init()
        skillConfigInited = true
    end

    local enemy = EnemyData.GetEnemy(enemyId)
    if not enemy then
        print(string.format("[EnemyData] Enemy not found: %s", tostring(enemyId)))
        return nil
    end

    local name = enemy.EnemyName or string.format("Enemy_%d", enemyId)
    local level = overrideLevel or enemy.Level or 1
    local star = enemy.Star or 1
    local quality = enemy.Quality or 1
    local monsterType = enemy.MonsterType or 0
    local class = enemy.Class or 2

    local baseHp, baseAtk, baseDef, baseSpeed
    if class == 1 then
        baseHp, baseAtk, baseDef, baseSpeed = 1200, 105, 78, 88
    elseif class == 2 then
        baseHp, baseAtk, baseDef, baseSpeed = 980, 138, 55, 104
    else
        baseHp, baseAtk, baseDef, baseSpeed = 920, 152, 48, 108
    end

    local hpGrowthRate = 0.12 + quality * 0.015
    local atkGrowthRate = 0.095 + quality * 0.012
    local defGrowthRate = 0.075 + quality * 0.010
    local levelDiff = math.max(0, level - 1)

    local hpGrowth = math.floor(baseHp * hpGrowthRate * levelDiff)
    local atkGrowth = math.floor(baseAtk * atkGrowthRate * levelDiff)
    local defGrowth = math.floor(baseDef * defGrowthRate * levelDiff)

    local qualityMultipliers = {1.0, 1.06, 1.12, 1.18, 1.26, 1.34}
    local qualityMultiplier = qualityMultipliers[quality] or 1.0
    local typeMultipliers = {[0] = 1.0, [1] = 1.15, [2] = 1.35}
    local typeMultiplier = typeMultipliers[monsterType] or 1.0
    local starMultiplier = GetStarMultiplier(star)
    local totalMultiplier = qualityMultiplier * typeMultiplier * starMultiplier
    local atkMultiplier = 1.0 + (totalMultiplier - 1.0) * 0.45

    local heroData = {
        id = enemyId,
        name = name,
        hp = math.floor((baseHp + hpGrowth) * totalMultiplier),
        atk = math.floor((baseAtk + atkGrowth) * atkMultiplier),
        def = math.floor((baseDef + defGrowth) * totalMultiplier),
        speed = baseSpeed,
        critRate = 0.05 + (quality * 0.01),
        critDmg = 1.3 + (star * 0.05),
        skills = {},
        class = class,
        _originalEnemy = enemy,
        _class = class,
        _className = EnemyData.GetClassName(class),
        _monsterType = monsterType,
        _monsterTypeName = EnemyData.GetMonsterTypeName(monsterType),
        _level = level,
        _star = star,
        _quality = quality,
    }

    local skillList = {}
    local skillsConfig = {}
    local processedSkillIds = {}

    local function AddSkill(skillId)
        if not skillId or processedSkillIds[skillId] then
            return
        end

        processedSkillIds[skillId] = true
        table.insert(skillList, skillId)

        local skillType = E_SKILL_TYPE_PASSIVE
        local skillCost = 0
        local skillConfig = SkillConfig.GetSkillConfig(skillId)

        if skillConfig then
            if skillConfig.Type == 1 then
                skillType = E_SKILL_TYPE_NORMAL
            elseif skillConfig.Type == 2 then
                skillType = E_SKILL_TYPE_ACTIVE
            elseif skillConfig.Type == 3 then
                skillType = E_SKILL_TYPE_ULTIMATE
                skillCost = skillConfig.Cost or 100
            elseif skillConfig.Type == 4 then
                skillType = E_SKILL_TYPE_PASSIVE
            end
        elseif skillId >= 800010000 and skillId < 800013000 then
            local lastDigit = (math.floor(skillId / 100)) % 10
            if lastDigit == 1 or lastDigit == 2 then
                skillType = E_SKILL_TYPE_NORMAL
            elseif lastDigit >= 3 then
                skillType = E_SKILL_TYPE_ULTIMATE
                skillCost = 100
            end
        end

        table.insert(skillsConfig, {
            skillId = skillId,
            skillType = skillType,
            name = "Skill_" .. skillId,
            skillCost = skillCost,
        })
    end

    for _, skillId in ipairs(BuildScaledSkillIds(enemy, level)) do
        AddSkill(skillId)
    end

    heroData.skills = {}
    for _, skillId in ipairs(skillList) do
        table.insert(heroData.skills, { skillId = skillId, level = 1 })
    end
    heroData.skillsConfig = skillsConfig

    return heroData
end

function EnemyData.ConvertEnemiesToHeroData(enemyIds)
    local result = {}
    for _, enemyId in ipairs(enemyIds) do
        local heroData = EnemyData.ConvertToHeroData(enemyId)
        if heroData then
            table.insert(result, heroData)
        end
    end
    return result
end

function EnemyData.GetHeroesByLevelRange(minLevel, maxLevel, count)
    local result = {}
    for _, enemy in ipairs(EnemyData.GetAllEnemies()) do
        local level = enemy.Level or 1
        if level >= minLevel and level <= maxLevel then
            table.insert(result, EnemyData.ConvertToHeroData(enemy.ID))
            if count and #result >= count then
                break
            end
        end
    end
    return result
end

function EnemyData.GetEnemiesByMonsterType(monsterType)
    local result = {}
    for _, enemy in ipairs(EnemyData.GetAllEnemies()) do
        if enemy.MonsterType == monsterType then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetAllNormalEnemyIds()
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(enemyData) do
        if type(id) == "number" and enemy.MonsterType == 0 and EnemyHasSkills(enemy) then
            table.insert(result, id)
        end
    end
    return result
end

function EnemyData.GetAllBossIds()
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(enemyData) do
        if type(id) == "number" and enemy.MonsterType == 2 and EnemyHasSkills(enemy) then
            table.insert(result, id)
        end
    end
    return result
end

function EnemyData.Reload()
    enemyData = {}
    isLoaded = false
    return EnemyData.Init()
end

EnemyData.Init()

return EnemyData
