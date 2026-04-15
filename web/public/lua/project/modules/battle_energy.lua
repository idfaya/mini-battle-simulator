local BattleEnergy = {}

if not E_SKILL_TYPE then
    require("core.battle_enum")
end

local Logger = require("utils.logger")
local EnergyConfig = require("config.battle_energy_config")

local DEFAULT_MAX_ENERGY = EnergyConfig.defaultMaxEnergy or 100

-- 英雄能量数据存储
local heroEnergyData = {}

local function ClampFloor(value, minValue, maxValue)
    value = math.floor(tonumber(value) or 0)
    value = math.max(minValue or value, value)
    if maxValue ~= nil then
        value = math.min(maxValue, value)
    end
    return value
end

local function GetClassModifier(hero)
    local classId = hero and (hero.class or hero.Class) or 0
    return EnergyConfig.classModifiers[classId] or EnergyConfig.classModifiers[2] or {}
end

local function SyncHeroEnergy(hero, data)
    if not hero or not data then
        return
    end

    hero.curEnergy = data.curEnergy
    hero.energy = data.curEnergy
    hero.maxEnergy = data.maxEnergy
end

local function PublishHeroStateChanged(hero)
    if not hero then
        return
    end

    local BattleEvent = require("core.battle_event")
    local BattleVisualEvents = require("ui.battle_visual_events")
    BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(hero))
end

--- 初始化能量系统
function BattleEnergy.Init()
    heroEnergyData = {}
    Logger.Log("[BattleEnergy] 能量系统初始化完成")
end

--- 清理能量系统
function BattleEnergy.OnFinal()
    heroEnergyData = {}
end

function BattleEnergy.GetConfig()
    return EnergyConfig
end

function BattleEnergy.GetDefaultInitialEnergy()
    return EnergyConfig.defaultInitialEnergy or 0
end

--- 获取英雄能量数据
local function GetHeroEnergyData(hero)
    if not hero or not hero.instanceId then
        return nil
    end

    if not heroEnergyData[hero.instanceId] then
        local maxEnergy = ClampFloor(hero.maxEnergy or DEFAULT_MAX_ENERGY, 1, nil)
        heroEnergyData[hero.instanceId] = {
            curEnergy = ClampFloor(hero.curEnergy or hero.energy or 0, 0, maxEnergy),
            maxEnergy = maxEnergy,
        }

        SyncHeroEnergy(hero, heroEnergyData[hero.instanceId])
    end

    return heroEnergyData[hero.instanceId]
end

--- 增加能量
---@return number 实际增加值
function BattleEnergy.AddEnergy(hero, amount, reason, meta)
    if not hero or not amount or amount <= 0 then
        return 0
    end

    local data = GetHeroEnergyData(hero)
    if not data then
        return 0
    end

    amount = ClampFloor(amount, 0, nil)
    if amount <= 0 then
        return 0
    end

    local oldEnergy = data.curEnergy
    data.curEnergy = math.min(data.curEnergy + amount, data.maxEnergy)
    SyncHeroEnergy(hero, data)

    local gained = data.curEnergy - oldEnergy
    if gained > 0 then
        Logger.Log(string.format("[BattleEnergy] %s 能量增加[%s]: %d + %d = %d/%d",
            hero.name or "Unknown",
            tostring(reason or "unknown"),
            oldEnergy,
            gained,
            data.curEnergy,
            data.maxEnergy))
        if meta and meta.silent ~= true then
            PublishHeroStateChanged(hero)
        end
    end

    return gained
end

function BattleEnergy.AddPoint(hero, amount, reason, meta)
    return BattleEnergy.AddEnergy(hero, amount, reason, meta)
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

    amount = ClampFloor(amount, 0, nil)
    if amount <= 0 then
        return false
    end

    if data.curEnergy < amount then
        Logger.Log(string.format("[BattleEnergy] %s 能量不足: %d < %d",
            hero.name or "Unknown", data.curEnergy, amount))
        return false
    end

    local oldEnergy = data.curEnergy
    data.curEnergy = data.curEnergy - amount
    SyncHeroEnergy(hero, data)

    Logger.Log(string.format("[BattleEnergy] %s 能量消耗: %d - %d = %d/%d",
        hero.name or "Unknown", oldEnergy, amount, data.curEnergy, data.maxEnergy))

    local BattleEvent = require("core.battle_event")
    BattleEvent.Publish("ENERGY_CONSUMED", hero, amount)
    PublishHeroStateChanged(hero)

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

local function GetSkillHitGain(hero, skill)
    local gains = EnergyConfig.gains or {}
    local modifier = GetClassModifier(hero)
    local baseGain = 0
    local skillType = skill and skill.skillType or E_SKILL_TYPE_NORMAL

    if skillType == E_SKILL_TYPE_NORMAL then
        baseGain = gains.normalHit or 0
    elseif skillType == E_SKILL_TYPE_ACTIVE then
        baseGain = gains.activeHit or 0
    elseif skillType == E_SKILL_TYPE_ULTIMATE then
        baseGain = gains.ultimateHit or 0
    end

    return math.max(0, baseGain + (modifier.skillHitBonus or 0))
end

--- 行动结束时的能量回复（回合结束调用）
function BattleEnergy.OnActionEnd(hero)
    if not hero then
        return 0
    end

    local gains = EnergyConfig.gains or {}
    local modifier = GetClassModifier(hero)
    local amount = (gains.turnEnd or 0) + (modifier.turnEndBonus or 0)
    return BattleEnergy.AddEnergy(hero, amount, "turn_end")
end

--- 技能命中后的能量回复
function BattleEnergy.OnSkillHit(hero, skill, hitResult)
    if not hero or not hitResult then
        return 0
    end

    local totalGain = 0
    if (hitResult.successfulHits or 0) > 0 then
        totalGain = totalGain + BattleEnergy.AddEnergy(hero, GetSkillHitGain(hero, skill), "skill_hit")
    end

    if (hitResult.killCount or 0) > 0 then
        totalGain = totalGain + BattleEnergy.AddEnergy(
            hero,
            (EnergyConfig.gains.kill or 0) * hitResult.killCount,
            "kill"
        )
    end

    if hitResult.didCrit then
        totalGain = totalGain + BattleEnergy.AddEnergy(hero, EnergyConfig.gains.crit or 0, "crit")
    end

    return totalGain
end

function BattleEnergy.OnBlock(hero)
    if not hero then
        return 0
    end

    return BattleEnergy.AddEnergy(hero, EnergyConfig.gains.block or 0, "block")
end

--- 受到伤害时的能量回复
function BattleEnergy.OnHeroDamaged(hero, damage, attacker, context)
    if not hero or not damage or damage <= 0 or hero.isDead then
        return 0
    end

    local gains = EnergyConfig.gains or {}
    local caps = EnergyConfig.caps or {}
    local modifier = GetClassModifier(hero)
    local maxHp = math.max(1, hero.maxHp or 1)
    local hpLossRatio = damage / maxHp
    local amount = (gains.damageTakenBase or 0) + math.floor(hpLossRatio * (gains.damageTakenByLostHpRate or 0))
    amount = amount * (modifier.damageTakenScale or 1)

    local damageKind = context and context.damageKind or "direct"
    local damageScale = (EnergyConfig.damageKindScale and EnergyConfig.damageKindScale[damageKind]) or 1
    amount = amount * damageScale

    amount = ClampFloor(amount, 0, caps.singleDamageTaken)
    if amount <= 0 then
        return 0
    end

    return BattleEnergy.AddEnergy(hero, amount, "damaged", {
        attacker = attacker,
    })
end

--- 重置英雄能量
function BattleEnergy.ResetEnergy(hero)
    if not hero or not hero.instanceId then
        return
    end

    local data = GetHeroEnergyData(hero)
    if data then
        data.curEnergy = 0
        SyncHeroEnergy(hero, data)
        PublishHeroStateChanged(hero)
    end
end

--- 设置英雄最大能量
function BattleEnergy.SetMaxEnergy(hero, maxEnergy)
    if not hero or not hero.instanceId or not maxEnergy then
        return
    end

    local data = GetHeroEnergyData(hero)
    if data then
        data.maxEnergy = ClampFloor(maxEnergy, 1, nil)
        if data.curEnergy > data.maxEnergy then
            data.curEnergy = data.maxEnergy
        end
        SyncHeroEnergy(hero, data)
        PublishHeroStateChanged(hero)
    end
end

return BattleEnergy
