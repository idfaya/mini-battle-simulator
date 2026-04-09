---
--- Battle Attribute Module
--- 管理战斗英雄的属性系统，包括基础属性、Buff/装备加成、HP管理等
---

local Logger = require("utils.logger")

---@class BattleAttribute
local BattleAttribute = {}

-- 属性ID定义
BattleAttribute.ATTR_ID = {
    HP = 1,         -- 生命值
    ATK = 2,        -- 攻击力
    DEF = 3,        -- 防御力
    SPEED = 4,      -- 速度
    CRIT_RATE = 5,  -- 暴击率
    CRIT_DMG = 6,   -- 暴击伤害
    HIT_RATE = 7,   -- 命中率
    DODGE_RATE = 8, -- 闪避率
    DMG_REDUCE = 9, -- 伤害减免
    DMG_INCREASE = 10, -- 伤害加成
}

-- 属性名称映射
local ATTR_NAME_MAP = {
    [1] = "hp",
    [2] = "atk",
    [3] = "def",
    [4] = "speed",
    [5] = "critRate",
    [6] = "critDamage",
    [7] = "hitRate",
    [8] = "dodgeRate",
    [9] = "damageReduce",
    [10] = "damageIncrease",
}

-- 属性默认值
local ATTR_DEFAULT_VALUE = {
    [1] = 100,   -- HP
    [2] = 10,    -- ATK
    [3] = 5,     -- DEF
    [4] = 100,   -- SPEED
    [5] = 0,     -- CRIT_RATE
    [6] = 150,   -- CRIT_DMG
    [7] = 100,   -- HIT_RATE
    [8] = 0,     -- DODGE_RATE
    [9] = 0,     -- DMG_REDUCE
    [10] = 0,    -- DMG_INCREASE
}

--- 获取属性字段名
---@param attrId number 属性ID
---@return string|nil 属性字段名
local function GetAttrFieldName(attrId)
    return ATTR_NAME_MAP[attrId]
end

--- 获取属性默认值
---@param attrId number 属性ID
---@return number 默认值
local function GetAttrDefaultValue(attrId)
    return ATTR_DEFAULT_VALUE[attrId] or 0
end

--- 初始化英雄属性
---@param hero table 英雄对象 (可选，不传则为模块初始化)
---@param attributeMap table 属性映射表 { [attrId] = value, ... }
function BattleAttribute.Init(hero, attributeMap)
    -- 如果没有传入hero，只是模块初始化，直接返回
    if not hero then
        -- 模块级初始化，无需处理
        return
    end

    -- 初始化属性存储结构
    hero.attributes = {
        base = {},      -- 基础属性
        bonus = {},     -- 加成属性 (来自Buff/装备等)
        final = {},     -- 最终计算后的属性
    }

    -- 设置基础属性
    attributeMap = attributeMap or {}
    for attrId, value in pairs(attributeMap) do
        hero.attributes.base[attrId] = value
    end

    -- 确保必要属性有默认值
    for attrId = 1, 10 do
        if not hero.attributes.base[attrId] then
            hero.attributes.base[attrId] = GetAttrDefaultValue(attrId)
        end
    end

    -- 初始化当前HP和最大HP
    local maxHp = hero.attributes.base[BattleAttribute.ATTR_ID.HP] or 100
    hero.maxHp = maxHp
    hero.hp = hero.hp or maxHp

    -- 初始化其他基础字段
    hero.atk = hero.attributes.base[BattleAttribute.ATTR_ID.ATK] or 0
    hero.def = hero.attributes.base[BattleAttribute.ATTR_ID.DEF] or 0
    hero.speed = hero.attributes.base[BattleAttribute.ATTR_ID.SPEED] or 0

    -- 重新计算所有属性
    BattleAttribute.UpdateHeroAttribute(hero)

    Logger.Debug(string.format("BattleAttribute.Init - 英雄 %s 属性初始化完成, 最大HP: %d", 
        hero.name or "Unknown", hero.maxHp))
end

--- 获取英雄当前HP
---@param hero table 英雄对象
---@return number 当前HP
function BattleAttribute.GetHeroCurHp(hero)
    if not hero then
        return 0
    end
    return hero.hp or 0
end

--- 获取英雄最大HP
---@param hero table 英雄对象
---@return number 最大HP
function BattleAttribute.GetHeroMaxHp(hero)
    if not hero then
        return 0
    end
    return hero.maxHp or 100
end

--- 设置英雄HP为指定值
---@param hero table 英雄对象
---@param value number 要设置的HP值
function BattleAttribute.SetHpByVal(hero, value)
    if not hero then
        return
    end

    local oldHp = hero.hp or 0
    local maxHp = hero.maxHp or 100

    -- 限制HP范围 [0, maxHp]
    hero.hp = math.max(0, math.min(value, maxHp))

    -- 更新存活状态
    hero.isAlive = hero.hp > 0
    hero.isDead = hero.hp <= 0

    Logger.Debug(string.format("BattleAttribute.SetHpByVal - 英雄 %s HP: %d -> %d", 
        hero.name or "Unknown", oldHp, hero.hp))

    -- 如果HP变为0，触发死亡状态
    if hero.hp <= 0 and oldHp > 0 then
        Logger.Log(string.format("英雄 %s HP归零，进入死亡状态", hero.name or "Unknown"))
    end
end

--- 设置英雄HP为最大HP的百分比
---@param hero table 英雄对象
---@param percent number 百分比 (0-100)
function BattleAttribute.SetHpByPercent(hero, percent)
    if not hero then
        return
    end

    local maxHp = hero.maxHp or 100
    local targetHp = maxHp * (percent / 100)
    BattleAttribute.SetHpByVal(hero, targetHp)
end

--- 获取指定属性的值
---@param hero table 英雄对象
---@param attrId number 属性ID
---@return number 属性值
function BattleAttribute.GetAttribute(hero, attrId)
    if not hero then
        return GetAttrDefaultValue(attrId)
    end

    -- 如果存在 attributes 结构，优先使用
    if hero.attributes then
        -- 优先返回最终计算值
        if hero.attributes.final and hero.attributes.final[attrId] then
            return hero.attributes.final[attrId]
        end

        -- 返回基础值
        if hero.attributes.base and hero.attributes.base[attrId] then
            return hero.attributes.base[attrId]
        end
    end

    -- 如果没有 attributes 结构，检查直接属性字段
    local fieldName = GetAttrFieldName(attrId)
    if fieldName and hero[fieldName] then
        return hero[fieldName]
    end

    -- 返回默认值
    return GetAttrDefaultValue(attrId)
end

--- 设置指定属性的基础值
---@param hero table 英雄对象
---@param attrId number 属性ID
---@param value number 属性值
function BattleAttribute.SetAttribute(hero, attrId, value)
    if not hero or not hero.attributes then
        return
    end

    hero.attributes.base[attrId] = value

    -- 如果是HP属性，同步更新maxHp
    if attrId == BattleAttribute.ATTR_ID.HP then
        hero.maxHp = value
    end

    -- 重新计算属性
    BattleAttribute.UpdateHeroAttribute(hero)

    Logger.Debug(string.format("BattleAttribute.SetAttribute - 英雄 %s 属性 %d 设置为 %d", 
        hero.name or "Unknown", attrId, value))
end

--- 修改指定属性值 (增加或减少)
---@param hero table 英雄对象
---@param attrId number 属性ID
---@param delta number 变化量 (可为负数)
function BattleAttribute.ModifyAttribute(hero, attrId, delta)
    if not hero or not hero.attributes then
        return
    end

    local oldValue = hero.attributes.base[attrId] or GetAttrDefaultValue(attrId)
    local newValue = oldValue + delta

    BattleAttribute.SetAttribute(hero, attrId, newValue)

    Logger.Debug(string.format("BattleAttribute.ModifyAttribute - 英雄 %s 属性 %d: %d %+d = %d", 
        hero.name or "Unknown", attrId, oldValue, delta, newValue))
end

--- 添加属性加成 (来自Buff/装备等)
---@param hero table 英雄对象
---@param attrId number 属性ID
---@param bonus number 加成值
---@param source string 加成来源标识
function BattleAttribute.AddAttributeBonus(hero, attrId, bonus, source)
    if not hero or not hero.attributes then
        return
    end

    source = source or "unknown"
    hero.attributes.bonus[source] = hero.attributes.bonus[source] or {}
    hero.attributes.bonus[source][attrId] = bonus

    -- 重新计算属性
    BattleAttribute.UpdateHeroAttribute(hero)

    Logger.Debug(string.format("BattleAttribute.AddAttributeBonus - 英雄 %s 从 %s 获得属性 %d 加成 %+d", 
        hero.name or "Unknown", source, attrId, bonus))
end

--- 移除属性加成
---@param hero table 英雄对象
---@param source string 加成来源标识
function BattleAttribute.RemoveAttributeBonus(hero, source)
    if not hero or not hero.attributes then
        return
    end

    if hero.attributes.bonus[source] then
        hero.attributes.bonus[source] = nil

        -- 重新计算属性
        BattleAttribute.UpdateHeroAttribute(hero)

        Logger.Debug(string.format("BattleAttribute.RemoveAttributeBonus - 英雄 %s 移除来源 %s 的属性加成", 
            hero.name or "Unknown", source))
    end
end

--- 重新计算英雄所有属性
---@param hero table 英雄对象
function BattleAttribute.UpdateHeroAttribute(hero)
    if not hero or not hero.attributes then
        return
    end

    -- 计算每个属性的最终值
    for attrId = 1, 10 do
        local baseValue = hero.attributes.base[attrId] or GetAttrDefaultValue(attrId)
        local totalBonus = 0

        -- 累加所有来源的加成
        for source, bonuses in pairs(hero.attributes.bonus) do
            if bonuses[attrId] then
                totalBonus = totalBonus + bonuses[attrId]
            end
        end

        -- 最终值 = 基础值 + 加成
        hero.attributes.final[attrId] = baseValue + totalBonus
    end

    -- 更新maxHp (基于HP属性)
    local oldMaxHp = hero.maxHp
    hero.maxHp = hero.attributes.final[BattleAttribute.ATTR_ID.HP] or 100

    -- 如果maxHp增加，按比例增加当前HP
    if hero.maxHp > oldMaxHp and oldMaxHp > 0 then
        local hpPercent = (hero.hp or 0) / oldMaxHp
        hero.hp = hero.maxHp * hpPercent
    end

    -- 确保当前HP不超过最大值
    if hero.hp and hero.hp > hero.maxHp then
        hero.hp = hero.maxHp
    end

    -- 同步常用字段
    hero.atk = hero.attributes.final[BattleAttribute.ATTR_ID.ATK] or 0
    hero.def = hero.attributes.final[BattleAttribute.ATTR_ID.DEF] or 0
    hero.speed = hero.attributes.final[BattleAttribute.ATTR_ID.SPEED] or 0
    hero.critRate = hero.attributes.final[BattleAttribute.ATTR_ID.CRIT_RATE] or 0
    hero.critDamage = hero.attributes.final[BattleAttribute.ATTR_ID.CRIT_DMG] or 150
    hero.hitRate = hero.attributes.final[BattleAttribute.ATTR_ID.HIT_RATE] or 100
    hero.dodgeRate = hero.attributes.final[BattleAttribute.ATTR_ID.DODGE_RATE] or 0
    hero.damageReduce = hero.attributes.final[BattleAttribute.ATTR_ID.DMG_REDUCE] or 0
    hero.damageIncrease = hero.attributes.final[BattleAttribute.ATTR_ID.DMG_INCREASE] or 0

    -- 更新存活状态
    hero.isAlive = (hero.hp or 0) > 0
    hero.isDead = not hero.isAlive
end

--- 检查英雄是否存活
---@param hero table 英雄对象
---@return boolean 是否存活
function BattleAttribute.IsAlive(hero)
    if not hero then
        return false
    end
    return (hero.hp or 0) > 0
end

--- 获取英雄速度 (用于行动顺序计算)
---@param hero table 英雄对象
---@return number 速度值
function BattleAttribute.GetSpeed(hero)
    if not hero then
        return 0
    end

    local BattleBuff = require("modules.battle_buff")

    local speed = 0
    if hero.attributes and hero.attributes.final[BattleAttribute.ATTR_ID.SPEED] then
        speed = hero.attributes.final[BattleAttribute.ATTR_ID.SPEED]
    else
        speed = hero.spd or hero.speed or 0
    end
    local slowPct = BattleBuff.GetBuffStackNumBySubType(hero, 880001)
    local warSpiritPct = BattleBuff.GetBuffStackNumBySubType(hero, 840001) * 500
    local auraSpdPct = 0
    if BattleBuff.GetBuffBySubType(hero, 840003) then
        auraSpdPct = 5000
    end
    local speedBuffPct = warSpiritPct + auraSpdPct - slowPct
    return math.max(0, math.floor(speed * (1 + speedBuffPct / 10000)))
end

--- 获取英雄所有属性信息 (用于调试)
---@param hero table 英雄对象
---@return table 属性信息表
function BattleAttribute.GetAllAttributes(hero)
    if not hero or not hero.attributes then
        return {}
    end

    return {
        base = table.shallow_copy(hero.attributes.base),
        bonus = table.shallow_copy(hero.attributes.bonus),
        final = table.shallow_copy(hero.attributes.final),
        curHp = hero.hp,
        maxHp = hero.maxHp,
        isAlive = hero.isAlive,
    }
end

--- 重置英雄属性 (清除所有加成)
---@param hero table 英雄对象
function BattleAttribute.ResetAttributes(hero)
    if not hero or not hero.attributes then
        return
    end

    -- 清除所有加成
    hero.attributes.bonus = {}

    -- 重新计算
    BattleAttribute.UpdateHeroAttribute(hero)

    Logger.Debug(string.format("BattleAttribute.ResetAttributes - 英雄 %s 属性已重置", 
        hero.name or "Unknown"))
end

--- 复制英雄属性
---@param sourceHero table 源英雄
---@param targetHero table 目标英雄
function BattleAttribute.CopyAttributes(sourceHero, targetHero)
    if not sourceHero or not targetHero then
        return
    end

    -- 初始化目标英雄属性结构
    targetHero.attributes = {
        base = table.shallow_copy(sourceHero.attributes.base or {}),
        bonus = {},
        final = {},
    }

    -- 复制加成
    for source, bonuses in pairs(sourceHero.attributes.bonus or {}) do
        targetHero.attributes.bonus[source] = table.shallow_copy(bonuses)
    end

    -- 复制HP
    targetHero.maxHp = sourceHero.maxHp
    targetHero.hp = sourceHero.hp

    -- 重新计算
    BattleAttribute.UpdateHeroAttribute(targetHero)

    Logger.Debug(string.format("BattleAttribute.CopyAttributes - 从 %s 复制属性到 %s", 
        sourceHero.name or "Unknown", targetHero.name or "Unknown"))
end

--- 清理模块
function BattleAttribute.OnFinal()
    Logger.Log("[BattleAttribute.OnFinal] 属性模块清理")
end

return BattleAttribute
