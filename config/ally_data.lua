local JSON = require("utils.json")
local SkillData = require("config.skill_data")
local AllyData = {}

-- 配置目录路径（从bin目录运行时的相对路径）
local CONFIG_DIR = "../config/"

-- 内部数据存储
local allyInfoMap = {}      -- AllyID -> ally info
local allyLevelMap = {}     -- LevelId -> level info
local alliesByClass = {}    -- Class -> {ally1, ally2, ...}
local alliesByFaction = {}  -- Faction -> {ally1, ally2, ...}
local alliesByQuality = {}  -- Quality -> {ally1, ally2, ...}
local allAllies = {}        -- 所有盟友列表
local playableHeroes = {}   -- 玩家可用英雄列表 (IsHero = 1)

-- 品质倍率 (1-6星品质)
local QUALITY_MULTIPLIERS = {
    [1] = 1.0,   -- 普通
    [2] = 1.1,   -- 优秀
    [3] = 1.2,   -- 精良
    [4] = 1.35,  -- 史诗
    [5] = 1.5,   -- 传说
    [6] = 1.7,   -- 神话
}

-- 星级倍率 (每星增加15%)
local function GetStarMultiplier(star)
    return 1.0 + (star - 1) * 0.15
end

-- 属性ID常量定义 (对应原项目 HeroProxy.lua 中的 Attr 定义)
local ATTR_ID = {
    HP = 1,              -- 当前生命
    HP_BASE = 2,         -- 最大生命基础
    HP_RATE = 3,         -- 最大生命加成（百分比）
    EX_HP = 4,           -- 额外增加最大生命值
    HP_MAX = 5,          -- 最大生命
    ATK_BASE = 6,        -- 攻击基础
    ATK_RATE = 7,        -- 攻击加成(百分比)
    EX_ATK = 8,          -- 额外攻击
    ATK = 9,             -- 攻击
    DEF_BASE = 10,       -- 防御基础
    DEF_RATE = 11,       -- 防御加成（百分比）
    EX_DEF = 12,         -- 额外防御
    DEF = 13,            -- 防御
    MANA = 14,           -- 当前能量
    MANA_INIT = 15,      -- 初始能量
    MANA_MAX = 16,       -- 能量阈值
    MANA_GAIN_RATE = 17, -- 能量获取加成(百分比)
    SPD_BASE = 18,       -- 速度Base
    SKILL_CD_VALUE = 19, -- 技能cd减少固定值
    SKILL_CD_PERCENT = 20, -- 技能cd减少百分比
    CRIT_RATE = 21,      -- 爆击率(百分比)
    CRIT_DAMAGE = 22,    -- 爆击伤害加成（百分比）
    ANTI_CRIT_RATE = 23, -- 抗爆击率(百分比)
    HIT_RATE = 24,       -- 命中率(百分比)
    DODGE_RATE = 25,     -- 闪避率(百分比)
    BLOCK_RATE = 26,     -- 格挡率(百分比)
    BLOCK_DEEPEN = 27,   -- 格挡强度（百分比）
    ANTI_BLOCK_RATE = 28, -- 精准率（百分比）
    BREAK_DEF_RATE = 29, -- 破甲率（百分比）
    SPD_RATE = 101,      -- 速度Rate
    EX_SPD = 104,        -- 速度Ex
    SPD = 105,           -- 最终速度
}

-- 解析嵌套数组格式的技能数据
local function ParseSkillIDs(skillData)
    local skills = {}
    if skillData and skillData.array then
        for _, skillItem in ipairs(skillData.array) do
            if skillItem and skillItem.array and #skillItem.array >= 2 then
                table.insert(skills, {
                    skillId = skillItem.array[1],
                    level = skillItem.array[2]
                })
            end
        end
    end
    return skills
end

-- 解析属性数组
local function ParsePropArray(propData)
    local props = {}
    if propData and propData.array then
        for _, propItem in ipairs(propData.array) do
            if propItem and propItem.array and #propItem.array >= 2 then
                props[propItem.array[1]] = propItem.array[2]
            end
        end
    end
    return props
end

-- 加载 ally info 数据
local function LoadAllyInfo()
    local file = io.open(CONFIG_DIR .. "res_ally_info.json", "r")
    if not file then
        error("Failed to open res_ally_info.json")
        return
    end

    local content = file:read("*a")
    file:close()

    local data = JSON.JsonDecode(content)
    if not data then
        error("Failed to parse res_ally_info.json")
        return
    end

    for _, ally in ipairs(data) do
        -- 解析技能
        ally.ParsedSkills = ParseSkillIDs(ally.SkillIDs)
        ally.ParsedInitSkills = ParseSkillIDs(ally.InitializeSkills)
        ally.ParsedProps = ParsePropArray(ally.Prop)

        -- 存储到主映射表
        allyInfoMap[ally.AllyID] = ally
        table.insert(allAllies, ally)

        -- 按职业分类 (1=前排, 2=中排, 3=后排)
        if not alliesByClass[ally.Class] then
            alliesByClass[ally.Class] = {}
        end
        table.insert(alliesByClass[ally.Class], ally)

        -- 按阵营分类
        if not alliesByFaction[ally.Faction] then
            alliesByFaction[ally.Faction] = {}
        end
        table.insert(alliesByFaction[ally.Faction], ally)

        -- 按品质分类
        local quality = ally.BaseQuality or ally.Quality or 1
        if not alliesByQuality[quality] then
            alliesByQuality[quality] = {}
        end
        table.insert(alliesByQuality[quality], ally)

        -- 按是否可用英雄分类 (IsHero = 1 是玩家可用角色)
        if ally.IsHero == 1 then
            if not playableHeroes then playableHeroes = {} end
            table.insert(playableHeroes, ally)
        end
    end
end

-- 加载 ally level 数据
local function LoadAllyLevel()
    local file = io.open(CONFIG_DIR .. "res_ally_level.json", "r")
    if not file then
        error("Failed to open res_ally_level.json")
        return
    end

    local content = file:read("*a")
    file:close()

    local data = JSON.JsonDecode(content)
    if not data then
        error("Failed to parse res_ally_level.json")
        return
    end

    for _, levelInfo in ipairs(data) do
        local levelId = levelInfo.Level or levelInfo.LevelId
        if levelId then
            allyLevelMap[levelId] = levelInfo
        end
    end
end

-- 初始化
local function Init()
    LoadAllyInfo()
    LoadAllyLevel()
end

-- 获取盟友信息
function AllyData.GetAllyInfo(allyId)
    return allyInfoMap[allyId]
end

-- 获取等级信息
function AllyData.GetLevelInfo(level)
    return allyLevelMap[level]
end

-- 获取所有盟友
function AllyData.GetAllAllies()
    return allAllies
end

-- 获取可玩英雄列表
function AllyData.GetPlayableHeroes()
    return playableHeroes
end

-- 按职业获取盟友
function AllyData.GetAlliesByClass(class)
    return alliesByClass[class] or {}
end

-- 按阵营获取盟友
function AllyData.GetAlliesByFaction(faction)
    return alliesByFaction[faction] or {}
end

-- 按品质获取盟友
function AllyData.GetAlliesByQuality(quality)
    return alliesByQuality[quality] or {}
end

-- 获取盟友名称
function AllyData.GetAllyName(allyId)
    local ally = allyInfoMap[allyId]
    if ally then
        -- 配置中没有Name字段，使用AllyID作为名称
        return ally.Name or ("Hero_" .. tostring(allyId))
    end
    return "Unknown"
end

-- 计算英雄属性
function AllyData.CalculateHeroAttributes(allyId, level, star)
    local ally = allyInfoMap[allyId]
    if not ally then
        return nil
    end

    local levelInfo = allyLevelMap[level]
    if not levelInfo then
        return nil
    end

    -- 基础属性 (使用配置中的基础数值)
    local baseHp = ally.HpBaseNum or 1000
    local baseAtk = ally.AtkBaseNum or 100
    local baseDef = ally.DefBaseNum or 50
    local baseSpd = 100  -- 默认速度

    -- 品质 (1-6，用于索引成长数组)
    local quality = ally.BaseQuality or ally.Quality or 1
    local qualityIndex = math.min(6, math.max(1, quality))

    -- 等级成长 (从配置数组中获取对应品质的成长值)
    local hpGrowth = levelInfo.LevelBaseHp and levelInfo.LevelBaseHp[qualityIndex] or 0
    local atkGrowth = levelInfo.LevelBaseAtk and levelInfo.LevelBaseAtk[qualityIndex] or 0
    local defGrowth = levelInfo.LevelBaseDef and levelInfo.LevelBaseDef[qualityIndex] or 0

    -- 星级倍率
    local starMultiplier = GetStarMultiplier(star)

    -- 最终属性 = 基础属性 + 等级成长 + 星级加成
    local finalHp = math.floor((baseHp + hpGrowth) * starMultiplier)
    local finalAtk = math.floor((baseAtk + atkGrowth) * starMultiplier)
    local finalDef = math.floor((baseDef + defGrowth) * starMultiplier)
    local finalSpd = baseSpd

    return {
        hp = finalHp,
        maxHp = finalHp,
        atk = finalAtk,
        def = finalDef,
        spd = finalSpd,
        level = level,
        star = star,
        quality = quality,
        class = ally.Class,
        faction = ally.Faction
    }
end

-- 根据英雄等级计算技能等级
local function CalculateSkillLevel(heroLevel)
    -- 技能等级 = 英雄等级 // 10 + 1，最大为5级
    return math.min(5, math.floor(heroLevel / 10) + 1)
end

-- 获取指定ClassID和等级的技能，如果不存在则降级查找
local function GetSkillByClassAndLevel(classId, level)
    -- 从指定等级开始向下查找，直到找到存在的技能
    for l = level, 1, -1 do
        local skillId = classId * 100 + l
        local skill = SkillData.GetSkill(skillId)
        if skill then
            return skill
        end
    end
    return nil
end

-- 转换为战斗使用的英雄数据格式
function AllyData.ConvertToHeroData(allyId, level, star)
    local ally = allyInfoMap[allyId]
    if not ally then
        return nil
    end

    local attrs = AllyData.CalculateHeroAttributes(allyId, level, star)
    if not attrs then
        return nil
    end

    -- 构建技能配置 (根据英雄等级选择合适的技能等级)
    local skillsConfig = {}
    local relationConfigId = ally.RelationConfigID or allyId
    local skillLevel = CalculateSkillLevel(level)
    
    -- 查询多个ClassID，但只选择对应等级的技能
    -- 技能ID格式: classId * 100 + level，如 131840101 表示 classId=1318401, level=1
    for i = 1, 5 do
        local skillClassId = relationConfigId * 100 + i
        -- 获取技能，如果不存在则降级查找
        local skill = GetSkillByClassAndLevel(skillClassId, skillLevel)
        
        if skill then
            table.insert(skillsConfig, {
                skillId = skill.ID,
                skillType = skill.Type,
                name = skill.Name,
                skillCost = skill.Type == 2 and 100 or 0
            })
        end
    end

    -- 构建英雄数据
    local heroData = {
        id = allyId,
        modelId = ally.ModelID,
        name = AllyData.GetAllyName(allyId),
        level = level,
        star = star,
        quality = attrs.quality,
        class = ally.Class,
        faction = ally.Faction,
        atk = attrs.atk,
        def = attrs.def,
        hp = attrs.hp,
        maxHp = attrs.maxHp,
        spd = attrs.spd,
        skillsConfig = skillsConfig,
        -- 保留原始配置数据
        config = ally
    }

    return heroData
end

-- 自动初始化
Init()

return AllyData
