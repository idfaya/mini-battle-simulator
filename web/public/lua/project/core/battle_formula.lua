---
--- Battle Formula Module
--- 战斗公式计算模块
---

local BattleFormula = {}

-- 公式类型
BattleFormula.FORMULA_TYPE = {
    STANDARD = 1,  -- 标准公式
    PVP = 2,       -- PVP公式
    PVE = 3,       -- PVE公式
}

-- 默认配置
local DEFAULT_CONFIG = {
    -- 暴击伤害倍率
    critDamageMultiplier = 1.5,
    -- 格挡减伤比例
    blockDamageReduction = 0.5,
    -- 最小伤害值
    minDamage = 1,
    -- 最大暴击率 (万分比)
    maxCritRate = 10000,
    -- 最大格挡率 (万分比)
    maxBlockRate = 10000,
    -- 属性类型
    attrType = {
        ATK = 1,    -- 攻击
        DEF = 2,    -- 防御
        HP = 3,     -- 生命
        CRIT = 4,   -- 暴击
        BLOCK = 5,  -- 格挡
    },
    -- 伤害类型加成
    damageTypeBonus = {
        [E_ATTACK_TYPE.Physical] = {  -- 物理伤害
            vsPhysicalDef = 1.0,
        },
        [E_ATTACK_TYPE.Magic] = {     -- 魔法伤害
            vsMagicDef = 1.0,
        },
    },
}

-- 当前配置
local currentConfig = nil
local currentFormulaType = nil

--- 初始化公式模块
--- @param formulaType number 公式类型 (BattleFormula.FORMULA_TYPE)
function BattleFormula.Init(formulaType)
    currentFormulaType = formulaType or BattleFormula.FORMULA_TYPE.STANDARD
    currentConfig = DEFAULT_CONFIG
    
    -- 根据公式类型调整配置
    if currentFormulaType == BattleFormula.FORMULA_TYPE.PVP then
        -- PVP公式调整
        currentConfig.critDamageMultiplier = 1.3
    elseif currentFormulaType == BattleFormula.FORMULA_TYPE.PVE then
        -- PVE公式调整
        currentConfig.critDamageMultiplier = 1.5
    end
end

--- 获取单位属性值
--- @param unit table 单位数据
--- @param attrType number 属性类型
--- @return number 属性值
local function GetUnitAttr(unit, attrType)
    if not unit then
        return 0
    end
    
    -- 优先检查 attrs 字段 (原工程格式)
    if unit.attrs then
        return unit.attrs[attrType] or 0
    end
    
    -- 优先检查直接字段 (BattleAttribute模块设置，包含所有加成)
    if attrType == currentConfig.attrType.ATK then
        return unit.atk or 0
    elseif attrType == currentConfig.attrType.DEF then
        return unit.def or 0
    elseif attrType == currentConfig.attrType.HP then
        return unit.maxHp or 0
    elseif attrType == currentConfig.attrType.SPEED then
        return unit.speed or 0
    elseif attrType == currentConfig.attrType.CRIT then
        return unit.critRate or 0
    elseif attrType == currentConfig.attrType.CRIT_DAMAGE then
        return unit.critDamage or 0
    end
    
    -- 兼容 attributes 字段 (基础属性，不含加成)
    if unit.attributes and unit.attributes.base then
        return unit.attributes.base[attrType] or 0
    end
    
    return 0
end

--- 检查是否暴击
--- @param critRate number 暴击率 (万分比，如 3000 表示 30%)
--- @return boolean 是否暴击
function BattleFormula.CheckCrit(critRate)
    -- 确保已初始化
    if not currentConfig then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
    
    -- 限制暴击率范围
    local rate = math.min(critRate or 0, currentConfig.maxCritRate)
    rate = math.max(rate, 0)
    
    -- 使用 BattleMath 进行随机判定
    if BattleMath then
        return BattleMath.RandomCheck(rate, currentConfig.maxCritRate)
    else
        -- 备用方案：使用 Lua 的 math.random
        local randomValue = math.random(1, currentConfig.maxCritRate)
        return randomValue <= rate
    end
end

--- 检查是否格挡
--- @param blockRate number 格挡率 (万分比，如 2000 表示 20%)
--- @return boolean 是否格挡
function BattleFormula.CheckBlock(blockRate)
    -- 确保已初始化
    if not currentConfig then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
    
    -- 限制格挡率范围
    local rate = math.min(blockRate or 0, currentConfig.maxBlockRate)
    rate = math.max(rate, 0)
    
    -- 使用 BattleMath 进行随机判定
    if BattleMath then
        return BattleMath.RandomCheck(rate, currentConfig.maxBlockRate)
    else
        -- 备用方案：使用 Lua 的 math.random
        local randomValue = math.random(1, currentConfig.maxBlockRate)
        return randomValue <= rate
    end
end

--- 计算基础伤害
--- @param attacker table 攻击者数据
--- @param defender table 防御者数据
--- @param skillDamageRate number 技能伤害倍率 (万分比，如 10000 表示 100%)
--- @param damageType number 伤害类型 (E_ATTACK_TYPE)
--- @return number 基础伤害值
local function CalcBaseDamage(attacker, defender, skillDamageRate, damageType)
    -- 获取攻击者攻击力
    local atk = GetUnitAttr(attacker, currentConfig.attrType.ATK)
    
    -- 获取防御者防御力
    local def = GetUnitAttr(defender, currentConfig.attrType.DEF)
    
    -- 基础伤害公式：(攻击 - 防御) * 技能倍率 / 10000
    local baseDamage = (atk - def) * (skillDamageRate or 10000) / 10000
    
    -- 确保最小伤害
    baseDamage = math.max(baseDamage, currentConfig.minDamage)
    
    return math.floor(baseDamage)
end

--- 计算最终伤害
--- @param baseDamage number 基础伤害值
--- @param attacker table 攻击者数据
--- @param defender table 防御者数据
--- @param damageType number 伤害类型 (E_ATTACK_TYPE)
--- @return number 最终伤害值
function BattleFormula.CalcFinalDamage(baseDamage, attacker, defender, damageType)
    -- 确保已初始化
    if not currentConfig then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
    
    local finalDamage = baseDamage
    
    -- 应用伤害类型加成
    if damageType and currentConfig.damageTypeBonus[damageType] then
        local bonus = currentConfig.damageTypeBonus[damageType]
        -- 这里可以根据攻击类型和防御类型计算加成
        -- 例如：物理攻击对物理防御、魔法攻击对魔法防御等
    end
    
    -- 应用攻击者伤害加成 (如果有)
    if attacker and attacker.damageBonus then
        finalDamage = finalDamage * (1 + attacker.damageBonus / 10000)
    end
    
    -- 应用防御者伤害减免 (如果有)
    if defender and defender.damageReduction then
        finalDamage = finalDamage * (1 - defender.damageReduction / 10000)
    end
    
    -- 确保最小伤害
    finalDamage = math.max(finalDamage, currentConfig.minDamage)
    
    return math.floor(finalDamage)
end

--- 计算伤害
--- @param attacker table 攻击者数据 { attrs = {ATK, CRIT, ...}, damageBonus }
--- @param defender table 防御者数据 { attrs = {DEF, BLOCK, ...}, damageReduction }
--- @param skillDamageRate number 技能伤害倍率 (万分比)
--- @param damageType number 伤害类型 (E_ATTACK_TYPE.Physical 或 E_ATTACK_TYPE.Magic)
--- @param isCrit boolean 是否强制暴击 (nil 则自动判定)
--- @return table 伤害结果 { damage = number, isCrit = boolean, isBlock = boolean }
function BattleFormula.CalcDamage(attacker, defender, skillDamageRate, damageType, isCrit)
    -- 确保已初始化
    if not currentConfig then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
    
    -- 参数默认值
    skillDamageRate = skillDamageRate or 10000
    damageType = damageType or E_ATTACK_TYPE.Physical
    
    -- 计算基础伤害
    local baseDamage = CalcBaseDamage(attacker, defender, skillDamageRate, damageType)
    
    -- 判定是否暴击
    local crit = false
    if isCrit ~= nil then
        crit = isCrit
    else
        local critRate = GetUnitAttr(attacker, currentConfig.attrType.CRIT)
        crit = BattleFormula.CheckCrit(critRate)
    end
    
    -- 应用暴击伤害
    if crit then
        baseDamage = baseDamage * currentConfig.critDamageMultiplier
    end
    
    -- 判定是否格挡
    local block = false
    local blockRate = GetUnitAttr(defender, currentConfig.attrType.BLOCK)
    block = BattleFormula.CheckBlock(blockRate)
    
    -- 应用格挡减伤
    if block then
        baseDamage = baseDamage * (1 - currentConfig.blockDamageReduction)
    end
    
    -- 计算最终伤害
    local finalDamage = BattleFormula.CalcFinalDamage(baseDamage, attacker, defender, damageType)
    
    return {
        damage = finalDamage,
        isCrit = crit,
        isBlock = block,
    }
end

--- 计算治疗量
--- @param caster table 施法者数据 { attrs = {ATK, ...} }
--- @param target table 目标数据
--- @param healRate number 治疗倍率 (万分比，如 5000 表示 50%)
--- @return number 治疗量
function BattleFormula.CalcHeal(caster, target, healRate)
    -- 确保已初始化
    if not currentConfig then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
    
    -- 参数默认值
    healRate = healRate or 10000
    
    -- 获取施法者攻击力作为治疗基础
    local atk = GetUnitAttr(caster, currentConfig.attrType.ATK)
    
    -- 基础治疗量 = 攻击力 * 治疗倍率 / 10000
    local baseHeal = atk * healRate / 10000
    
    -- 应用治疗加成 (如果有)
    local finalHeal = baseHeal
    if caster and caster.healBonus then
        finalHeal = finalHeal * (1 + caster.healBonus / 10000)
    end
    
    -- 确保最小治疗量
    finalHeal = math.max(finalHeal, 1)
    
    return math.floor(finalHeal)
end

--- 获取当前配置
--- @return table 当前配置
function BattleFormula.GetConfig()
    return currentConfig
end

--- 获取当前公式类型
--- @return number 公式类型
function BattleFormula.GetFormulaType()
    return currentFormulaType
end

--- 设置自定义配置
--- @param config table 配置表
function BattleFormula.SetConfig(config)
    if config then
        for k, v in pairs(config) do
            currentConfig[k] = v
        end
    end
end

return BattleFormula
