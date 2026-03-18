local BattleEnergy = {}

local Logger = require("utils.logger")

-- 能量配置常量
local DEFAULT_MAX_ENERGY = 100  -- 默认最大能量值
local ENERGY_PER_ACTION = 20    -- 每次行动回复的能量
local ENERGY_PER_DAMAGE = 0.5   -- 每受到1点伤害回复的能量比例

-- 英雄能量数据存储
local heroEnergyData = {}

--- 初始化能量系统
function BattleEnergy.Init()
    heroEnergyData = {}
    Logger.Log("[BattleEnergy] 能量系统初始化完成")
end

--- 清理能量系统
function BattleEnergy.OnFinal()
    heroEnergyData = {}
end

--- 获取英雄能量数据
local function GetHeroEnergyData(hero)
    if not hero or not hero.instanceId then
        return nil
    end
    
    if not heroEnergyData[hero.instanceId] then
        -- 初始化英雄能量数据
        local maxEnergy = hero.maxEnergy or DEFAULT_MAX_ENERGY
        heroEnergyData[hero.instanceId] = {
            curEnergy = 0,  -- 当前能量
            maxEnergy = maxEnergy,  -- 最大能量
        }
        
        -- 同时设置到英雄对象上，方便外部访问
        hero.curEnergy = 0
        hero.maxEnergy = maxEnergy
    end
    
    return heroEnergyData[hero.instanceId]
end

--- 增加能量
function BattleEnergy.AddEnergy(hero, amount)
    if not hero or not amount or amount <= 0 then
        return
    end
    
    local data = GetHeroEnergyData(hero)
    if not data then
        return
    end
    
    local oldEnergy = data.curEnergy
    data.curEnergy = math.min(data.curEnergy + amount, data.maxEnergy)
    
    -- 同步到英雄对象
    hero.curEnergy = data.curEnergy
    
    Logger.Log(string.format("[BattleEnergy] %s 能量增加: %d + %d = %d/%d",
        hero.name or "Unknown", oldEnergy, amount, data.curEnergy, data.maxEnergy))
end

--- 消耗能量
function BattleEnergy.ConsumeEnergy(hero, amount)
    if not hero or not amount or amount <= 0 then
        return false
    end
    
    local data = GetHeroEnergyData(hero)
    if not data then
        return false
    end
    
    if data.curEnergy < amount then
        Logger.Log(string.format("[BattleEnergy] %s 能量不足: %d < %d",
            hero.name or "Unknown", data.curEnergy, amount))
        return false
    end
    
    local oldEnergy = data.curEnergy
    data.curEnergy = data.curEnergy - amount
    
    -- 同步到英雄对象
    hero.curEnergy = data.curEnergy
    
    Logger.Log(string.format("[BattleEnergy] %s 能量消耗: %d - %d = %d/%d",
        hero.name or "Unknown", oldEnergy, amount, data.curEnergy, data.maxEnergy))
    return true
end

--- 检查能量是否足够
function BattleEnergy.CanCastUltimate(hero, skill)
    if not hero or not skill then
        return false
    end
    
    local data = GetHeroEnergyData(hero)
    if not data then
        return false
    end
    
    local energyCost = skill.skillCost or skill.energyCost or 0
    if energyCost <= 0 then
        return true
    end
    
    return data.curEnergy >= energyCost
end

--- 获取当前能量
function BattleEnergy.GetCurrentEnergy(hero)
    local data = GetHeroEnergyData(hero)
    if not data then
        return 0
    end
    return data.curEnergy
end

--- 获取最大能量
function BattleEnergy.GetMaxEnergy(hero)
    local data = GetHeroEnergyData(hero)
    if not data then
        return DEFAULT_MAX_ENERGY
    end
    return data.maxEnergy
end

--- 行动结束时的能量回复（回合结束调用）
function BattleEnergy.OnActionEnd(hero)
    if not hero then
        return
    end
    
    -- 每次行动结束回复固定能量
    BattleEnergy.AddEnergy(hero, ENERGY_PER_ACTION)
end

--- 受到伤害时的能量回复
function BattleEnergy.OnHeroDamaged(hero, damage)
    if not hero or not damage or damage <= 0 then
        return
    end
    
    -- 受到伤害回复能量（按伤害比例）
    local energyGain = math.floor(damage * ENERGY_PER_DAMAGE)
    if energyGain > 0 then
        BattleEnergy.AddEnergy(hero, energyGain)
    end
end

--- 重置英雄能量
function BattleEnergy.ResetEnergy(hero)
    if not hero or not hero.instanceId then
        return
    end
    
    local data = GetHeroEnergyData(hero)
    if data then
        data.curEnergy = 0
        hero.curEnergy = 0
    end
end

--- 设置英雄最大能量
function BattleEnergy.SetMaxEnergy(hero, maxEnergy)
    if not hero or not hero.instanceId or not maxEnergy then
        return
    end
    
    local data = GetHeroEnergyData(hero)
    if data then
        data.maxEnergy = maxEnergy
        hero.maxEnergy = maxEnergy
        -- 确保当前能量不超过最大值
        if data.curEnergy > maxEnergy then
            data.curEnergy = maxEnergy
            hero.curEnergy = maxEnergy
        end
    end
end

return BattleEnergy
