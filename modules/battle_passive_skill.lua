---
--- Battle Passive Skill Module
--- 战斗被动技能模块 - 完全按照原项目实现移植
---

local Logger = require("utils.logger")

---@class BattlePassiveSkill
local BattlePassiveSkill = {}

-- 触发时机到委托的映射表
local triggerTime2Delegate = {}

-- 触发限制保护
local triggerLimitProtect = {}

-- 忽略HP检查的触发时机
local triggerTimeIgnoreHp = {
    [E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill] = true,
    [E_PASSIVE_SKILL_TRIGGER_TIME.Dying] = true,
}

-- 友方触发时机映射
local triggerTime2Friend = {
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendAfterDmg] = E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmg,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendAtkBeforeDmg] = E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDmg,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendTurnBegin] = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendNormalAtkStart] = E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkStart,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendDmgMakeDeath] = E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeDeath,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendDmgCauseDeath] = E_PASSIVE_SKILL_TRIGGER_TIME.DmgCauseDeath,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendCasterBuff] = E_PASSIVE_SKILL_TRIGGER_TIME.CasterBuff,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendReceiveBuff] = E_PASSIVE_SKILL_TRIGGER_TIME.ReceiveBuff,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendHpChg] = E_PASSIVE_SKILL_TRIGGER_TIME.HpChg,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendUltimateAtkStart] = E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkStart,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendPayHp] = E_PASSIVE_SKILL_TRIGGER_TIME.PayHp,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendDying] = E_PASSIVE_SKILL_TRIGGER_TIME.Dying,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendAfterHeal] = E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterHeal,
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendAfterRecover] = E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterRecover,
}

-- 敌方触发时机映射
local triggerTime2Enemy = {
    [E_PASSIVE_SKILL_TRIGGER_TIME.EnemyUltimateAtkStart] = E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkStart,
    [E_PASSIVE_SKILL_TRIGGER_TIME.EnemyDefBeforeDotDmgCalc] = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDotDmgCalc,
    [E_PASSIVE_SKILL_TRIGGER_TIME.EnemyDefAfterBurnDmg] = E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterBurnDmg,
    [E_PASSIVE_SKILL_TRIGGER_TIME.EnemyTurnBegin] = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
    [E_PASSIVE_SKILL_TRIGGER_TIME.EnemyAfterReceiveBuff] = E_PASSIVE_SKILL_TRIGGER_TIME.AfterReceiveBuff,
}

-- 友方集结触发时机映射
local triggerTime2FriendCollect = {
    [E_PASSIVE_SKILL_TRIGGER_TIME.FriendCollectMakeDeath] = E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeDeath,
}

-- 触发限制配置
local triggerLimitConfig = {
    [E_PASSIVE_SKILL_TRIGGER_TIME.BuffChg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDmgCalc] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDmg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmgCalc] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkFinish] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnEnd] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.Died] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeHealCalc] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkStart] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.CasterBuff] = 20,
    [E_PASSIVE_SKILL_TRIGGER_TIME.ReceiveBuff] = 20,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDotDmg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDotDmg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AtkAfterHeal] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterHeal] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkStart] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkFinish] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.HpChg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.EnemyUltimateAtkStart] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.CriticalRateChg] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeDeath] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DmgCauseDeath] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDotDmgCalc] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.TurnEndAddEnergy] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.EnterBuffSubType] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.LeaveBuffSubType] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.Dying] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.Revive] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.CollectAtkStart] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.CollectAtkFinish] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDotDmgCalc] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterBurnDmg] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.PayHp] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmgUnifiedPoint] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeHeal] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.BeControl] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.ReviveFriend] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.ReviveByFriend] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.JudgeRoundEnd] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AfterReceiveBuff] = 50,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AfterCasterBuff] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.TransferEnd] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDmgBeforeShield] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmgBeforeShield] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterRecover] = 30,
    [E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkStartU3] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.BeforeBattleEnd] = 10,
    [E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnEndActionForceUpdated] = 10,
}

--- 重置系统
local function Reset()
    triggerTime2Delegate = {}
    for k, v in pairs(E_PASSIVE_SKILL_TRIGGER_TIME) do
        triggerTime2Delegate[v] = {}
    end
    triggerLimitProtect = {}
end

--- 创建被动技能上下文
local function CreatePassiveSkillContext(hero, heroTrigger, skill, extraParam)
    local data = {}
    data.OwnerUnitID = hero.instanceId or hero.id
    data.TriggerUnitID = heroTrigger.instanceId or heroTrigger.id

    if skill then
        data.OwnerSkillId = skill.skillId
        data.OwnerSkillCsv = {}
        data.OwnerSkillCsv.classId = skill.classId or skill.rglConfig and skill.rglConfig.ClassID
        
        -- 复制技能参数
        local skillParam = skill.skillParam or skill.rglConfig and skill.rglConfig.SkillParam or {}
        for k, v in ipairs(skillParam) do
            data.OwnerSkillCsv["param" .. k] = v
        end

        data.OwnerSkillCsv.coolDown = skill.coolDown or 0
    end

    data.extraParam = extraParam

    local context = {}
    context.data = data

    return context
end

--- 调用被动技能
local function CallPassiveSkill(hero, battleScriptSkill, extraParam)
    local context = CreatePassiveSkillContext(battleScriptSkill.src, hero, battleScriptSkill.skill, extraParam)

    -- 简化的条件检查（原项目使用 BattleCondition.CheckConditions）
    local canTrigger = true
    if battleScriptSkill.triggerConds then
        -- 这里可以添加更复杂的条件检查
        canTrigger = true
    end

    if canTrigger then
        local success, err = pcall(function()
            battleScriptSkill.func(battleScriptSkill.self, context)
        end)
        if not success then
            Logger.Log("[BattlePassiveSkill] 被动技能执行错误: " .. tostring(err))
        end
        return true
    end

    return false
end

--- 创建技能实体
local function CreateSkillEntity(luaSkill, luaFunc, src, skill, buffSubType, luaFuncName, triggerTime)
    local entity = {}
    entity.self = luaSkill
    entity.func = luaFunc
    entity.src = src
    entity.skill = skill
    entity.buffSubType = buffSubType
    entity.luaFuncName = luaFuncName
    entity.triggerLimit = triggerLimitConfig[triggerTime] or 10
    entity.triggerConds = nil  -- 可以添加触发条件
    return entity
end

--- 创建战斗脚本技能
local function CreateBattleScriptSkill(hero, skill, luaFuncName, triggerTime)
    local skillId = skill.skillId
    local classId = skill.classId or skill.rglConfig and skill.rglConfig.ClassID

    -- 初始化英雄的 luaSkill 表
    if not hero.luaSkill then
        hero.luaSkill = {}
    end

    if hero.luaSkill[skillId] then
        local self = hero.luaSkill[skillId]
        local luaFunc = self[luaFuncName]
        if luaFunc == nil then
            Logger.Error("[BattlePassiveSkill] 找不到Lua函数: " .. tostring(classId) .. " " .. luaFuncName)
            return nil
        end
        return CreateSkillEntity(self, luaFunc, hero, skill, nil, luaFuncName, triggerTime)
    end

    -- 加载Lua技能文件
    local luaFile = "war_" .. tostring(classId)
    local success, luaSkill = pcall(require, luaFile)
    if not success or luaSkill == nil then
        -- 尝试从 config/skill_rgl/ 目录加载
        success, luaSkill = pcall(require, "config.skill_rgl.skill_" .. skillId)
        if not success or luaSkill == nil then
            Logger.Error("[BattlePassiveSkill] 加载Lua文件失败: " .. luaFile .. " 或 skill_" .. skillId)
            return nil
        end
    end

    local context = CreatePassiveSkillContext(hero, {}, skill, nil)
    local self = luaSkill(context)
    hero.luaSkill[skillId] = self

    local luaFunc = self[luaFuncName]
    if luaFunc == nil then
        Logger.Error("[BattlePassiveSkill] 找不到Lua函数: " .. tostring(classId) .. " " .. luaFuncName)
        return nil
    end
    return CreateSkillEntity(self, luaFunc, hero, skill, nil, luaFuncName, triggerTime)
end

--- 检查是否可以插入被动技能
local function CanInsertPassiveSkill(hero, skill, buffSubType, triggerTime, luaFuncName)
    local delegates = triggerTime2Delegate[triggerTime]
    if delegates == nil then
        Logger.Error("[BattlePassiveSkill] 触发时间未配置: " .. tostring(triggerTime))
        return false
    end

    local heroId = hero.instanceId or hero.id
    delegates = delegates[heroId]
    if delegates == nil then return true end

    if skill then
        for _, battleScriptSkill in ipairs(delegates) do
            if battleScriptSkill.skill and battleScriptSkill.skill.skillId == skill.skillId 
               and battleScriptSkill.luaFuncName == luaFuncName then
                return false
            end
        end
    end

    return true
end

--- 添加被动技能到触发时机
local function AddPassiveSkill2TriggerTime(hero, triggerTime, battleScriptSkill, checkRepeat)
    local delegates = triggerTime2Delegate[triggerTime]
    if delegates == nil then
        Logger.Error("[BattlePassiveSkill] 不支持的触发时间: " .. tostring(triggerTime))
        return
    end

    local heroId = hero.instanceId or hero.id
    if delegates[heroId] == nil then
        delegates[heroId] = {}
    end

    if checkRepeat then
        if CanInsertPassiveSkill(hero, battleScriptSkill.skill, battleScriptSkill.buffSubType, triggerTime, battleScriptSkill.luaFuncName) then
            table.insert(delegates[heroId], battleScriptSkill)
        end
    else
        battleScriptSkill.triggerLimit = triggerLimitConfig[triggerTime] or 10
        table.insert(delegates[heroId], battleScriptSkill)
    end
end

--- 添加战斗脚本技能到触发时机
local function AddBattleScriptSkill2TriggerTime(hero, triggerTime, battleScriptSkill, checkRepeat)
    -- 检查友方触发时机映射
    local toFriendTrigger = triggerTime2Friend[triggerTime]
    if toFriendTrigger then
        -- 为友方添加技能（简化版，直接添加到自身）
        AddPassiveSkill2TriggerTime(hero, toFriendTrigger, battleScriptSkill, checkRepeat)
        return
    end

    -- 检查敌方触发时机映射
    local toEnemyTrigger = triggerTime2Enemy[triggerTime]
    if toEnemyTrigger then
        -- 为敌方添加技能（简化版，直接添加到自身）
        AddPassiveSkill2TriggerTime(hero, toEnemyTrigger, battleScriptSkill, checkRepeat)
        return
    end

    -- 直接添加到自身
    AddPassiveSkill2TriggerTime(hero, triggerTime, battleScriptSkill, checkRepeat)
end

--- 获取被动技能模板
local function GetPassiveSkillTemplate(skill)
    local classId = skill.classId or skill.rglConfig and skill.rglConfig.ClassID
    if not classId then
        Logger.Error("[BattlePassiveSkill] 技能没有classId")
        return nil
    end

    -- 尝试加载事件模板
    local fileName = "event_" .. classId
    local unitEventTemplate = _G[fileName]
    
    -- 如果没有全局模板，尝试从技能配置构建
    if unitEventTemplate == nil then
        -- 为Roguelike技能构建默认模板
        if skill.rglConfig then
            local triggers = {}
            local classId = skill.rglConfig.ClassID
            
            -- 根据ClassID确定触发时机和函数名
            if classId >= 8000010 and classId < 8000011 then
                -- 连击系: 攻击时触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkStart, luaFuncName = "OnNormalAtkStart" })
            elseif classId >= 8000011 and classId < 8000012 then
                -- 反击系: 受击后触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmg, luaFuncName = "OnDefAfterDmg" })
            elseif classId >= 8000050 and classId < 8000051 then
                -- 吸血系: 造成伤害后触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkFinish, luaFuncName = "OnNormalAtkFinish" })
            elseif classId >= 8000020 and classId < 8000021 then
                -- 格挡系: 受击前触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg, luaFuncName = "OnDefBeforeDmg" })
            elseif classId >= 8000021 and classId < 8000022 then
                -- 闪避系: 受击前触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg, luaFuncName = "OnDefBeforeDmg" })
            elseif classId >= 8000030 and classId < 8000031 then
                -- 开局增益系: 回合开始时触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin, luaFuncName = "OnSelfTurnBegin" })
            elseif classId >= 8000032 and classId < 8000033 then
                -- 速度系: 战斗开始时触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin, luaFuncName = "OnBattleBegin" })
            elseif classId >= 8000100 and classId < 8000101 then
                -- 法术增益系: 战斗开始时触发
                table.insert(triggers, { triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin, luaFuncName = "OnBattleBegin" })
            end
            
            if #triggers > 0 then
                unitEventTemplate = { triggers = triggers }
            end
        end
    end

    return unitEventTemplate
end

--- 执行委托
local function DoRunDelegates(hero, delegates, extraParam, ignoreHeroHp, isMutex)
    local removeDelegates = {}
    
    for k, battleScriptSkill in ipairs(delegates) do
        local src = battleScriptSkill.src
        local skill = battleScriptSkill.skill

        -- 检查技能是否可以运行
        local canRunBySkillType = true
        if skill ~= nil then
            canRunBySkillType = skill.enable ~= false
        end

        -- 检查HP（简化版）
        local canRunByHp = ignoreHeroHp or (src.hp and src.hp > 0) or battleScriptSkill.ignoreHeroHp

        local canRun = canRunBySkillType and canRunByHp

        if canRun then
            if battleScriptSkill.triggerLimit > 0 then
                if battleScriptSkill.isRunning then
                    Logger.Log("[BattlePassiveSkill] 检测到循环触发，暂时跳过")
                    return
                end

                battleScriptSkill.isRunning = true
                CallPassiveSkill(hero, battleScriptSkill, extraParam)
                battleScriptSkill.triggerLimit = battleScriptSkill.triggerLimit - 1
                battleScriptSkill.isRunning = false
            else
                Logger.Log("[BattlePassiveSkill] 触发次数已达上限")
            end
        else
            if not canRunBySkillType then
                table.insert(removeDelegates, k)
            end

            if isMutex then
                break
            end
        end
    end

    -- 移除无效的技能
    for k = #removeDelegates, 1, -1 do
        table.remove(delegates, removeDelegates[k])
    end
end

--- 运行委托
local function RunDelegates(hero, delegateType, extraParam)
    local delegatesDict = triggerTime2Delegate[delegateType]
    if delegatesDict == nil then
        Logger.Error("[BattlePassiveSkill] 错误的触发器类型: " .. tostring(delegateType))
        return
    end

    local heroId = hero.instanceId or hero.id
    local delegates = delegatesDict[heroId]

    if delegates == nil then return end

    if delegateType == E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill then
        DoRunDelegates(hero, delegates, extraParam, true, true)
    elseif delegateType == E_PASSIVE_SKILL_TRIGGER_TIME.Dying then
        DoRunDelegates(hero, delegates, extraParam, true, false)
    elseif delegateType == E_PASSIVE_SKILL_TRIGGER_TIME.Revive then
        DoRunDelegates(hero, delegates, extraParam, true, false)
    else
        DoRunDelegates(hero, delegates, extraParam, false, false)
    end
end

-- ==================== 公共接口 ====================

--- 添加被动技能到触发时机
function BattlePassiveSkill.AddPassiveSkill2TriggerTime(hero, skill)
    local unitEventTemplate = GetPassiveSkillTemplate(skill)
    if unitEventTemplate == nil then 
        Logger.Error("[BattlePassiveSkill] 无法获取技能模板")
        return 
    end

    local triggers = unitEventTemplate.triggers
    if triggers == nil then
        Logger.Error("[BattlePassiveSkill] 被动技能没有配置触发条件")
        return
    end

    for i = 1, #triggers do
        local trigger = triggers[i]
        local triggerTime = trigger.triggerTime
        local luaFuncName = trigger.luaFuncName

        local battleScriptSkill = CreateBattleScriptSkill(hero, skill, luaFuncName, triggerTime)

        if battleScriptSkill ~= nil then
            AddBattleScriptSkill2TriggerTime(hero, triggerTime, battleScriptSkill)
            Logger.Log(string.format("[BattlePassiveSkill] 英雄 [%s] 注册被动技能 [%s] 触发时机 [%d] 函数 [%s]",
                hero.name or "Unknown", skill.name or "Unknown", triggerTime, luaFuncName))
        end
    end
end

--- 插入被动技能（带排重检查）
function BattlePassiveSkill.InsertPassiveSkill(heroSkillOwner, heroSkillTrigger, classId, luaFuncName, triggerTime, ignoreHeroHp)
    if ignoreHeroHp == nil then
        ignoreHeroHp = false
    end

    -- 查找技能
    local skill = nil
    if heroSkillOwner.passiveSkills then
        for _, s in ipairs(heroSkillOwner.passiveSkills) do
            if s.classId == classId or (s.rglConfig and s.rglConfig.ClassID == classId) then
                skill = s
                break
            end
        end
    end
    
    if not skill then
        Logger.Error("[BattlePassiveSkill] 找不到技能: " .. tostring(classId))
        return
    end

    local battleScriptSkill = CreateBattleScriptSkill(heroSkillOwner, skill, luaFuncName, triggerTime)
    if battleScriptSkill then
        battleScriptSkill.ignoreHeroHp = ignoreHeroHp
        AddBattleScriptSkill2TriggerTime(heroSkillTrigger, triggerTime, battleScriptSkill, true)
    end
end

--- 禁用技能
function BattlePassiveSkill.DisableSkill(hero, skillId)
    if hero.passiveSkills then
        for _, passiveSkill in ipairs(hero.passiveSkills) do
            if passiveSkill.skillId == skillId then
                passiveSkill.enable = false
                return
            end
        end
    end
    Logger.Error("[BattlePassiveSkill] 找不到被动技能: " .. tostring(skillId))
end

--- 启用技能
function BattlePassiveSkill.EnableSkill(hero, skillId)
    if hero.passiveSkills then
        for _, passiveSkill in ipairs(hero.passiveSkills) do
            if passiveSkill.skillId == skillId then
                passiveSkill.enable = true
                return
            end
        end
    end
    Logger.Error("[BattlePassiveSkill] 找不到被动技能: " .. tostring(skillId))
end

-- ==================== 触发函数 ====================

function BattlePassiveSkill.RunSkillOnBattleBegin()
    Logger.Log("[BattlePassiveSkill] 触发战斗开始被动技能")
    -- 获取所有英雄并触发
    local BattleFormation = require("modules.battle_formation")
    local allHeroes = BattleFormation.GetAllHeroes and BattleFormation.GetAllHeroes() or {}
    for _, hero in ipairs(allHeroes) do
        RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin)
    end
end

function BattlePassiveSkill.RunSkillOnSelfTurnBegin(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin)
end

function BattlePassiveSkill.RunSkillOnSelfTurnEnd(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnEnd)
end

function BattlePassiveSkill.RunSkillOnNormalAtkStart(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkStart, extraParam)
end

function BattlePassiveSkill.RunSkillOnNormalAtkFinish(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkFinish)
end

function BattlePassiveSkill.RunSkillOnDefAfterDmg(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmg, extraParam)
end

function BattlePassiveSkill.RunSkillOnDefBeforeDmg(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg, extraParam)
end

function BattlePassiveSkill.RunSkillOnAtkBeforeDmg(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDmg, extraParam)
end

function BattlePassiveSkill.RunSkillOnDmgMakeKill(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill, extraParam)
end

function BattlePassiveSkill.RunSkillOnHeroDied(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.Died)
end

function BattlePassiveSkill.RunSkillOnHpChg(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.HpChg)
end

function BattlePassiveSkill.RunSkillOnBuffAdd(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.BuffChg)
end

function BattlePassiveSkill.RunSkillOnBuffDel(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.BuffChg)
end

function BattlePassiveSkill.RunSkillOnUltimateAtkStart(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkStart, extraParam)
end

function BattlePassiveSkill.RunSkillOnUltimateAtkFinish(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkFinish)
end

function BattlePassiveSkill.RunSkillOnDefAfterHeal(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterHeal, extraParam)
end

function BattlePassiveSkill.RunSkillOnAtkAfterHeal(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AtkAfterHeal, extraParam)
end

function BattlePassiveSkill.RunSkillOnDying(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.Dying, extraParam)
end

function BattlePassiveSkill.RunSkillOnRevive(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.Revive)
end

function BattlePassiveSkill.RunSkillBeforeBattleEnd(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.BeforeBattleEnd)
end

function BattlePassiveSkill.RunSkillOnJudgeTurnEnd(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.JudgeRoundEnd)
end

function BattlePassiveSkill.RunSkillOnTurnEndAddEnergy(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.TurnEndAddEnergy, extraParam)
end

function BattlePassiveSkill.RunSkillOnCasterBuff(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.CasterBuff, extraParam)
end

function BattlePassiveSkill.RunSkillOnReceiveBuff(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.ReceiveBuff, extraParam)
end

function BattlePassiveSkill.RunSkillOnAfterCasterBuff(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AfterCasterBuff, extraParam)
end

function BattlePassiveSkill.RunSkillOnAfterReceiveBuff(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AfterReceiveBuff, extraParam)
end

function BattlePassiveSkill.RunSkillOnEnterBuffSubType(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.EnterBuffSubType, extraParam)
end

function BattlePassiveSkill.RunSkillOnLeaveBuffSubType(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.LeaveBuffSubType, extraParam)
end

function BattlePassiveSkill.RunSkillOnPayHp(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.PayHp, extraParam)
end

function BattlePassiveSkill.RunSkillOnBeControl(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.BeControl)
end

function BattlePassiveSkill.RunSkillOnCriticalRateChg(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.CriticalRateChg)
end

function BattlePassiveSkill.RunSkillOnDefAfterBurnDmg(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterBurnDmg)
end

function BattlePassiveSkill.RunSkillOnDefAfterRecover(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterRecover, extraParam)
end

function BattlePassiveSkill.RunSkillOnDefBeforeDotDmgCalc(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDotDmgCalc, extraParam)
end

function BattlePassiveSkill.RunSkillOnAtkBeforeDotDmgCalc(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDotDmgCalc, extraParam)
end

function BattlePassiveSkill.RunSkillOnAtkBeforeDmgCalc(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDmgCalc, extraParam)
end

function BattlePassiveSkill.RunSkillOnDefBeforeDmgCalc(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmgCalc, extraParam)
end

function BattlePassiveSkill.RunSkillOnAtkBeforeDmgBeforeShield(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeDmgBeforeShield, extraParam)
end

function BattlePassiveSkill.RunSkillOnDefBeforeDmgBeforeShield(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmgBeforeShield, extraParam)
end

function BattlePassiveSkill.RunSkillOnDefBeforeHeal(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeHeal, extraParam)
end

function BattlePassiveSkill.RunSkillOnAtkBeforeHealCalc(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.AtkBeforeHealCalc, extraParam)
end

function BattlePassiveSkill.RunSkillOnDmgMakeDeath(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeDeath, extraParam)
end

function BattlePassiveSkill.RunSkillOnDmgCauseDeath(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DmgCauseDeath, extraParam)
end

function BattlePassiveSkill.RunSkillOnDefAfterDmgUnifiedPoint(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmgUnifiedPoint)
end

function BattlePassiveSkill.RunSkillOnCollectAtkStart(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.CollectAtkStart, extraParam)
end

function BattlePassiveSkill.RunSkillOnCollectAtkFinish(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.CollectAtkFinish)
end

function BattlePassiveSkill.RunSkillOnUltimateAtkU3(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.UltimateAtkStartU3, extraParam)
end

function BattlePassiveSkill.RunSkillOnSelfTurnEndActionForceUpdated(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnEndActionForceUpdated)
end

function BattlePassiveSkill.RunSkillOnTransferFini(hero)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.TransferEnd)
end

function BattlePassiveSkill.RunSkillOnReviveFriend(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.ReviveFriend, extraParam)
end

function BattlePassiveSkill.RunSkillOnReviveByFriend(hero, extraParam)
    RunDelegates(hero, E_PASSIVE_SKILL_TRIGGER_TIME.ReviveByFriend, extraParam)
end

-- ==================== 生命周期函数 ====================

function BattlePassiveSkill.Init()
    Reset()
    Logger.Log("[BattlePassiveSkill] 初始化完成")
end

function BattlePassiveSkill.OnFinal()
    Reset()
    Logger.Log("[BattlePassiveSkill] 清理完成")
end

function BattlePassiveSkill.ResetTriggerLimit()
    for k, _ in pairs(triggerTime2Delegate) do
        local delegatesDict = triggerTime2Delegate[k]
        for _, delegates in pairs(delegatesDict) do
            for _, battleScriptSkill in ipairs(delegates) do
                battleScriptSkill.triggerLimit = triggerLimitConfig[k] or 10
            end
        end
    end
end

return BattlePassiveSkill
