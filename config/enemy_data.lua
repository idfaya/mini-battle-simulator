local JSON = require("utils.json")
local SkillConfig = require("config.skill_config")
local ClassRoleConfig = require("config.class_role_config")
local Ability5e = require("modules.ability_5e")

---@class EnemyAbilityScores
---@field str integer
---@field dex integer
---@field con integer
---@field int integer
---@field wis integer
---@field cha integer

---@class EnemyRoleTemplate
---@field hp integer[]
---@field atk integer[]
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

---@class EnemyChallengeMeta
---@field cr string
---@field xp integer
---@field role string

---@class MonsterTypeTemplate
---@field hpMul number
---@field atkMul number
---@field defMul number
---@field acDelta integer
---@field hitDelta integer
---@field spellDCDelta integer
---@field saveDelta integer
---@field speedDelta integer

local EnemyData = {}

local enemyData = {}
local isLoaded = false
local skillConfigInited = false

---@type table<integer, string>
local MONSTER_TYPE_NAMES = {
    [0] = "Normal",
    [1] = "Elite",
    [2] = "BOSS",
}

---@type table<integer, EnemyChallengeMeta>
local ENEMY_CR_META = {
    [910001] = { cr = "1/8", xp = 25, role = "fodder" },   -- Slime
    [910002] = { cr = "1/4", xp = 50, role = "skirmisher" }, -- Goblin
    [910003] = { cr = "1/2", xp = 100, role = "brute" },   -- Orc
    [910004] = { cr = "1/4", xp = 50, role = "frontliner" }, -- Skeleton
    [910005] = { cr = "1", xp = 200, role = "caster" },    -- DarkMage
    [910006] = { cr = "3", xp = 700, role = "elite_caster" }, -- IceDemon
    [910007] = { cr = "4", xp = 1100, role = "elite_caster" }, -- ThunderLord
}

-- True 5e-style enemy templates.
-- Base role template is picked by class, then monster type applies a clean modifier.
---@type table<integer|string, EnemyRoleTemplate>
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

---@type table<integer, MonsterTypeTemplate>
local MONSTER_TYPE_TEMPLATES = {
    [0] = { hpMul = 0.58, atkMul = 1.00, defMul = 0.95, acDelta = -4, hitDelta = 0, spellDCDelta = 0, saveDelta = -1, speedDelta = 0 },
    [1] = { hpMul = 0.80, atkMul = 1.10, defMul = 1.00, acDelta = -2, hitDelta = 1, spellDCDelta = 1, saveDelta = 0, speedDelta = 0 },
    [2] = { hpMul = 1.08, atkMul = 1.22, defMul = 1.10, acDelta = -1, hitDelta = 2, spellDCDelta = 2, saveDelta = 1, speedDelta = 1 },
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

local function BuildConfiguredSkillIds(enemy)
    local result = {}
    local seen = {}

    local function Add(skillId)
        if not skillId or seen[skillId] then
            return
        end
        seen[skillId] = true
        table.insert(result, skillId)
    end

    for _, skillId in ipairs(enemy.SkillIDs or {}) do
        Add(skillId)
    end

    return result
end

local ENEMY_LEVEL_MAX = 20
---@type integer[]
local ENEMY_TIER_STARTS = { 1, 5, 11, 17, ENEMY_LEVEL_MAX + 1 }

---@type table<integer, EnemyAbilityScores>
local ENEMY_ABILITY_SCORES = {
    [910001] = { str = 10, dex = 8,  con = 14, int = 2,  wis = 8,  cha = 2  }, -- Slime
    [910002] = { str = 8,  dex = 16, con = 10, int = 8,  wis = 8,  cha = 8  }, -- Goblin
    [910003] = { str = 16, dex = 12, con = 16, int = 8,  wis = 8,  cha = 8  }, -- Orc
    [910004] = { str = 14, dex = 14, con = 14, int = 6,  wis = 8,  cha = 5  }, -- Skeleton
    [910005] = { str = 8,  dex = 14, con = 12, int = 16, wis = 12, cha = 10 }, -- DarkMage
    [910006] = { str = 12, dex = 14, con = 16, int = 18, wis = 14, cha = 12 }, -- IceDemon
    [910007] = { str = 10, dex = 16, con = 14, int = 18, wis = 12, cha = 12 }, -- ThunderLord
}

local function clampAbility(score)
    return Ability5e.ClampAbility(score)
end

local function getAbilityMod(score)
    return Ability5e.GetAbilityMod(score)
end

local function getEnemyAbilityScores(enemyId, classId)
    local preset = ENEMY_ABILITY_SCORES[tonumber(enemyId) or 0]
    if preset then
        return preset
    end
    if ClassRoleConfig.IsMelee(classId) then
        return { str = 14, dex = 12, con = 14, int = 8, wis = 10, cha = 8 }
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
    local lv = math.max(1, math.min(ENEMY_LEVEL_MAX, tonumber(level) or 1))
    return Ability5e.Calculate5eHp(lv, hitDie, conMod)
end

local function getProficiencyBonus(level)
    local lv = math.max(1, math.min(ENEMY_LEVEL_MAX, tonumber(level) or 1))
    return Ability5e.GetProficiencyBonus(lv)
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

local function calculateArmorClass(classId, dexMod, conMod)
    return Ability5e.CalculateArmorClass(classId, {
        dex = dexMod, con = conMod,
    })
end

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
        atk = GetInterpolatedTemplateValue(tpl.atk, level),
        def = GetInterpolatedTemplateValue(tpl.def, level),
        speed = GetInterpolatedTemplateValue(tpl.speed, level),
        critRate = tpl.critRate or 0,
        blockRate = tpl.blockRate or 0,
        healBonus = tpl.healBonus or 0,
    }
end

local function GetEnemyTemplateStats(enemyId, classId, level, monsterType)
    local base = GetBaseTemplateStats(classId, level)
    local mt = MONSTER_TYPE_TEMPLATES[tonumber(monsterType) or 0] or MONSTER_TYPE_TEMPLATES[0]
    local abilities = getEnemyAbilityScores(enemyId, classId)
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
    local hitDie = getClassHitDie(classId)
    local prof = getProficiencyBonus(level)

    return {
        hp = math.max(1, math.floor(calculate5eHp(level, hitDie, conMod) * mt.hpMul)),
        atk = math.max(1, math.floor(base.atk * mt.atkMul)),
        def = math.max(0, math.floor(base.def * mt.defMul)),
        speed = math.max(60, math.floor(base.speed + mt.speedDelta)),
        ac = math.max(10, math.floor(calculateArmorClass(classId, dexMod, conMod) + mt.acDelta)),
        hit = math.max(0, math.floor(prof + getAttackAbilityMod(classId, strMod, dexMod, intMod, wisMod) + mt.hitDelta)),
        spellDC = math.max(10, math.floor(8 + prof + getSpellAbilityMod(classId, intMod, wisMod, chaMod) + mt.spellDCDelta)),
        saveFort = math.max(0, math.floor(conMod + (isSaveProficient(classId, "fort") and prof or 0) + mt.saveDelta)),
        saveRef = math.max(0, math.floor(dexMod + (isSaveProficient(classId, "ref") and prof or 0) + mt.saveDelta)),
        saveWill = math.max(0, math.floor(wisMod + (isSaveProficient(classId, "will") and prof or 0) + mt.saveDelta)),
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

function EnemyData.GetChallengeMeta(enemyId)
    local meta = ENEMY_CR_META[tonumber(enemyId) or 0]
    if not meta then
        return { cr = "1/4", xp = 50, role = "unknown" }
    end
    return {
        cr = meta.cr,
        xp = meta.xp,
        role = meta.role,
    }
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
    local template = GetEnemyTemplateStats(enemyId, class, level, monsterType)

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
        str = template.str,
        dex = template.dex,
        con = template.con,
        int = template.int,
        wis = template.wis,
        cha = template.cha,
        strMod = template.strMod,
        dexMod = template.dexMod,
        conMod = template.conMod,
        intMod = template.intMod,
        wisMod = template.wisMod,
        chaMod = template.chaMod,
        hitDie = template.hitDie,
        proficiencyBonus = template.proficiencyBonus,
        skills = {},
        class = class,
        _originalEnemy = enemy,
        _class = class,
        _className = EnemyData.GetClassName(class),
        _monsterType = monsterType,
        _monsterTypeName = EnemyData.GetMonsterTypeName(monsterType),
        _challenge = EnemyData.GetChallengeMeta(enemyId),
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

    for _, skillId in ipairs(BuildConfiguredSkillIds(enemy)) do
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
