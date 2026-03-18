local JSON = require("utils.json")
local AllyData = {}

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
    local file = io.open("config/res_ally_info.json", "r")
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
    local file = io.open("config/res_ally_level.json", "r")
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
        allyLevelMap[levelInfo.LevelId] = levelInfo
    end
end

-- 初始化模块
function AllyData.Init()
    LoadAllyInfo()
    LoadAllyLevel()
end

-- 获取指定ID的盟友
function AllyData.GetAlly(allyId)
    return allyInfoMap[allyId]
end

-- 获取盟友名称 (根据ModelID生成)
function AllyData.GetAllyName(allyId)
    local ally = allyInfoMap[allyId]
    if not ally then
        return nil
    end
    return string.format("Hero_%d", ally.ModelID)
end

-- 获取指定职业的所有盟友 (1=前排, 2=中排, 3=后排)
function AllyData.GetAlliesByClass(class)
    return alliesByClass[class] or {}
end

-- 获取指定阵营的所有盟友
function AllyData.GetAlliesByFaction(faction)
    return alliesByFaction[faction] or {}
end

-- 获取指定品质的所有盟友 (1-6)
function AllyData.GetAlliesByQuality(quality)
    return alliesByQuality[quality] or {}
end

-- 获取所有盟友
function AllyData.GetAllAllies()
    return allAllies
end

-- 获取所有玩家可用英雄 (IsHero = 1)
function AllyData.GetPlayableHeroes()
    return playableHeroes
end

-- 获取玩家可用英雄数量
function AllyData.GetPlayableHeroCount()
    return #playableHeroes
end

-- 按职业获取玩家可用英雄
function AllyData.GetPlayableHeroesByClass(class)
    local result = {}
    for _, hero in ipairs(playableHeroes) do
        if hero.Class == class then
            table.insert(result, hero)
        end
    end
    return result
end

-- 按品质获取玩家可用英雄
function AllyData.GetPlayableHeroesByQuality(quality)
    local result = {}
    for _, hero in ipairs(playableHeroes) do
        if (hero.BaseQuality or hero.Quality or 1) == quality then
            table.insert(result, hero)
        end
    end
    return result
end

-- 获取等级成长数据
function AllyData.GetLevelData(level)
    return allyLevelMap[level]
end

-- 获取职业名称
function AllyData.GetClassName(class)
    local classNames = {
        [1] = "前排",
        [2] = "中排",
        [3] = "后排"
    }
    return classNames[class] or "未知"
end

-- 获取阵营名称
function AllyData.GetFactionName(faction)
    local factionNames = {
        [1] = "阵营1",
        [2] = "阵营2",
        [3] = "阵营3"
    }
    return factionNames[faction] or "未知"
end

-- 获取品质名称
function AllyData.GetQualityName(quality)
    local qualityNames = {
        [1] = "普通",
        [2] = "优秀",
        [3] = "精良",
        [4] = "史诗",
        [5] = "传说",
        [6] = "神话"
    }
    return qualityNames[quality] or "未知"
end

-- 转换盟友配置为战斗用英雄数据
function AllyData.ConvertToHeroData(allyId, level, star)
    local ally = allyInfoMap[allyId]
    if not ally then
        return nil
    end

    level = level or 1
    star = star or ally.DefaultStar or 1

    -- 获取等级成长数据
    local levelData = allyLevelMap[level]
    local levelAtk = 0
    local levelDef = 0
    local levelHp = 0

    if levelData then
        -- LevelBaseAtk/Def/Hp 是数组，根据品质索引获取
        local qualityIndex = ally.BaseQuality or 1
        levelAtk = levelData.LevelBaseAtk[qualityIndex] or 0
        levelDef = levelData.LevelBaseDef[qualityIndex] or 0
        levelHp = levelData.LevelBaseHp[qualityIndex] or 0
    end

    -- 计算基础属性
    local baseAtk = ally.AtkBaseNum or 0
    local baseDef = ally.DefBaseNum or 0
    local baseHp = ally.HpBaseNum or 0

    -- 获取品质倍率
    local quality = ally.BaseQuality or 1
    local qualityMult = QUALITY_MULTIPLIERS[quality] or 1.0

    -- 获取星级倍率
    local starMult = GetStarMultiplier(star)

    -- 获取属性比例 (百分比，需要除以10000)
    local atkRatio = (ally.AtkBaseRadio or 10000) / 10000
    local defRatio = (ally.DefBaseRadio or 10000) / 10000
    local hpRatio = (ally.HpBaseRadio or 10000) / 10000

    -- 计算最终属性
    local finalAtk = math.floor((baseAtk + levelAtk) * atkRatio * qualityMult * starMult)
    local finalDef = math.floor((baseDef + levelDef) * defRatio * qualityMult * starMult)
    local finalHp = math.floor((baseHp + levelHp) * hpRatio * qualityMult * starMult)

    -- 从 Prop 数组获取所有额外属性
    local props = ally.ParsedProps or {}

    -- 基础属性（从Prop读取，如果没有则使用默认值）
    local spd = props[ATTR_ID.SPD_BASE] or 100  -- 速度基础值，默认100
    local critRate = props[ATTR_ID.CRIT_RATE] or 0
    local critDamage = props[ATTR_ID.CRIT_DAMAGE] or 5000  -- 默认150%暴击伤害 (5000/10000 + 1)
    local hitRate = props[ATTR_ID.HIT_RATE] or 10000  -- 默认100%命中
    local dodgeRate = props[ATTR_ID.DODGE_RATE] or 0
    local blockRate = props[ATTR_ID.BLOCK_RATE] or 0
    local manaInit = props[ATTR_ID.MANA_INIT] or 0  -- 初始能量

    -- 读取其他可能的属性（如152, 153, 171, 181等特殊属性）
    local extraProps = {}
    for attrId, value in pairs(props) do
        -- 只读取不在ATTR_ID中定义的属性（即特殊属性）
        local isStandardAttr = false
        for _, stdId in pairs(ATTR_ID) do
            if attrId == stdId then
                isStandardAttr = true
                break
            end
        end
        if not isStandardAttr then
            extraProps[attrId] = value
        end
    end

    -- 构建技能列表
    local skills = {}
    for _, skill in ipairs(ally.ParsedSkills or {}) do
        table.insert(skills, {
            id = skill.skillId,
            level = skill.level
        })
    end

    -- 构建英雄数据
    local heroData = {
        id = allyId,
        modelId = ally.ModelID,
        name = AllyData.GetAllyName(allyId),
        level = level,
        star = star,
        quality = quality,
        class = ally.Class,
        faction = ally.Faction,
        atk = finalAtk,
        def = finalDef,
        hp = finalHp,
        maxHp = finalHp,
        spd = spd,
        crt = critRate,      -- 暴击率 (百分比，如5000表示50%)
        crtd = critDamage,   -- 暴击伤害加成
        hit = hitRate,       -- 命中率
        res = dodgeRate,     -- 闪避率
        blk = blockRate,     -- 格挡率
        mana = manaInit,     -- 初始能量
        skills = skills,
        -- 保留原始配置数据
        config = ally,
        -- 保留原始属性映射
        props = props,
        -- 保留额外属性（如152, 153, 171, 181等特殊属性）
        extraProps = extraProps
    }

    return heroData
end

-- 批量转换多个盟友
function AllyData.ConvertAlliesToHeroData(allyList)
    local heroes = {}
    for _, info in ipairs(allyList) do
        local hero = AllyData.ConvertToHeroData(info.allyId, info.level, info.star)
        if hero then
            table.insert(heroes, hero)
        end
    end
    return heroes
end

-- 打印盟友信息 (调试用)
function AllyData.PrintAllyInfo(allyId)
    local ally = allyInfoMap[allyId]
    if not ally then
        print(string.format("Ally %d not found", allyId))
        return
    end

    print(string.format("=== Ally %d Info ===", allyId))
    print(string.format("ModelID: %d", ally.ModelID))
    print(string.format("Class: %d (%s)", ally.Class, AllyData.GetClassName(ally.Class)))
    print(string.format("Faction: %d", ally.Faction))
    print(string.format("Quality: %d (%s)", ally.BaseQuality or 1, AllyData.GetQualityName(ally.BaseQuality)))
    print(string.format("DefaultStar: %d, FinalStar: %d", ally.DefaultStar or 1, ally.FinalStar or 1))
    print(string.format("Base Stats - ATK: %d, DEF: %d, HP: %d", ally.AtkBaseNum or 0, ally.DefBaseNum or 0, ally.HpBaseNum or 0))
    print(string.format("Base Ratios - ATK: %.2f%%, DEF: %.2f%%, HP: %.2f%%",
        (ally.AtkBaseRadio or 10000) / 100,
        (ally.DefBaseRadio or 10000) / 100,
        (ally.HpBaseRadio or 10000) / 100))

    print("Skills:")
    for _, skill in ipairs(ally.ParsedSkills or {}) do
        print(string.format("  - SkillID: %d, Level: %d", skill.skillId, skill.level))
    end
end

-- 自动初始化
AllyData.Init()

return AllyData
