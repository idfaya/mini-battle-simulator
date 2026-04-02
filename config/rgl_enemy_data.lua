local JSON = require("utils.json")
local RglEnemyData = {}

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

local _enemyData = {}
local _isLoaded = false

local CLASS_NAMES = {
    [1] = "Front",
    [2] = "Mid",
    [3] = "Back"
}

local MONSTER_TYPE_NAMES = {
    [0] = "Normal",
    [1] = "Elite",
    [2] = "BOSS"
}

local STAR_MULTIPLIERS = {
    [1] = 1.0, [2] = 1.1, [3] = 1.2,
    [4] = 1.3, [5] = 1.5, [6] = 1.8, [7] = 2.2
}

local function GetStarMultiplier(star)
    return STAR_MULTIPLIERS[star] or 1.0
end

local function CalculateLevelGrowth(level, class)
    local baseGrowthRate = 0.05
    local hpRate, atkRate, defRate
    if class == 1 then
        hpRate, atkRate, defRate = 1.2, 0.8, 1.1
    elseif class == 2 then
        hpRate, atkRate, defRate = 1.0, 1.0, 1.0
    else
        hpRate, atkRate, defRate = 0.8, 1.2, 0.9
    end

    local levelDiff = level - 1
    if levelDiff <= 0 then return 0, 0, 0 end

    local hpGrowth = math.floor(100 * baseGrowthRate * levelDiff * hpRate)
    local atkGrowth = math.floor(20 * baseGrowthRate * levelDiff * atkRate)
    local defGrowth = math.floor(15 * baseGrowthRate * levelDiff * defRate)

    return hpGrowth, atkGrowth, defGrowth
end

local function loadJsonFile(filename)
    local file, err = io.open(filename, "r")
    if not file then
        print(string.format("[RglEnemyData] Cannot open: %s", filename))
        return nil
    end
    local content = file:read("*all")
    file:close()
    local success, result = pcall(JSON.JsonDecode, content)
    if not success then
        print(string.format("[RglEnemyData] JSON parse failed: %s", filename))
        return nil
    end
    return result
end

function RglEnemyData.Init()
    if _isLoaded then return true end

    local enemyPath = GetConfigFilePath("res_rgl_enemy.json")
    local enemyArray = enemyPath and loadJsonFile(enemyPath) or nil
    if enemyArray then
        for _, enemy in ipairs(enemyArray) do
            if enemy.ID then
                _enemyData[enemy.ID] = enemy
            end
        end
        print(string.format("[RglEnemyData] Loaded %d RGL enemies", #enemyArray))
    else
        print("[RglEnemyData] Failed to load res_rgl_enemy.json")
        return false
    end

    _isLoaded = true
    return true
end

function RglEnemyData.GetEnemy(enemyId)
    RglEnemyData.Init()
    return _enemyData[enemyId]
end

function RglEnemyData.GetAllEnemies()
    RglEnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" then
            table.insert(result, enemy)
        end
    end
    return result
end

function RglEnemyData.GetAllEnemyIds()
    RglEnemyData.Init()
    local ids = {}
    for id, _ in pairs(_enemyData) do
        if type(id) == "number" then
            table.insert(ids, id)
        end
    end
    return ids
end

function RglEnemyData.GetClassName(class)
    return CLASS_NAMES[class] or "Unknown"
end

function RglEnemyData.GetMonsterTypeName(monsterType)
    return MONSTER_TYPE_NAMES[monsterType] or "Unknown"
end

function RglEnemyData.ConvertToHeroData(enemyId, overrideLevel)
    local enemy = RglEnemyData.GetEnemy(enemyId)
    if not enemy then
        print(string.format("[RglEnemyData] Enemy not found: %s", tostring(enemyId)))
        return nil
    end

    local name = enemy.EnemyName or string.format("RglEnemy_%d", enemyId)
    local level = overrideLevel or enemy.Level or 1
    local star = enemy.Star or 1
    local quality = enemy.Quality or 1
    local monsterType = enemy.MonsterType or 0
    local class = enemy.Class or 2

    local baseHp, baseAtk, baseDef, baseSpeed
    if class == 1 then
        baseHp, baseAtk, baseDef, baseSpeed = 900, 70, 55, 75
    elseif class == 2 then
        baseHp, baseAtk, baseDef, baseSpeed = 680, 82, 40, 95
    else
        baseHp, baseAtk, baseDef, baseSpeed = 520, 98, 30, 105
    end

    local hpGrowthRate = 0.10 + quality * 0.012
    local atkGrowthRate = 0.08 + quality * 0.01
    local defGrowthRate = 0.065 + quality * 0.008

    local levelDiff = math.max(0, level - 1)
    local hpGrowth = math.floor(baseHp * hpGrowthRate * levelDiff)
    local atkGrowth = math.floor(baseAtk * atkGrowthRate * levelDiff)
    local defGrowth = math.floor(baseDef * defGrowthRate * levelDiff)

    local qualityMultipliers = {1.0, 1.1, 1.15, 1.2, 1.25, 1.3}
    local qualityMultiplier = qualityMultipliers[quality] or 1.0
    local typeMultipliers = {[0] = 1.0, [1] = 1.2, [2] = 1.5}
    local typeMultiplier = typeMultipliers[monsterType] or 1.0
    local starMultiplier = GetStarMultiplier(star)
    local totalMultiplier = qualityMultiplier * typeMultiplier * starMultiplier

    local heroData = {
        id = enemyId,
        name = name,
        hp = math.floor((baseHp + hpGrowth) * totalMultiplier),
        atk = math.floor((baseAtk + atkGrowth) * totalMultiplier),
        def = math.floor((baseDef + defGrowth) * totalMultiplier),
        speed = baseSpeed,
        critRate = 0.05 + (quality * 0.01),
        critDmg = 1.3 + (star * 0.05),
        skills = {},
        class = class,
        isRgl = true,
        _originalEnemy = enemy,
        _class = class,
        _className = RglEnemyData.GetClassName(class),
        _monsterType = monsterType,
        _monsterTypeName = RglEnemyData.GetMonsterTypeName(monsterType),
        _level = level,
        _star = star,
        _quality = quality,
    }

    local skillList = {}
    local skillsConfig = {}
    local processedSkillIds = {}

    local function AddSkill(skillId)
        if not skillId or processedSkillIds[skillId] then return end
        processedSkillIds[skillId] = true
        table.insert(skillList, skillId)

        local skillType = E_SKILL_TYPE_PASSIVE
        local skillCost = 0

        if skillId >= 800010000 and skillId < 800013000 then
            local lastDigit = (math.floor(skillId / 100)) % 10
            if lastDigit == 1 then
                skillType = E_SKILL_TYPE_NORMAL
            elseif lastDigit == 2 then
                skillType = E_SKILL_TYPE_NORMAL
            elseif lastDigit >= 3 then
                skillType = E_SKILL_TYPE_ULTIMATE
                skillCost = 100
            end
        end

        table.insert(skillsConfig, {
            skillId = skillId,
            skillType = skillType,
            name = "RglSkill_" .. skillId,
            skillCost = skillCost
        })
    end

    if enemy.SkillIDs and #enemy.SkillIDs > 0 then
        for _, skillId in ipairs(enemy.SkillIDs) do
            AddSkill(skillId)
        end
    end

    if enemy.SkillIDsBossWarning and #enemy.SkillIDsBossWarning > 0 then
        for _, skillId in ipairs(enemy.SkillIDsBossWarning) do
            AddSkill(skillId)
        end
    end

    heroData.skills = {}
    for _, sid in ipairs(skillList) do
        table.insert(heroData.skills, {skillId = sid, level = 1})
    end
    heroData.skillsConfig = skillsConfig

    return heroData
end

function RglEnemyData.ConvertEnemiesToHeroData(enemyIds)
    local result = {}
    for _, enemyId in ipairs(enemyIds) do
        local heroData = RglEnemyData.ConvertToHeroData(enemyId)
        if heroData then
            table.insert(result, heroData)
        end
    end
    return result
end

local function EnemyHasSkills(enemy)
    if not enemy then return false end
    if enemy.SkillIDs and #enemy.SkillIDs > 0 then return true end
    if enemy.SkillIDsBossWarning and #enemy.SkillIDsBossWarning > 0 then return true end
    return false
end

function RglEnemyData.GetAllNormalEnemyIds()
    RglEnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.MonsterType == 0 and EnemyHasSkills(enemy) then
            table.insert(result, id)
        end
    end
    return result
end

function RglEnemyData.GetAllBossIds()
    RglEnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.MonsterType == 2 and EnemyHasSkills(enemy) then
            table.insert(result, id)
        end
    end
    return result
end

function RglEnemyData.Reload()
    _enemyData = {}
    _isLoaded = false
    return RglEnemyData.Init()
end

RglEnemyData.Init()

return RglEnemyData