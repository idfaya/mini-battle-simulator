---
--- Enemy Data Loader Module
--- Loads and provides access to enemy data from res_enemy.json and res_enemy_info.json
---

local JSON = require("utils.json")
local EnemyData = {}

-- 内部数据存储
local _enemyData = {}      -- 敌人基础数据 (res_enemy.json)
local _enemyInfoData = {}  -- 敌人详细信息 (res_enemy_info.json)
local _isLoaded = false

-- 职业映射 (Class: 1=前排, 2=中排, 3=后排)
local CLASS_NAMES = {
    [1] = "前排",
    [2] = "中排",
    [3] = "后排"
}

-- 怪物类型映射 (MonsterType: 0=普通, 1=精英, 2=BOSS)
local MONSTER_TYPE_NAMES = {
    [0] = "普通",
    [1] = "精英",
    [2] = "BOSS"
}

--- 获取模块所在目录路径
local function getModulePath()
    local info = debug.getinfo(1, "S")
    local path = info.source:sub(2) -- 去掉开头的 "@"
    path = path:gsub("\\", "/")
    return path:match("(.*/)") or ""
end

--- 加载 JSON 文件
local function loadJsonFile(filename)
    local file, err = io.open(filename, "r")
    if not file then
        print(string.format("[EnemyData] 无法打开文件: %s, 错误: %s", filename, err or "未知"))
        return nil
    end

    local content = file:read("*all")
    file:close()

    local success, result = pcall(JSON.JsonDecode, content)
    if not success then
        print(string.format("[EnemyData] JSON 解析失败: %s, 错误: %s", filename, result))
        return nil
    end

    return result
end

--- 初始化加载数据
function EnemyData.Init()
    if _isLoaded then
        return true
    end

    local basePath = getModulePath()

    -- 加载 res_enemy.json
    local enemyArray = loadJsonFile(basePath .. "res_enemy.json")
    if enemyArray then
        for _, enemy in ipairs(enemyArray) do
            if enemy.ID then
                _enemyData[enemy.ID] = enemy
            end
        end
        print(string.format("[EnemyData] 成功加载 %d 个敌人基础数据", #enemyArray))
    else
        print("[EnemyData] 加载 res_enemy.json 失败")
        return false
    end

    -- 加载 res_enemy_info.json
    local infoArray = loadJsonFile(basePath .. "res_enemy_info.json")
    if infoArray then
        for _, info in ipairs(infoArray) do
            if info.AllyID then
                _enemyInfoData[info.AllyID] = info
            end
        end
        print(string.format("[EnemyData] 成功加载 %d 个敌人详细信息", #infoArray))
    else
        print("[EnemyData] 加载 res_enemy_info.json 失败")
        return false
    end

    _isLoaded = true
    return true
end

--- 获取指定 ID 的敌人基础数据
-- @param enemyId 敌人 ID
-- @return 敌人数据表，如果不存在返回 nil
function EnemyData.GetEnemy(enemyId)
    EnemyData.Init()
    return _enemyData[enemyId]
end

--- 获取指定 ID 的敌人详细信息
-- @param enemyId 敌人 ID (对应 AllyID)
-- @return 敌人信息表，如果不存在返回 nil
function EnemyData.GetEnemyInfo(enemyId)
    EnemyData.Init()
    return _enemyInfoData[enemyId]
end

--- 获取指定等级的所有敌人
-- @param level 等级
-- @return 符合条件的敌人列表
function EnemyData.GetEnemiesByLevel(level)
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.Level == level then
            table.insert(result, enemy)
        end
    end
    return result
end

--- 获取指定职业的所有敌人
-- @param class 职业 (1=前排, 2=中排, 3=后排)
-- @return 符合条件的敌人列表
function EnemyData.GetEnemiesByClass(class)
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.Class == class then
            table.insert(result, enemy)
        end
    end
    return result
end

--- 获取所有敌人数据
-- @return 所有敌人的列表
function EnemyData.GetAllEnemies()
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" then
            table.insert(result, enemy)
        end
    end
    return result
end

--- 获取所有敌人 ID 列表
-- @return 敌人 ID 列表
function EnemyData.GetAllEnemyIds()
    EnemyData.Init()
    local ids = {}
    for id, _ in pairs(_enemyData) do
        if type(id) == "number" then
            table.insert(ids, id)
        end
    end
    return ids
end

--- 获取职业名称
-- @param class 职业 ID
-- @return 职业名称
function EnemyData.GetClassName(class)
    return CLASS_NAMES[class] or "未知"
end

--- 获取怪物类型名称
-- @param monsterType 怪物类型 ID
-- @return 类型名称
function EnemyData.GetMonsterTypeName(monsterType)
    return MONSTER_TYPE_NAMES[monsterType] or "未知"
end

--- 将敌人配置转换为英雄数据格式（用于战斗模拟）
-- 根据敌人的等级、星级、职业等属性生成对应的英雄属性
-- @param enemyId 敌人 ID
-- @return 英雄数据格式表，如果敌人不存在返回 nil
function EnemyData.ConvertToHeroData(enemyId)
    local enemy = EnemyData.GetEnemy(enemyId)
    if not enemy then
        print(string.format("[EnemyData] 敌人不存在: %s", tostring(enemyId)))
        return nil
    end

    local enemyInfo = EnemyData.GetEnemyInfo(enemyId)
    local name = enemyInfo and enemyInfo.EnemyName or string.format("Enemy_%d", enemyId)

    -- 基础属性计算系数
    local level = enemy.Level or 1
    local star = enemy.Star or 1
    local quality = enemy.Quality or 1
    local monsterType = enemy.MonsterType or 0

    -- 根据职业确定基础属性倾向
    local baseHp, baseAtk, baseDef, baseSpeed
    local class = enemy.Class or 2

    if class == 1 then
        -- 前排: 高血量、高防御、中等攻击、低速度
        baseHp = 6000
        baseAtk = 180
        baseDef = 200
        baseSpeed = 80
    elseif class == 2 then
        -- 中排: 平衡型
        baseHp = 4000
        baseAtk = 250
        baseDef = 120
        baseSpeed = 100
    else
        -- 后排: 高攻击、低血量、中等速度
        baseHp = 2800
        baseAtk = 320
        baseDef = 80
        baseSpeed = 110
    end

    -- 等级成长系数 (每级提升约 5%)
    local levelMultiplier = 1 + (level - 1) * 0.05

    -- 星级成长系数 (每星提升约 15%)
    local starMultiplier = 1 + (star - 1) * 0.15

    -- 品质成长系数
    local qualityMultipliers = {1.0, 1.2, 1.5, 2.0, 2.5, 3.0}
    local qualityMultiplier = qualityMultipliers[quality] or 1.0

    -- 怪物类型系数 (精英和BOSS更强)
    local typeMultipliers = {[0] = 1.0, [1] = 1.5, [2] = 3.0}
    local typeMultiplier = typeMultipliers[monsterType] or 1.0

    -- 计算最终属性
    local totalMultiplier = levelMultiplier * starMultiplier * qualityMultiplier * typeMultiplier

    local heroData = {
        id = enemyId,
        name = name,
        hp = math.floor(baseHp * totalMultiplier),
        atk = math.floor(baseAtk * totalMultiplier),
        def = math.floor(baseDef * totalMultiplier),
        speed = math.floor(baseSpeed * (1 + (level - 1) * 0.02)), -- 速度成长较慢
        critRate = 0.10 + (quality * 0.02), -- 品质越高暴击率越高
        critDmg = 1.5 + (star * 0.1), -- 星级越高暴击伤害越高
        skills = {},

        -- 保留原始敌人数据供参考
        _originalEnemy = enemy,
        _class = class,
        _className = EnemyData.GetClassName(class),
        _monsterType = monsterType,
        _monsterTypeName = EnemyData.GetMonsterTypeName(monsterType),
        _level = level,
        _star = star,
        _quality = quality,
    }

    -- 处理技能 (只使用 SkillIDs，不包含 SkillIDsBossWarning)
    local skillList = {}

    if enemy.SkillIDs and #enemy.SkillIDs > 0 then
        for _, skillId in ipairs(enemy.SkillIDs) do
            table.insert(skillList, skillId)
        end
    end

    -- 如果没有技能，添加默认普通攻击
    if #skillList == 0 then
        heroData.skills = {10000} -- 默认普通攻击技能ID
    else
        heroData.skills = skillList
    end

    return heroData
end

--- 批量转换多个敌人为英雄数据
-- @param enemyIds 敌人 ID 列表
-- @return 英雄数据列表
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

--- 根据等级范围获取敌人并转换为英雄数据
-- @param minLevel 最小等级
-- @param maxLevel 最大等级
-- @param count 需要获取的数量 (可选)
-- @return 英雄数据列表
function EnemyData.GetHeroesByLevelRange(minLevel, maxLevel, count)
    EnemyData.Init()
    local result = {}
    local found = 0

    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.Level >= minLevel and enemy.Level <= maxLevel then
            local heroData = EnemyData.ConvertToHeroData(id)
            if heroData then
                table.insert(result, heroData)
                found = found + 1
                if count and found >= count then
                    break
                end
            end
        end
    end

    return result
end

--- 获取指定怪物类型的敌人
-- @param monsterType 怪物类型 (0=普通, 1=精英, 2=BOSS)
-- @return 符合条件的敌人列表
function EnemyData.GetEnemiesByMonsterType(monsterType)
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.MonsterType == monsterType then
            table.insert(result, enemy)
        end
    end
    return result
end

--- 重新加载数据（用于调试）
function EnemyData.Reload()
    _enemyData = {}
    _enemyInfoData = {}
    _isLoaded = false
    return EnemyData.Init()
end

-- 自动初始化
EnemyData.Init()

return EnemyData
