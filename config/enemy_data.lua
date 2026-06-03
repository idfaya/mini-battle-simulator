local ConfigJsonLoader = require("config.json_loader")
local ClassRoleConfig = require("config.tables.classes")
local Ability5e = require("modules.ability_5e")

---@class EnemyAbilityScores
---@field str integer
---@field dex integer
---@field con integer
---@field int integer
---@field wis integer
---@field cha integer

---@class EnemyChallengeMeta
---@field cr string
---@field xp integer
---@field role string

---@class EnemySkillEntry
---@field skillId integer
---@field level integer

local EnemyData = {}

local enemyData = {}
local isLoaded = false

---@type table<integer, string>
local MONSTER_TYPE_NAMES = {
    [0] = "普通",
    [1] = "精英",
    [2] = "Boss",
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
    [910008] = { cr = "1/4", xp = 50, role = "skirmisher" }, -- ScoutArcher
    [910009] = { cr = "1/4", xp = 50, role = "caster" },   -- Acolyte
    [910010] = { cr = "1/2", xp = 100, role = "frontliner" }, -- Oathguard
    [910011] = { cr = "1/2", xp = 100, role = "brute" },   -- Berserker
}

local ENEMY_LEVEL_MAX = 20

local function normalizeEnemySkillIds(skillData)
    local skills = {}
    if type(skillData) ~= "table" then
        return skills
    end
    for _, item in ipairs(skillData) do
        local skillId = tonumber(item and (item.skillId or (item.array and item.array[1]))) or 0
        local level = tonumber(item and (item.level or (item.array and item.array[2]))) or 1
        if skillId > 0 then
            skills[#skills + 1] = { skillId = skillId, level = math.max(1, level) }
        end
    end
    return skills
end

local function parseChallengeRating(cr)
    local text = tostring(cr or "")
    local a, b = text:match("^(%d+)%/(%d+)$")
    if a and b then
        local numerator = tonumber(a) or 0
        local denominator = tonumber(b) or 1
        if denominator ~= 0 then
            return numerator / denominator
        end
    end
    return tonumber(text) or 0
end

local function getMonsterProficiencyBonusByCr(cr)
    local value = math.max(0, parseChallengeRating(cr))
    if value >= 29 then return 9 end
    if value >= 25 then return 8 end
    if value >= 21 then return 7 end
    if value >= 17 then return 6 end
    if value >= 13 then return 5 end
    if value >= 9 then return 4 end
    if value >= 5 then return 3 end
    return 2
end

local function getEnemyArmorClass(enemy, dexMod)
    local armorBonus = tonumber(enemy and enemy.AcBonus) or 0
    return math.max(10, 10 + (tonumber(dexMod) or 0) + armorBonus)
end

local function getEnemyBaseHp(enemy, hitDie, conMod)
    local preset = tonumber(enemy and enemy.BaseHp)
    if preset and preset > 0 then
        return math.floor(preset)
    end
    return math.max(1, math.floor(Ability5e.Calculate5eHp(1, hitDie, conMod)))
end

local function clampAbility(score)
    return Ability5e.ClampAbility(score)
end

local function getAbilityMod(score)
    return Ability5e.GetAbilityMod(score)
end

local function getEnemyAbilityScores(enemy, classId)
    local preset = enemy and enemy.AbilityScores
    if type(preset) == "table" then
        return preset
    end
    if ClassRoleConfig.IsMelee(classId) then
        return { str = 12, dex = 12, con = 12, int = 8, wis = 10, cha = 8 }
    end
    return { str = 8, dex = 12, con = 10, int = 12, wis = 10, cha = 8 }
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

local function GetEnemyTemplateStats(enemy)
    local classId = tonumber(enemy and enemy.Class) or 0
    local abilities = getEnemyAbilityScores(enemy, classId)
    local challengeMeta = EnemyData.GetChallengeMeta(enemy and enemy.ID)
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
    local hitDie = Ability5e.GetClassHitDie(classId)
    local prof = getMonsterProficiencyBonusByCr(challengeMeta.cr)

    return {
        hp = math.max(1, math.floor(getEnemyBaseHp(enemy, hitDie, conMod))),
        ac = math.max(10, math.floor(getEnemyArmorClass(enemy, dexMod))),
        hit = math.max(0, math.floor(prof + getAttackAbilityMod(classId, strMod, dexMod, intMod, wisMod))),
        atk = math.max(0, math.floor(prof + getAttackAbilityMod(classId, strMod, dexMod, intMod, wisMod))),
        spellAttack = math.max(0, math.floor(prof + getSpellAbilityMod(classId, intMod, wisMod, chaMod))),
        spellDC = math.max(10, math.floor(8 + prof + getSpellAbilityMod(classId, intMod, wisMod, chaMod))),
        saveFort = math.max(0, math.floor(conMod + (isSaveProficient(classId, "fort") and prof or 0))),
        saveRef = math.max(0, math.floor(dexMod + (isSaveProficient(classId, "ref") and prof or 0))),
        saveWill = math.max(0, math.floor(wisMod + (isSaveProficient(classId, "will") and prof or 0))),
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
    }
end

local function EnemyHasClassBuild(enemy)
    if not enemy then
        return false
    end
    return ClassRoleConfig.HasClass(tonumber(enemy.Class) or 0)
end

function EnemyData.Init()
    if isLoaded then
        return true
    end

    local enemyArray, err = ConfigJsonLoader.Load("data/enemies.json", { expectedType = "table" })
    if not enemyArray then
        print("[EnemyData] " .. tostring(err))
        return false
    end

    for _, enemy in ipairs(enemyArray) do
        if enemy.ID then
            enemy.SkillIDs = normalizeEnemySkillIds(enemy.SkillIDs)
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
    return MONSTER_TYPE_NAMES[monsterType] or "未知"
end

function EnemyData.GetChallengeMeta(enemyId)
    local enemy = EnemyData.GetEnemy(enemyId)
    if not enemy then
        return { cr = "1/4", xp = 50, role = "unknown" }
    end
    return {
        cr = tostring(enemy.CR or "1/4"),
        xp = math.max(0, math.floor(tonumber(enemy.XP) or 50)),
        role = tostring(enemy.Role or "unknown"),
    }
end

function EnemyData.ConvertToHeroData(enemyId, _displayLevelOverride)
    local enemy = EnemyData.GetEnemy(enemyId)
    if not enemy then
        print(string.format("[EnemyData] Enemy not found: %s", tostring(enemyId)))
        return nil
    end

    local name = enemy.EnemyName or string.format("Enemy_%d", enemyId)
    local level = enemy.Level or 1
    level = math.max(1, math.min(ENEMY_LEVEL_MAX, tonumber(level) or 1))
    local star = enemy.Star or 1
    local quality = enemy.Quality or 1
    local monsterType = enemy.MonsterType or 0
    local class = enemy.Class or 2
    local template = GetEnemyTemplateStats(enemy)

    local heroData = {
        id = enemyId,
        name = name,
        hp = template.hp,
        atk = template.atk,
        ac = template.ac,
        hit = template.hit,
        spellAttack = template.spellAttack,
        spellDC = template.spellDC,
        saveFort = template.saveFort,
        saveRef = template.saveRef,
        saveWill = template.saveWill,
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
        level = level,
        _level = level,
        _star = star,
        _quality = quality,
    }

    heroData.skills = {}
    heroData.skillsConfig = {}
    for _, entry in ipairs(enemy.SkillIDs or {}) do
        local skillId = tonumber(entry and entry.skillId) or 0
        local skillLevel = math.max(1, tonumber(entry and entry.level) or 1)
        if skillId > 0 then
            heroData.skills[#heroData.skills + 1] = {
                skillId = skillId,
                level = skillLevel,
            }
            heroData.skillsConfig[#heroData.skillsConfig + 1] = {
                skillId = skillId,
                level = skillLevel,
            }
        end
    end

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
        if type(id) == "number" and enemy.MonsterType == 0 and EnemyHasClassBuild(enemy) then
            table.insert(result, id)
        end
    end
    return result
end

function EnemyData.GetAllBossIds()
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(enemyData) do
        if type(id) == "number" and enemy.MonsterType == 2 and EnemyHasClassBuild(enemy) then
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
