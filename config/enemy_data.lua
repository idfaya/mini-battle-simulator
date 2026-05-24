local ConfigJsonLoader = require("config.json_loader")
local ClassRoleConfig = require("config.tables.classes")
local FeatBuildConfig = require("config.tables.feats")
local Ability5e = require("modules.ability_5e")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")

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

---@class MonsterTypeTemplate
---@field acDelta integer
---@field hitDelta integer
---@field spellDCDelta integer
---@field saveDelta integer

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
}

---@type table<integer, MonsterTypeTemplate>
local MONSTER_TYPE_TEMPLATES = {
    [0] = { acDelta = -4, hitDelta = 0, spellDCDelta = 0, saveDelta = -1 },
    [1] = { acDelta = -2, hitDelta = 1, spellDCDelta = 1, saveDelta = 0 },
    [2] = { acDelta = -1, hitDelta = 2, spellDCDelta = 2, saveDelta = 1 },
}

local ENEMY_LEVEL_MAX = 20

--- 技能解锁等级：普通怪=战斗等级；精英 +1、Boss +2（design/roguelike_monster_system_design.md §5.2）。
local function resolveEnemySkillUnlockLevel(battleLevel, monsterType)
    local lv = math.max(1, math.min(ENEMY_LEVEL_MAX, tonumber(battleLevel) or 1))
    local mt = tonumber(monsterType) or 0
    if mt == 1 then
        lv = lv + 1
    elseif mt == 2 then
        lv = lv + 2
    end
    return math.max(1, math.min(ENEMY_LEVEL_MAX, lv))
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

--- 与 HeroData 一致：各 choiceGroup 取排序后第一项作为敌人默认分支。
local function collectCanonicalEnemyFeatIds(classId, buildLevel)
    local selected = {}
    if not ClassRoleConfig.GetProgression(classId) then
        return selected
    end
    local maxLevel = math.max(1, tonumber(buildLevel) or 1)
    for stageLevel = 1, maxLevel do
        local entry = ClassRoleConfig.GetLevelEntry(classId, stageLevel)
        if entry and entry.choiceGroup then
            local pool = sortFeatDefs(FeatBuildConfig.GetFeatsByLevel(classId, stageLevel, entry.choiceGroup) or {})
            if pool[1] and pool[1].id then
                selected[#selected + 1] = pool[1].id
            end
        end
    end
    return selected
end

local function applyBuildStatMods(target, buildState)
    if not buildState or type(buildState.statMods) ~= "table" then
        return
    end
    for key, delta in pairs(buildState.statMods) do
        local numDelta = tonumber(delta) or 0
        if numDelta ~= 0 then
            local resolvedKey = (key == "atk") and "hit" or key
            if resolvedKey == "maxHp" then
                target.hp = math.max(1, (target.hp or 1) + numDelta)
            else
                target[resolvedKey] = (tonumber(target[resolvedKey]) or 0) + numDelta
            end
        end
    end
    target.atk = target.hit or target.atk
end

---@return table|nil buildState
---@return integer buildLevel
---@return integer[] selectedFeatIds
local function compileEnemyBuild(enemy, battleLevel)
    local classId = tonumber(enemy.Class) or 0
    local buildLevel = resolveEnemySkillUnlockLevel(battleLevel or enemy.Level or 1, enemy.MonsterType)
    local selectedFeatIds = {}
    if type(enemy.FeatIDs) == "table" and #enemy.FeatIDs > 0 then
        for _, featId in ipairs(enemy.FeatIDs) do
            local id = tonumber(featId) or 0
            if id > 0 then
                selectedFeatIds[#selectedFeatIds + 1] = id
            end
        end
    else
        selectedFeatIds = collectCanonicalEnemyFeatIds(classId, buildLevel)
    end
    local buildState = HeroBuild.TryCompileBuild(classId, buildLevel, selectedFeatIds)
    return buildState, buildLevel, selectedFeatIds
end

---@type table<integer, EnemyAbilityScores>
-- 怪物主属性低于英雄同档；精英/Boss 靠 MonsterType delta 与 Build 等级抬升。
local ENEMY_ABILITY_SCORES = {
    [910001] = { str = 8,  dex = 8,  con = 12, int = 2,  wis = 8,  cha = 2  }, -- Slime
    [910002] = { str = 8,  dex = 14, con = 10, int = 8,  wis = 8,  cha = 8  }, -- Goblin
    [910003] = { str = 14, dex = 12, con = 14, int = 8,  wis = 8,  cha = 8  }, -- Orc
    [910004] = { str = 12, dex = 12, con = 12, int = 6,  wis = 8,  cha = 5  }, -- Skeleton
    [910005] = { str = 8,  dex = 12, con = 10, int = 14, wis = 12, cha = 10 }, -- DarkMage
    [910006] = { str = 10, dex = 12, con = 14, int = 16, wis = 12, cha = 10 }, -- IceDemon
    [910007] = { str = 10, dex = 14, con = 12, int = 16, wis = 10, cha = 10 }, -- ThunderLord
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
        return { str = 12, dex = 12, con = 12, int = 8, wis = 10, cha = 8 }
    end
    return { str = 8, dex = 12, con = 10, int = 12, wis = 10, cha = 8 }
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

local function GetEnemyTemplateStats(enemyId, classId, level, monsterType)
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
        hp = math.max(1, math.floor(calculate5eHp(level, hitDie, conMod))),
        ac = math.max(10, math.floor(calculateArmorClass(classId, dexMod, conMod) + mt.acDelta)),
        hit = math.max(0, math.floor(prof + getAttackAbilityMod(classId, strMod, dexMod, intMod, wisMod) + mt.hitDelta)),
        atk = math.max(0, math.floor(prof + getAttackAbilityMod(classId, strMod, dexMod, intMod, wisMod) + mt.hitDelta)),
        spellAttack = math.max(0, math.floor(prof + getSpellAbilityMod(classId, intMod, wisMod, chaMod) + mt.hitDelta)),
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
    }
end

local function EnemyHasClassBuild(enemy)
    if not enemy then
        return false
    end
    return ClassRoleConfig.GetProgression(tonumber(enemy.Class) or 0) ~= nil
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

    local buildState, buildLevel, buildFeatIds = compileEnemyBuild(enemy, level)
    if buildState then
        applyBuildStatMods(heroData, buildState)
        heroData.skillsConfig = SkillRuntime.BuildSkillsConfig(buildState)
        heroData.skills = {}
        for _, cfg in ipairs(heroData.skillsConfig) do
            heroData.skills[#heroData.skills + 1] = {
                skillId = cfg.skillId,
                level = tonumber(cfg.level) or 1,
            }
        end
        heroData.buildFeatIds = buildFeatIds
        heroData._buildLevel = buildLevel
    else
        heroData.skills = {}
        heroData.skillsConfig = {}
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

