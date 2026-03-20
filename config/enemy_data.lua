---
--- Enemy Data Loader Module
--- Loads and provides access to enemy data from res_enemy.json and res_enemy_info.json
---

local JSON = require("utils.json")
local EnemyData = {}

-- 配置目录路径（从bin目录运行时的相对路径）
local CONFIG_DIR = "../config/"

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

-- 星级倍率
local STAR_MULTIPLIERS = {
    [1] = 1.0,
    [2] = 1.1,
    [3] = 1.2,
    [4] = 1.3,
    [5] = 1.5,
    [6] = 1.8,
    [7] = 2.2
}

-- 获取星级倍率
local function GetStarMultiplier(star)
    return STAR_MULTIPLIERS[star] or 1.0
end

-- 计算敌人等级成长值
-- 参考 Hero 的成长曲线，但稍微简化
local function CalculateEnemyLevelGrowth(level, class)
    -- 基础成长系数
    local baseGrowthRate = 0.05  -- 每级 5% 成长
    
    -- 根据职业调整成长倾向
    local hpRate, atkRate, defRate
    if class == 1 then  -- 前排: HP成长高
        hpRate = 1.2
        atkRate = 0.8
        defRate = 1.1
    elseif class == 2 then  -- 中排: 平衡
        hpRate = 1.0
        atkRate = 1.0
        defRate = 1.0
    else  -- 后排: ATK成长高
        hpRate = 0.8
        atkRate = 1.2
        defRate = 0.9
    end
    
    -- 计算成长值 (从1级到当前等级的累计成长)
    local levelDiff = level - 1
    if levelDiff <= 0 then
        return 0, 0, 0
    end
    
    -- 成长公式: 基础值 * 成长率 * 等级差 * 职业系数
    local hpGrowth = math.floor(100 * baseGrowthRate * levelDiff * hpRate)
    local atkGrowth = math.floor(20 * baseGrowthRate * levelDiff * atkRate)
    local defGrowth = math.floor(15 * baseGrowthRate * levelDiff * defRate)
    
    return hpGrowth, atkGrowth, defGrowth
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

    -- 加载 res_enemy.json
    local enemyArray = loadJsonFile(CONFIG_DIR .. "res_enemy.json")
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
    local infoArray = loadJsonFile(CONFIG_DIR .. "res_enemy_info.json")
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

    -- 敌人属性配置
    local level = enemy.Level or 1
    local star = enemy.Star or 1
    local quality = enemy.Quality or 1
    local monsterType = enemy.MonsterType or 0
    local class = enemy.Class or 2

    -- 根据职业确定基础属性倾向
    local baseHp, baseAtk, baseDef, baseSpeed

    if class == 1 then
        -- 前排: 高血量、高防御、中等攻击、低速度
        baseHp = 3000
        baseAtk = 120
        baseDef = 150
        baseSpeed = 80
    elseif class == 2 then
        -- 中排: 平衡型
        baseHp = 2200
        baseAtk = 150
        baseDef = 100
        baseSpeed = 100
    else
        -- 后排: 高攻击、低血量、中等速度
        baseHp = 1800
        baseAtk = 180
        baseDef = 70
        baseSpeed = 110
    end

    -- 计算等级成长
    local hpGrowth, atkGrowth, defGrowth = CalculateEnemyLevelGrowth(level, class)

    -- 轻微的品质调整 (10%-30%)
    local qualityMultipliers = {1.0, 1.1, 1.15, 1.2, 1.25, 1.3}
    local qualityMultiplier = qualityMultipliers[quality] or 1.0

    -- 怪物类型系数 (精英和BOSS有轻微加成)
    local typeMultipliers = {[0] = 1.0, [1] = 1.2, [2] = 1.5}
    local typeMultiplier = typeMultipliers[monsterType] or 1.0

    -- 星级倍率
    local starMultiplier = GetStarMultiplier(star)

    -- 计算最终属性 = (基础 + 成长) * 品质 * 类型 * 星级
    local totalMultiplier = qualityMultiplier * typeMultiplier * starMultiplier

    local heroData = {
        id = enemyId,
        name = name,
        hp = math.floor((baseHp + hpGrowth) * totalMultiplier),
        atk = math.floor((baseAtk + atkGrowth) * totalMultiplier),
        def = math.floor((baseDef + defGrowth) * totalMultiplier),
        speed = baseSpeed,
        critRate = 0.05 + (quality * 0.01), -- 品质越高暴击率越高
        critDmg = 1.3 + (star * 0.05), -- 星级越高暴击伤害越高
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

    -- 处理技能 (使用 SkillIDs 和 SkillIDsBossWarning)
    local skillList = {}
    local skillsConfig = {}
    local processedSkillIds = {}  -- 用于去重

    -- 辅助函数：添加技能
    local function AddSkill(skillId)
        if not skillId or processedSkillIds[skillId] then return end
        processedSkillIds[skillId] = true
        
        table.insert(skillList, skillId)
        
        -- 构建 skillsConfig 格式 (与 ally_data.lua 一致)
        -- 敌人技能ID已经是完整格式，直接使用
        local skillType = 1  -- 默认普通攻击
        local skillCost = 0
        
        -- 根据技能ID判断类型
        -- 技能ID最后两位表示等级，倒数第三位表示类型
        -- 例如: 207010101 -> 类型=E_SKILL_TYPE_NORMAL (普通攻击)
        --       207010201 -> 类型=E_SKILL_TYPE_NORMAL (普通技能)
        --       207010301 -> 类型=E_SKILL_TYPE_ULTIMATE (大招)
        local classId = math.floor(skillId / 100)  -- 去掉等级部分
        local lastDigit = classId % 10
        
        if lastDigit == 2 then
            skillType = E_SKILL_TYPE_NORMAL  -- 普通技能（无能量消耗）
        elseif lastDigit == 3 then
            skillType = E_SKILL_TYPE_ULTIMATE  -- 大招
            skillCost = 100  -- 大招消耗100能量
        end
        
        table.insert(skillsConfig, {
            skillId = skillId,
            skillType = skillType,
            name = "EnemySkill_" .. skillId,
            skillCost = skillCost
        })
    end

    -- 读取 SkillIDs
    if enemy.SkillIDs and #enemy.SkillIDs > 0 then
        for _, skillId in ipairs(enemy.SkillIDs) do
            AddSkill(skillId)
        end
    end

    -- 读取 SkillIDsBossWarning (Boss警告技能，也是实际可用的技能)
    if enemy.SkillIDsBossWarning and #enemy.SkillIDsBossWarning > 0 then
        for _, skillId in ipairs(enemy.SkillIDsBossWarning) do
            AddSkill(skillId)
        end
    end

    -- 将 skillList 转换为与 ally_data.lua 相同的格式
    heroData.skills = {}
    for _, sid in ipairs(skillList) do
        table.insert(heroData.skills, {skillId = sid, level = 1})
    end
    
    heroData.skillsConfig = skillsConfig

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

--- 检查敌人是否有技能
-- @param enemy 敌人数据
-- @return boolean 是否有技能
local function EnemyHasSkills(enemy)
    if not enemy then return false end
    
    -- 检查 SkillIDs
    if enemy.SkillIDs then
        for _ in pairs(enemy.SkillIDs) do
            return true
        end
    end
    
    -- 检查 SkillIDsBossWarning
    if enemy.SkillIDsBossWarning then
        for _ in pairs(enemy.SkillIDsBossWarning) do
            return true
        end
    end
    
    return false
end

--- 获取指定怪物类型的敌人（只返回有技能的敌人）
-- @param monsterType 怪物类型 (0=普通, 1=精英, 2=BOSS)
-- @return 符合条件的敌人列表
function EnemyData.GetEnemiesByMonsterType(monsterType)
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.MonsterType == monsterType then
            -- 只添加有技能的敌人
            if EnemyHasSkills(enemy) then
                table.insert(result, enemy)
            end
        end
    end
    return result
end

--- 获取所有Boss ID列表（MonsterType=2，且有技能）
-- @return Boss ID列表
function EnemyData.GetAllBossIds()
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.MonsterType == 2 and EnemyHasSkills(enemy) then
            table.insert(result, id)
        end
    end
    return result
end

--- 获取所有普通敌人ID列表（MonsterType=0，且有技能）
-- @return 普通敌人ID列表
function EnemyData.GetAllNormalEnemyIds()
    EnemyData.Init()
    local result = {}
    for id, enemy in pairs(_enemyData) do
        if type(id) == "number" and enemy.MonsterType == 0 and EnemyHasSkills(enemy) then
            table.insert(result, id)
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
