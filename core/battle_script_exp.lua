---
--- Battle Script Exp Module
--- 战斗脚本API层 - 技能脚本与战斗系统的交互接口
--- 提供技能脚本使用的所有函数
---

local BattleFormation = require("modules.battle_formation")
local BattleMath = require("core.battle_math")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleBuff = require("modules.battle_buff")
local BattleAttribute = require("modules.battle_attribute")
local BattleSkill = require("modules.battle_skill")
local BattleEnergy = require("modules.battle_energy")
local BattleEvent = require("core.battle_event")
local BattleTimer = require("core.battle_timer")
local Logger = require("utils.logger")

---@class BattleScriptExp
local BattleScriptExp = {}

-- ==================== 辅助函数 ====================

--- 根据instanceId获取英雄
---@param instanceId number 实例ID
---@return table|nil 英雄对象
local function GetHeroByInstanceId(instanceId)
    if not instanceId then
        Logger.LogError("[BattleScriptExp] instanceId is nil")
        return nil
    end
    return BattleFormation.FindHeroByInstanceId(instanceId)
end

--- 检查英雄是否有效
---@param hero table 英雄对象
---@param funcName string 函数名（用于日志）
---@return boolean 是否有效
local function IsHeroValid(hero, funcName)
    if not hero then
        Logger.LogError(string.format("[BattleScriptExp.%s] hero not found", funcName))
        return false
    end
    return true
end

-- ==================== Math Functions ====================

--- 生成0-1之间的随机浮点数
---@return number 0-1之间的随机浮点数
function BattleScriptExp.Rand()
    return BattleMath.RandomProb()
end

--- 生成指定范围内的随机整数 [min, max]
---@param min number 最小值（包含）
---@param max number 最大值（包含）
---@return number 随机整数
function BattleScriptExp.RandInt(min, max)
    return BattleMath.Random(min, max)
end

--- 向下取整
---@param x number 输入值
---@return number 向下取整后的值
function BattleScriptExp.Floor(x)
    return BattleMath.Floor(x)
end

--- 向上取整
---@param x number 输入值
---@return number 向上取整后的值
function BattleScriptExp.Ceil(x)
    return BattleMath.Ceil(x)
end

-- ==================== Damage/Heal Functions ====================

--- 造成伤害
---@param instanceIdSrc number 攻击者实例ID
---@param instanceIdDest number 目标实例ID
---@param atkType number 攻击类型 (E_ATTACK_TYPE)
---@param dmgParam table 伤害参数 { skillDamageRate, isCrit, isForceHit, ... }
---@param tempAttr table 临时属性（可选）
---@param hitType number 命中类型 (E_HIT_TYPE)
---@return table 伤害结果 { damage, isCrit, isBlock, isDodged }
function BattleScriptExp.MakeDmg(instanceIdSrc, instanceIdDest, atkType, dmgParam, tempAttr, hitType)
    local srcHero = GetHeroByInstanceId(instanceIdSrc)
    local destHero = GetHeroByInstanceId(instanceIdDest)
    
    if not IsHeroValid(srcHero, "MakeDmg") or not IsHeroValid(destHero, "MakeDmg") then
        return { damage = 0, isCrit = false, isBlock = false, isDodged = false }
    end
    
    -- 应用临时属性（如果有）
    if tempAttr then
        for attrId, value in pairs(tempAttr) do
            BattleAttribute.ModifyAttribute(srcHero, attrId, value)
        end
    end
    
    local result = BattleDmgHeal.MakeDmg(srcHero, destHero, atkType, dmgParam, true, hitType)
    
    -- 恢复临时属性
    if tempAttr then
        for attrId, value in pairs(tempAttr) do
            BattleAttribute.ModifyAttribute(srcHero, attrId, -value)
        end
    end
    
    return result
end

--- 造成额外伤害（无视防御或特殊计算）
---@param instanceIdSrc number 攻击者实例ID
---@param instanceIdDest number 目标实例ID
---@param atkType number 攻击类型 (E_ATTACK_TYPE)
---@param dmgParam table 伤害参数 { damage, isTrueDamage, isCrit }
---@return table 伤害结果 { damage }
function BattleScriptExp.MakeDmgPlus(instanceIdSrc, instanceIdDest, atkType, dmgParam)
    local srcHero = GetHeroByInstanceId(instanceIdSrc)
    local destHero = GetHeroByInstanceId(instanceIdDest)
    
    if not IsHeroValid(srcHero, "MakeDmgPlus") or not IsHeroValid(destHero, "MakeDmgPlus") then
        return { damage = 0 }
    end
    
    return BattleDmgHeal.MakeDmgPlus(srcHero, destHero, atkType, dmgParam)
end

--- 治疗目标
---@param instanceIdSrc number 施法者实例ID
---@param instanceIdDest number 目标实例ID
---@param healVal number 治疗值
---@return number 实际治疗量
function BattleScriptExp.MakeHeal(instanceIdSrc, instanceIdDest, healVal)
    local srcHero = GetHeroByInstanceId(instanceIdSrc)
    local destHero = GetHeroByInstanceId(instanceIdDest)
    
    if not IsHeroValid(srcHero, "MakeHeal") or not IsHeroValid(destHero, "MakeHeal") then
        return 0
    end
    
    return BattleDmgHeal.MakeHeal(srcHero, destHero, healVal)
end

--- 恢复目标生命值（不受治疗加成/减益影响）
---@param instanceIdSrc number 施法者实例ID
---@param instanceIdDest number 目标实例ID
---@param healVal number 恢复值
---@return number 实际恢复量
function BattleScriptExp.MakeRecovery(instanceIdSrc, instanceIdDest, healVal)
    local srcHero = GetHeroByInstanceId(instanceIdSrc)
    local destHero = GetHeroByInstanceId(instanceIdDest)
    
    if not IsHeroValid(srcHero, "MakeRecovery") or not IsHeroValid(destHero, "MakeRecovery") then
        return 0
    end
    
    return BattleDmgHeal.MakeRecovery(srcHero, destHero, healVal)
end

--- 消耗HP（用于需要消耗生命值的技能）
---@param instanceId number 英雄实例ID
---@param percent number 消耗百分比 (0-100)
---@return number 实际消耗的HP值
function BattleScriptExp.PayHP(instanceId, percent)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "PayHP") then
        return 0
    end
    
    return BattleDmgHeal.PayHP(hero, percent)
end

-- ==================== Buff Functions ====================

--- 添加Buff到目标
---@param instanceIdSrc number 施法者实例ID
---@param instanceIdDest number 目标实例ID
---@param buff table Buff配置 { buffId, mainType, subType, duration, effects, ... }
---@return boolean 是否成功添加
function BattleScriptExp.AddBuff(instanceIdSrc, instanceIdDest, buff)
    local srcHero = GetHeroByInstanceId(instanceIdSrc)
    local destHero = GetHeroByInstanceId(instanceIdDest)
    
    if not IsHeroValid(srcHero, "AddBuff") or not IsHeroValid(destHero, "AddBuff") then
        return false
    end
    
    return BattleBuff.Add(srcHero, destHero, buff)
end

--- 根据主类型删除Buff
---@param instanceId number 目标实例ID
---@param mainType number Buff主类型
---@return number 移除的Buff数量
function BattleScriptExp.DelBuffByMainType(instanceId, mainType)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "DelBuffByMainType") then
        return 0
    end
    
    return BattleBuff.DelBuffByMainType(hero, mainType)
end

--- 根据子类型删除Buff
---@param instanceId number 目标实例ID
---@param subType number Buff子类型
---@param num number 删除数量（nil表示删除所有）
---@return number 实际移除的Buff数量
function BattleScriptExp.DelBuffBySubType(instanceId, subType, num)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "DelBuffBySubType") then
        return 0
    end
    
    return BattleBuff.DelBuffBySubType(hero, subType, num)
end

--- 根据主类型获取Buff层数
---@param instanceId number 目标实例ID
---@param mainType number Buff主类型
---@return number 总层数
function BattleScriptExp.GetBuffStackNumByMainType(instanceId, mainType)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetBuffStackNumByMainType") then
        return 0
    end
    
    return BattleBuff.GetBuffStackNumByMainType(hero, mainType)
end

--- 根据子类型获取Buff层数
---@param instanceId number 目标实例ID
---@param subType number Buff子类型
---@return number 总层数
function BattleScriptExp.GetBuffStackNumBySubType(instanceId, subType)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetBuffStackNumBySubType") then
        return 0
    end
    
    return BattleBuff.GetBuffStackNumBySubType(hero, subType)
end

-- ==================== Attribute Functions ====================

--- 获取当前HP
---@param instanceId number 英雄实例ID
---@return number 当前HP
function BattleScriptExp.GetCurHp(instanceId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetCurHp") then
        return 0
    end
    
    return BattleAttribute.GetHeroCurHp(hero)
end

--- 获取最大HP
---@param instanceId number 英雄实例ID
---@return number 最大HP
function BattleScriptExp.GetMaxHp(instanceId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetMaxHp") then
        return 0
    end
    
    return BattleAttribute.GetHeroMaxHp(hero)
end

--- 获取HP百分比
---@param instanceId number 英雄实例ID
---@return number HP百分比 (0-100)
function BattleScriptExp.GetHpPercent(instanceId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetHpPercent") then
        return 0
    end
    
    local curHp = BattleAttribute.GetHeroCurHp(hero)
    local maxHp = BattleAttribute.GetHeroMaxHp(hero)
    
    if maxHp <= 0 then
        return 0
    end
    
    return (curHp / maxHp) * 100
end

--- 设置HP为指定值
---@param instanceId number 英雄实例ID
---@param hpVal number 要设置的HP值
function BattleScriptExp.SetHp(instanceId, hpVal)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "SetHp") then
        return
    end
    
    BattleAttribute.SetHpByVal(hero, hpVal)
end

--- 设置HP为最大HP的百分比
---@param instanceId number 英雄实例ID
---@param percent number 百分比 (0-100)
function BattleScriptExp.SetHpPercent(instanceId, percent)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "SetHpPercent") then
        return
    end
    
    BattleAttribute.SetHpByPercent(hero, percent)
end

--- 获取英雄属性
---@param instanceId number 英雄实例ID
---@param attrId number 属性ID
---@return number 属性值
function BattleScriptExp.GetHeroAttribute(instanceId, attrId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetHeroAttribute") then
        return 0
    end
    
    return BattleAttribute.GetAttribute(hero, attrId)
end

--- 修改英雄属性
---@param instanceId number 英雄实例ID
---@param attrId number 属性ID
---@param attrValue number 属性变化值
function BattleScriptExp.ModifyAttribute(instanceId, attrId, attrValue)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "ModifyAttribute") then
        return
    end
    
    BattleAttribute.ModifyAttribute(hero, attrId, attrValue)
end

-- ==================== Skill Functions ====================

--- 获取技能当前冷却时间
---@param instanceId number 英雄实例ID
---@param skillId number 技能ID
---@return number 当前冷却时间
function BattleScriptExp.GetSkillCurCoolDown(instanceId, skillId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetSkillCurCoolDown") then
        return 0
    end
    
    return BattleSkill.GetSkillCurCoolDown(hero, skillId)
end

--- 设置技能冷却时间
---@param instanceId number 英雄实例ID
---@param skillId number 技能ID
---@param cd number 冷却时间
function BattleScriptExp.SetSkillCurCoolDown(instanceId, skillId, cd)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "SetSkillCurCoolDown") then
        return
    end
    
    BattleSkill.SetSkillCurCoolDown(hero, skillId, cd)
end

--- 释放隐藏技能（不消耗能量，不进入冷却）
---@param instanceIdSrc number 施法者实例ID
---@param instanceIdDest number 目标实例ID
---@param classId number 技能类别ID
---@return boolean 是否释放成功
function BattleScriptExp.CastHideSkill(instanceIdSrc, instanceIdDest, classId)
    local srcHero = GetHeroByInstanceId(instanceIdSrc)
    local destHero = GetHeroByInstanceId(instanceIdDest)
    
    if not IsHeroValid(srcHero, "CastHideSkill") then
        return false
    end
    
    -- TODO: 实现隐藏技能释放逻辑
    Logger.Debug(string.format("[BattleScriptExp.CastHideSkill] src=%d, dest=%d, classId=%d", 
        instanceIdSrc, instanceIdDest or 0, classId))
    
    return true
end

--- 添加无消耗的大招技能
---@param instanceIdSrc number 施法者实例ID
---@param instanceIdDest number 目标实例ID
---@return boolean 是否成功
function BattleScriptExp.AddUltimateSkillNoCost(instanceIdSrc, instanceIdDest)
    local srcHero = GetHeroByInstanceId(instanceIdSrc)
    local destHero = GetHeroByInstanceId(instanceIdDest)
    
    if not IsHeroValid(srcHero, "AddUltimateSkillNoCost") then
        return false
    end
    
    -- TODO: 实现无消耗大招添加逻辑
    Logger.Debug(string.format("[BattleScriptExp.AddUltimateSkillNoCost] src=%d, dest=%d", 
        instanceIdSrc, instanceIdDest or 0))
    
    return true
end

-- ==================== Target Selection Functions ====================

--- 获取随机敌人的实例ID
---@param instanceId number 英雄实例ID
---@return number|nil 随机敌人的实例ID
function BattleScriptExp.GetRandomEnemyInstanceId(instanceId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetRandomEnemyInstanceId") then
        return nil
    end
    
    return BattleFormation.GetRandomEnemyInstanceId(hero)
end

--- 获取随机友军的实例ID
---@param instanceId number 英雄实例ID
---@param includeSelf boolean 是否包含自己
---@return number|nil 随机友军的实例ID
function BattleScriptExp.GetRandomFriendInstanceId(instanceId, includeSelf)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetRandomFriendInstanceId") then
        return nil
    end
    
    return BattleFormation.GetRandomFriendInstanceId(hero, includeSelf)
end

--- 根据属性排序获取敌人列表
---@param instanceId number 英雄实例ID
---@param attrId number 属性ID
---@return table 排序后的敌人实例ID列表
function BattleScriptExp.GetEnemySortByAttrId(instanceId, attrId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetEnemySortByAttrId") then
        return {}
    end
    
    local enemyTeam = BattleFormation.GetEnemyTeam(hero)
    if not enemyTeam or #enemyTeam == 0 then
        return {}
    end
    
    -- 只选择存活的敌人并按属性排序
    local aliveEnemies = {}
    for _, enemy in ipairs(enemyTeam) do
        if enemy.isAlive and not enemy.isDead then
            table.insert(aliveEnemies, enemy)
        end
    end
    
    -- 按属性值降序排序
    table.sort(aliveEnemies, function(a, b)
        local attrA = BattleAttribute.GetAttribute(a, attrId) or 0
        local attrB = BattleAttribute.GetAttribute(b, attrId) or 0
        return attrA > attrB
    end)
    
    -- 返回实例ID列表
    local result = {}
    for _, enemy in ipairs(aliveEnemies) do
        table.insert(result, enemy.instanceId)
    end
    
    return result
end

--- 根据属性排序获取友军列表
---@param instanceId number 英雄实例ID
---@param attrId number 属性ID
---@param includeSelf boolean 是否包含自己
---@return table 排序后的友军实例ID列表
function BattleScriptExp.GetFriendSortByAttrId(instanceId, attrId, includeSelf)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetFriendSortByAttrId") then
        return {}
    end
    
    local friendTeam = BattleFormation.GetFriendTeam(hero)
    if not friendTeam or #friendTeam == 0 then
        return {}
    end
    
    -- 只选择存活的友军并按属性排序
    local aliveFriends = {}
    for _, friend in ipairs(friendTeam) do
        if friend.isAlive and not friend.isDead then
            if includeSelf or friend.instanceId ~= hero.instanceId then
                table.insert(aliveFriends, friend)
            end
        end
    end
    
    -- 按属性值降序排序
    table.sort(aliveFriends, function(a, b)
        local attrA = BattleAttribute.GetAttribute(a, attrId) or 0
        local attrB = BattleAttribute.GetAttribute(b, attrId) or 0
        return attrA > attrB
    end)
    
    -- 返回实例ID列表
    local result = {}
    for _, friend in ipairs(aliveFriends) do
        table.insert(result, friend.instanceId)
    end
    
    return result
end

--- 根据位置获取实例ID
---@param isLeft boolean 是否在左侧队伍
---@param wpType number 位置类型
---@return number|nil 实例ID
function BattleScriptExp.GetInstanceIdByWpType(isLeft, wpType)
    return BattleFormation.GetInstanceIdByWpType(isLeft, wpType)
end

-- ==================== Energy Functions ====================

--- 添加能量条
---@param instanceId number 英雄实例ID
---@param energyPoint number 能量点数
function BattleScriptExp.AddEnergyBar(instanceId, energyPoint)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "AddEnergyBar") then
        return
    end
    
    BattleEnergy.AddEnergy(hero, energyPoint)
end

--- 添加能量点
---@param instanceId number 英雄实例ID
---@param point number 能量点
function BattleScriptExp.AddEnergyPoint(instanceId, point)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "AddEnergyPoint") then
        return
    end
    
    BattleEnergy.AddPoint(hero, point)
end

--- 获取大招技能消耗
---@param instanceId number 英雄实例ID
---@return number 能量消耗
function BattleScriptExp.GetUltimateSkillCost(instanceId)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "GetUltimateSkillCost") then
        return 0
    end
    
    -- 获取大招技能
    local ultimateSkills = BattleSkill.GetSkillsByType(hero, E_SKILL_TYPE_ULTIMATE)
    if not ultimateSkills or #ultimateSkills == 0 then
        return 0
    end
    
    local ultimateSkill = ultimateSkills[1]
    return ultimateSkill.energyCost or ultimateSkill.energy_cost or 0
end

-- ==================== Summon/Revive Functions ====================

--- 创建召唤物
---@param instanceId number 召唤者实例ID
---@param tokenId number 召唤物ID
---@param life number 存活回合数
---@param wpType number 位置类型
---@return number|nil 召唤物实例ID
function BattleScriptExp.CreateToken(instanceId, tokenId, life, wpType)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "CreateToken") then
        return nil
    end
    
    -- TODO: 实现召唤物创建逻辑
    Logger.Debug(string.format("[BattleScriptExp.CreateToken] summoner=%d, tokenId=%d, life=%d, wpType=%d", 
        instanceId, tokenId, life, wpType))
    
    return nil
end

--- 销毁召唤物
---@param instanceId number 召唤物实例ID
---@param hideImmediately boolean 是否立即隐藏
function BattleScriptExp.DestroyToken(instanceId, hideImmediately)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not IsHeroValid(hero, "DestroyToken") then
        return
    end
    
    -- TODO: 实现召唤物销毁逻辑
    Logger.Debug(string.format("[BattleScriptExp.DestroyToken] instanceId=%d, hideImmediately=%s", 
        instanceId, tostring(hideImmediately)))
end

--- 复活英雄
---@param instanceId number 英雄实例ID
---@param wpType number 位置类型
---@param hpRate number HP恢复比例 (0-1)
---@param actionOrderRate number 行动条恢复比例 (0-1)
---@return boolean 是否复活成功
function BattleScriptExp.ReviveHero(instanceId, wpType, hpRate, actionOrderRate)
    local hero = GetHeroByInstanceId(instanceId)
    
    if not hero then
        Logger.LogError("[BattleScriptExp.ReviveHero] hero not found")
        return false
    end
    
    -- 检查英雄是否已死亡
    if hero.isAlive then
        Logger.LogWarning("[BattleScriptExp.ReviveHero] hero is already alive")
        return false
    end
    
    -- 设置HP
    local maxHp = BattleAttribute.GetHeroMaxHp(hero)
    local newHp = maxHp * (hpRate or 0.3)
    BattleAttribute.SetHpByVal(hero, newHp)
    
    -- 标记为存活
    hero.isAlive = true
    hero.isDead = false
    
    Logger.Debug(string.format("[BattleScriptExp.ReviveHero] hero=%d, wpType=%d, hpRate=%.2f", 
        instanceId, wpType, hpRate or 0.3))
    
    return true
end

-- ==================== Event Functions ====================

--- 发布事件
---@param eventName string 事件名称
---@param ... any 事件参数
function BattleScriptExp.PublishEvent(eventName, ...)
    BattleEvent.Publish(eventName, ...)
end

--- 延迟执行
---@param duration number 延迟时间（秒）
---@param callback function 回调函数
function BattleScriptExp.DelayExec(duration, callback)
    if type(callback) ~= "function" then
        Logger.LogError("[BattleScriptExp.DelayExec] callback must be a function")
        return
    end
    
    BattleTimer.Delay(duration, callback)
end

-- ==================== Utility Functions ====================

--- 输出日志
---@param msg string 日志消息
function BattleScriptExp.Log(msg)
    Logger.Log(tostring(msg))
end

--- 输出错误日志
---@param msg string 错误消息
function BattleScriptExp.LogError(msg)
    Logger.LogError(tostring(msg))
end

return BattleScriptExp
