local JSON = require("utils.json")
local SkillConfig = require("config.skill_config")
local ClassRoleConfig = require("config.class_role_config")

local EnemyData = {}

local enemyData = {}
local isLoaded = false
local skillConfigInited = false

local MONSTER_TYPE_NAMES = {
    [0] = "Normal",
    [1] = "Elite",
    [2] = "BOSS",
}

-- True 5e-style enemy templates.
-- Base role template is picked by class, then monster type applies a clean modifier.
local ENEMY_ROLE_TEMPLATES = {
    [1] = { hp = { 38, 48, 58, 70, 82 }, atk = { 7, 8, 9, 10, 11 }, def = { 2, 3, 3, 4, 4 }, speed = { 101, 102, 103, 104, 105 }, ac = { 15, 16, 17, 18, 19 }, hit = { 6, 7, 8, 9, 10 }, spellDC = { 11, 12, 13, 13, 14 }, saveFort = { 3, 4, 4, 5, 5 }, saveRef = { 4, 5, 6, 7, 8 }, saveWill = { 2, 3, 4, 5, 6 }, critRate = 800, blockRate = 400 },
    [2] = { hp = { 52, 66, 80, 94, 108 }, atk = { 6, 7, 8, 9, 10 }, def = { 3, 4, 5, 6, 7 }, speed = { 92, 93, 94, 95, 96 }, ac = { 17, 18, 19, 20, 21 }, hit = { 5, 6, 7, 8, 9 }, spellDC = { 11, 12, 12, 13, 14 }, saveFort = { 4, 5, 6, 7, 8 }, saveRef = { 2, 3, 4, 5, 6 }, saveWill = { 3, 4, 5, 6, 7 }, critRate = 300, blockRate = 1600 },
    [3] = { hp = { 44, 56, 68, 80, 92 }, atk = { 7, 8, 9, 10, 12 }, def = { 2, 3, 3, 4, 4 }, speed = { 104, 105, 106, 107, 108 }, ac = { 16, 17, 18, 19, 20 }, hit = { 6, 7, 8, 9, 10 }, spellDC = { 11, 12, 13, 13, 14 }, saveFort = { 3, 4, 5, 6, 7 }, saveRef = { 4, 5, 6, 7, 8 }, saveWill = { 2, 3, 4, 5, 6 }, critRate = 700, blockRate = 400 },
    [4] = { hp = { 56, 72, 88, 104, 120 }, atk = { 6, 7, 8, 10, 11 }, def = { 3, 4, 4, 5, 6 }, speed = { 94, 95, 96, 97, 98 }, ac = { 16, 17, 18, 19, 20 }, hit = { 5, 6, 7, 8, 9 }, spellDC = { 11, 12, 12, 13, 14 }, saveFort = { 4, 5, 6, 7, 8 }, saveRef = { 2, 3, 4, 5, 6 }, saveWill = { 3, 4, 5, 6, 7 }, critRate = 500, blockRate = 900 },
    [5] = { hp = { 46, 58, 70, 82, 94 }, atk = { 7, 8, 9, 10, 11 }, def = { 2, 3, 3, 4, 4 }, speed = { 97, 98, 99, 100, 101 }, ac = { 15, 16, 17, 18, 19 }, hit = { 6, 7, 8, 9, 10 }, spellDC = { 12, 13, 14, 15, 16 }, saveFort = { 3, 4, 5, 6, 7 }, saveRef = { 4, 5, 6, 7, 8 }, saveWill = { 2, 3, 4, 5, 6 }, critRate = 500, blockRate = 700 },
    [6] = { hp = { 42, 52, 62, 72, 82 }, atk = { 4, 5, 6, 7, 8 }, def = { 2, 2, 3, 3, 4 }, speed = { 97, 98, 99, 100, 101 }, ac = { 14, 15, 15, 16, 17 }, hit = { 3, 4, 4, 5, 6 }, spellDC = { 13, 14, 15, 16, 17 }, saveFort = { 2, 3, 4, 5, 6 }, saveRef = { 2, 3, 4, 5, 6 }, saveWill = { 4, 5, 6, 7, 8 }, critRate = 300, blockRate = 400, healBonus = 800 },
    [7] = { hp = { 36, 46, 56, 66, 76 }, atk = { 4, 5, 6, 7, 8 }, def = { 1, 2, 2, 3, 3 }, speed = { 99, 100, 101, 102, 103 }, ac = { 13, 13, 14, 15, 15 }, hit = { 3, 3, 4, 4, 5 }, spellDC = { 14, 15, 16, 17, 18 }, saveFort = { 2, 3, 4, 5, 6 }, saveRef = { 3, 4, 5, 6, 7 }, saveWill = { 4, 5, 6, 7, 8 }, critRate = 500, blockRate = 300 },
    [8] = { hp = { 40, 50, 60, 70, 80 }, atk = { 4, 5, 6, 7, 8 }, def = { 1, 2, 2, 3, 3 }, speed = { 97, 98, 99, 100, 101 }, ac = { 14, 14, 15, 15, 16 }, hit = { 3, 3, 4, 4, 5 }, spellDC = { 13, 14, 15, 16, 17 }, saveFort = { 3, 4, 5, 6, 7 }, saveRef = { 3, 4, 5, 6, 7 }, saveWill = { 3, 4, 5, 6, 7 }, critRate = 400, blockRate = 400 },
    [9] = { hp = { 37, 47, 57, 67, 77 }, atk = { 4, 5, 6, 7, 8 }, def = { 1, 2, 2, 3, 3 }, speed = { 100, 101, 102, 103, 104 }, ac = { 13, 13, 14, 15, 15 }, hit = { 3, 3, 4, 4, 5 }, spellDC = { 14, 15, 16, 17, 18 }, saveFort = { 2, 3, 4, 5, 6 }, saveRef = { 4, 5, 6, 7, 8 }, saveWill = { 3, 4, 5, 6, 7 }, critRate = 700, blockRate = 300 },
    default = { hp = { 42, 52, 62, 72, 82 }, atk = { 5, 6, 7, 8, 9 }, def = { 2, 2, 3, 3, 4 }, speed = { 98, 99, 100, 101, 102 }, ac = { 15, 16, 17, 18, 19 }, hit = { 5, 6, 7, 8, 9 }, spellDC = { 12, 13, 14, 15, 16 }, saveFort = { 3, 4, 5, 6, 7 }, saveRef = { 3, 4, 5, 6, 7 }, saveWill = { 3, 4, 5, 6, 7 }, critRate = 500, blockRate = 500 },
}

local MONSTER_TYPE_TEMPLATES = {
    [0] = { hpMul = 0.85, atkMul = 0.95, defMul = 0.95, acDelta = -1, hitDelta = -1, spellDCDelta = -1, saveDelta = -1, speedDelta = 0 },
    [1] = { hpMul = 1.15, atkMul = 1.05, defMul = 1.00, acDelta = 0, hitDelta = 0, spellDCDelta = 0, saveDelta = 0, speedDelta = 0 },
    [2] = { hpMul = 1.80, atkMul = 1.15, defMul = 1.10, acDelta = 1, hitDelta = 1, spellDCDelta = 1, saveDelta = 1, speedDelta = 1 },
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
        -- 1-20 scale: unlock more family skills as level rises.
        if level >= 6 or (enemy.MonsterType or 0) >= 1 then
            Add(family * 10 + 2)
        end
        if level >= 12 or (enemy.MonsterType or 0) >= 1 then
            Add(family * 10 + 3)
        end
        if level >= 17 or (enemy.MonsterType or 0) >= 2 then
            Add(family * 10 + 4)
        end
    end

    return result
end

local ENEMY_LEVEL_MAX = 20
local ENEMY_TIER_STARTS = { 1, 5, 11, 17, ENEMY_LEVEL_MAX + 1 }

local function GetTier(level)
    local lv = tonumber(level) or 1
    lv = math.max(1, math.min(ENEMY_LEVEL_MAX, lv))
    if lv >= ENEMY_TIER_STARTS[4] then return 4 end
    if lv >= ENEMY_TIER_STARTS[3] then return 3 end
    if lv >= ENEMY_TIER_STARTS[2] then return 2 end
    return 1
end

local function GetRoleTemplate(classId)
    return ENEMY_ROLE_TEMPLATES[tonumber(classId) or 0] or ENEMY_ROLE_TEMPLATES.default
end

local function GetInterpolatedTemplateValue(series, level)
    if type(series) ~= "table" or #series == 0 then
        return 0
    end
    local lv = math.max(1, math.min(ENEMY_LEVEL_MAX, tonumber(level) or 1))
    local a1 = tonumber(series[1]) or 0
    local a2 = tonumber(series[2]) or a1
    local a3 = tonumber(series[3]) or a2
    local a4 = tonumber(series[4]) or a3

    local tier = GetTier(lv)
    if tier == 1 then
        local progress = (lv - ENEMY_TIER_STARTS[1]) / (ENEMY_TIER_STARTS[2] - ENEMY_TIER_STARTS[1])
        return a1 + (a2 - a1) * progress
    elseif tier == 2 then
        local progress = (lv - ENEMY_TIER_STARTS[2]) / (ENEMY_TIER_STARTS[3] - ENEMY_TIER_STARTS[2])
        return a2 + (a3 - a2) * progress
    elseif tier == 3 then
        local progress = (lv - ENEMY_TIER_STARTS[3]) / (ENEMY_TIER_STARTS[4] - ENEMY_TIER_STARTS[3])
        return a3 + (a4 - a3) * progress
    end
    return a4
end

local function GetBaseTemplateStats(classId, level)
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

local function GetEnemyTemplateStats(classId, level, monsterType)
    local base = GetBaseTemplateStats(classId, level)
    local mt = MONSTER_TYPE_TEMPLATES[tonumber(monsterType) or 0] or MONSTER_TYPE_TEMPLATES[0]
    return {
        hp = math.max(1, math.floor(base.hp * mt.hpMul)),
        atk = math.max(1, math.floor(base.atk * mt.atkMul)),
        def = math.max(0, math.floor(base.def * mt.defMul)),
        speed = math.max(60, math.floor(base.speed + mt.speedDelta)),
        ac = math.max(10, math.floor(base.ac + mt.acDelta)),
        hit = math.max(0, math.floor(base.hit + mt.hitDelta)),
        spellDC = math.max(10, math.floor(base.spellDC + mt.spellDCDelta)),
        saveFort = math.max(0, math.floor(base.saveFort + mt.saveDelta)),
        saveRef = math.max(0, math.floor(base.saveRef + mt.saveDelta)),
        saveWill = math.max(0, math.floor(base.saveWill + mt.saveDelta)),
        critRate = base.critRate,
        blockRate = base.blockRate,
        healBonus = base.healBonus,
    }
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
    return ClassRoleConfig.GetName(class)
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
    level = math.max(1, math.min(ENEMY_LEVEL_MAX, tonumber(level) or 1))
    local star = enemy.Star or 1
    local quality = enemy.Quality or 1
    local monsterType = enemy.MonsterType or 0
    local class = enemy.Class or 2
    local template = GetEnemyTemplateStats(class, level, monsterType)

    local heroData = {
        id = enemyId,
        name = name,
        hp = template.hp,
        atk = template.atk,
        def = template.def,
        speed = template.speed,
        ac = template.ac,
        hit = template.hit,
        spellDC = template.spellDC,
        saveFort = template.saveFort,
        saveRef = template.saveRef,
        saveWill = template.saveWill,
        critRate = template.critRate or 0,
        critDamage = 150,
        blockRate = template.blockRate or 0,
        healBonus = template.healBonus or 0,
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
