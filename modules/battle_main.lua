---
--- Battle Main Module
--- 战斗主模块 - 战斗的入口点和主循环控制
--- 适用于命令行环境，不依赖 Unity 协程
---

local Logger = require("utils.logger")
local BattleTimer = require("core.battle_timer")
local BattleEvent = require("core.battle_event")
local BattleMath = require("core.battle_math")
local BattleFormation = require("modules.battle_formation")
local BattleActionOrder = require("modules.battle_action_order")
local BattleAttribute = require("modules.battle_attribute")
local BattleSkill = require("modules.battle_skill")
local BattleBuff = require("modules.battle_buff")
local BattleEnergy = require("modules.battle_energy")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattlePassiveSkill = require("modules.battle_passive_skill")
local PassiveEffectHandler = require("modules.passive_effect_handler")
local BattleSkillSeq = require("modules.battle_skill_seq")
local BattleVisualEvents = require("ui.battle_visual_events")
local ConsoleRenderer = require("ui.console_renderer")

---@class BattleMain
local BattleMain = {}

-- ==================== 状态变量 ====================

-- 战斗是否正在运行
local isRunning = false

-- 战斗是否暂停
local isPaused = false

-- 更新间隔（秒）
local updateInterval = 0  -- 默认无间隔，每次调用都执行

-- 上次更新时间戳
local lastUpdateTime = 0

-- 战斗开始状态
local battleBeginState = nil

-- 战斗结束回调函数
local onBattleEndCallback = nil

-- 当前战斗状态
local currentBattleState = E_BATTLE_STATE.PREPARE

-- 最大战斗回合数
local MAX_BATTLE_ROUNDS = 100

-- 当前回合数
local currentRound = 0

-- 战斗结果
local battleResult = {
    winner = nil,  -- "left", "right", "draw", nil
    isFinished = false,
    reason = nil,  -- 结束原因
}

-- ==================== 内部函数 ====================

--- 重置所有状态
local function ResetState()
    isRunning = false
    isPaused = false
    lastUpdateTime = 0
    battleBeginState = nil
    onBattleEndCallback = nil
    currentBattleState = E_BATTLE_STATE.PREPARE
    currentRound = 0
    battleResult = {
        winner = nil,
        isFinished = false,
        reason = nil,
    }
end

--- 初始化所有子系统
---@param beginState table 战斗开始状态
local function InitSubsystems(beginState)
    Logger.Log("BattleMain.InitSubsystems - 开始初始化子系统")

    -- 1. 初始化战斗数学模块（随机数生成器）
    if beginState.seedArray then
        BattleMath.Init(beginState.seedArray)
    else
        -- 使用默认种子
        BattleMath.Init({123456789, 362436069, 521288629, 88675123})
    end
    Logger.Debug("  BattleMath 初始化完成")

    -- 2. 初始化事件系统
    BattleEvent.Init()
    Logger.Debug("  BattleEvent 初始化完成")

    -- 3. 初始化计时器
    BattleTimer.Init()
    Logger.Debug("  BattleTimer 初始化完成")

    -- 4. 初始化阵型系统
    BattleFormation.Init(beginState)
    Logger.Debug("  BattleFormation 初始化完成")

    -- 5. 初始化属性系统（必须在行动顺序系统之前，因为行动顺序需要读取英雄速度）
    BattleAttribute.Init()
    Logger.Debug("  BattleAttribute 初始化完成")

    -- 6. 为所有英雄初始化属性
    local allHeroes = BattleFormation.GetAllHeroes()
    for _, hero in ipairs(allHeroes) do
        if hero then
            -- 从英雄数据构建属性映射表
            local attributeMap = {
                [BattleAttribute.ATTR_ID.HP] = hero.maxHp or hero.hp or 100,
                [BattleAttribute.ATTR_ID.ATK] = hero.atk or 0,
                [BattleAttribute.ATTR_ID.DEF] = hero.def or 0,
                [BattleAttribute.ATTR_ID.SPEED] = hero.spd or hero.speed or 0,
                [BattleAttribute.ATTR_ID.CRIT_RATE] = hero.crt or hero.critRate or 0,
                [BattleAttribute.ATTR_ID.CRIT_DMG] = hero.crtd or hero.critDamage or 150,
                [BattleAttribute.ATTR_ID.HIT_RATE] = hero.hit or hero.hitRate or 100,
                [BattleAttribute.ATTR_ID.DODGE_RATE] = hero.res or hero.dodgeRate or 0,
                [BattleAttribute.ATTR_ID.DMG_REDUCE] = hero.damageReduce or 0,
                [BattleAttribute.ATTR_ID.DMG_INCREASE] = hero.damageIncrease or 0,
            }
            BattleAttribute.Init(hero, attributeMap)
        end
    end
    Logger.Debug("  所有英雄属性初始化完成，共 " .. #allHeroes .. " 名英雄")

    -- 7. 初始化行动顺序系统（在属性初始化之后）
    local teamLeft, teamRight = BattleFormation.GetTeams()
    BattleActionOrder.Init(teamLeft, teamRight)
    Logger.Debug("  BattleActionOrder 初始化完成")

    -- 8. 初始化技能系统（为每个英雄初始化技能）
    for _, hero in ipairs(allHeroes) do
        if hero then
            -- 从英雄数据中获取技能配置
            local skillsConfig = hero.skillsConfig or {}
            Logger.Log(string.format("[BattleMain] %s 的 skillsConfig: %d 个技能", 
                tostring(hero.name), #skillsConfig))
            for i, cfg in ipairs(skillsConfig) do
                Logger.Log(string.format("  [%d] skillId=%s, name=%s, type=%s", 
                    i, tostring(cfg.skillId), tostring(cfg.name), tostring(cfg.skillType)))
            end
            -- 初始化技能系统（不添加默认技能，保持原项目逻辑）
            BattleSkill.Init(hero, skillsConfig)
        end
    end
    Logger.Debug("  BattleSkill 初始化完成，共初始化 " .. #allHeroes .. " 名英雄的技能")

    -- 8. 初始化 Buff 系统
    BattleBuff.Init()
    Logger.Debug("  BattleBuff 初始化完成")

    -- 9. 初始化能量系统
    BattleEnergy.Init()
    Logger.Debug("  BattleEnergy 初始化完成")

    -- 10. 初始化伤害/治疗系统
    BattleDmgHeal.Init()
    Logger.Debug("  BattleDmgHeal 初始化完成")

    -- 11. 初始化被动技能系统
    BattlePassiveSkill.Init()
    Logger.Debug("  BattlePassiveSkill 初始化完成")

    -- 11.5 注册Roguelike被动技能到 BattlePassiveSkill 系统
    -- 被动技能已经在英雄创建时通过 AddPassiveSkill2TriggerTime 注册
    Logger.Debug("  Roguelike被动技能注册完成")

    -- 12. 初始化被动技能效果处理器
    PassiveEffectHandler.Init()
    Logger.Debug("  PassiveEffectHandler 初始化完成")

    -- 13. 初始化技能序列模块
    BattleSkillSeq.Init()
    Logger.Debug("  BattleSkillSeq 初始化完成")

    -- 14. 初始化渲染器
    if beginState.renderer then
        beginState.renderer.Init()
        Logger.Debug("  自定义渲染器初始化完成")
    elseif not beginState.disableDefaultRenderer then
        ConsoleRenderer.Init()
        Logger.Debug("  ConsoleRenderer 初始化完成")
    end

    Logger.Log("BattleMain.InitSubsystems - 所有子系统初始化完成")
end

--- 清理所有子系统
local function FinalizeSubsystems()
    Logger.Log("BattleMain.FinalizeSubsystems - 开始清理子系统")

    ConsoleRenderer.OnFinal()
    PassiveEffectHandler.OnFinal()
    BattlePassiveSkill.OnFinal()
    BattleDmgHeal.OnFinal()
    BattleEnergy.OnFinal()
    BattleBuff.OnFinal()
    BattleSkill.OnFinal()
    BattleAttribute.OnFinal()
    BattleActionOrder.OnFinal()
    BattleFormation.OnFinal()
    BattleTimer.OnFinal()
    BattleSkillSeq.OnFinal()
    BattleEvent.OnFinal()

    Logger.Log("BattleMain.FinalizeSubsystems - 所有子系统清理完成")
end

--- 检查战斗是否结束
---@return boolean 是否结束
---@return string|nil 获胜方 ("left", "right", "draw")
---@return string|nil 结束原因
local function CheckBattleEnd()
    -- 检查是否超过最大回合数
    if currentRound >= MAX_BATTLE_ROUNDS then
        return true, "draw", "达到最大回合数限制"
    end

    -- 检查左侧队伍是否全灭
    local leftAlive = BattleFormation.GetAliveHeroCount(true)
    -- 检查右侧队伍是否全灭
    local rightAlive = BattleFormation.GetAliveHeroCount(false)

    if leftAlive == 0 and rightAlive == 0 then
        return true, "draw", "双方同归于尽"
    elseif leftAlive == 0 then
        return true, "right", "左侧队伍全灭"
    elseif rightAlive == 0 then
        return true, "left", "右侧队伍全灭"
    end

    return false, nil, nil
end

--- 触发战斗结束
---@param winner string 获胜方
---@param reason string 结束原因
local function TriggerBattleEnd(winner, reason)
    if battleResult.isFinished then
        return
    end

    battleResult.isFinished = true
    battleResult.winner = winner
    battleResult.reason = reason
    currentBattleState = E_BATTLE_STATE.FINI_BATTLE

    Logger.Log(string.format("战斗结束! 获胜方: %s, 原因: %s", winner or "draw", reason))

    -- 调用结束回调
    if onBattleEndCallback then
        onBattleEndCallback(battleResult)
    end

    -- 发布战斗结束事件（旧版兼容）
    BattleEvent.Publish("BattleEnd", battleResult)
    
    -- 触发可视化战斗结束事件
    BattleEvent.Publish(BattleVisualEvents.BATTLE_ENDED, {
        eventType = BattleVisualEvents.BATTLE_ENDED,
        winner = winner,
        reason = reason,
    })
    
    -- 触发胜利/失败/平局事件
    if winner == "left" or winner == "right" then
        BattleEvent.Publish(BattleVisualEvents.VICTORY, BattleVisualEvents.BuildBattleResultEvent(
            BattleVisualEvents.VICTORY, winner, {}))
    elseif winner == "draw" then
        BattleEvent.Publish(BattleVisualEvents.DRAW, BattleVisualEvents.BuildBattleResultEvent(
            BattleVisualEvents.DRAW, winner, {}))
    end
end

--- 战斗逻辑 - 开始下一个行动
local function BeginNextAction()
    if not isRunning or isPaused then
        return
    end

    -- 检查战斗是否已结束
    local isEnd, winner, reason = CheckBattleEnd()
    if isEnd then
        TriggerBattleEnd(winner, reason)
        return
    end

    -- 循环运行行动顺序系统，直到找到下一个行动的英雄（跳过空转帧）
    local hero = nil
    local safetyCounter = 0
    while not hero and safetyCounter < 1000 do
        hero = BattleActionOrder.Run()
        safetyCounter = safetyCounter + 1
        
        -- 如果没有人行动，检查一下战斗是否因为其他原因结束（虽然不太可能，但为了安全）
        if not hero then
            local isEndLoop, winnerLoop, reasonLoop = CheckBattleEnd()
            if isEndLoop then
                TriggerBattleEnd(winnerLoop, reasonLoop)
                return
            end
        end
    end

    if hero then
        -- 增加回合数
        currentRound = currentRound + 1
        
        Logger.Log(string.format("[行动] 英雄 %s 开始行动", hero.name or "Unknown"))

        -- 触发回合开始事件
        BattleEvent.Publish(BattleVisualEvents.TURN_STARTED, BattleVisualEvents.BuildTurnEvent(
            BattleVisualEvents.TURN_STARTED, currentRound, hero))

        -- 执行英雄行动
        BattleMain.ExecuteHeroAction(hero)

        -- 行动结束
        BattleActionOrder.OnHeroActionFinish(hero)
        
        -- 触发回合结束事件
        BattleEvent.Publish(BattleVisualEvents.TURN_ENDED, BattleVisualEvents.BuildTurnEvent(
            BattleVisualEvents.TURN_ENDED, currentRound, hero))
        
        Logger.Log(string.format("[行动] 英雄 %s 行动结束", hero.name or "Unknown"))
    end
end

-- ==================== 公共接口 ====================

--- 启动战斗
---@param beginState table 战斗开始状态，包含 teamLeft, teamRight, seedArray 等
---@param onBattleEnd function 战斗结束回调函数 (result)
function BattleMain.Start(beginState, onBattleEnd)
    Logger.Log("============================================")
    Logger.Log("BattleMain.Start - 战斗开始")
    Logger.Log("============================================")

    -- 重置状态
    ResetState()

    -- 保存参数
    battleBeginState = beginState or {}
    onBattleEndCallback = onBattleEnd

    -- 初始化所有子系统
    InitSubsystems(battleBeginState)

    -- 设置战斗状态
    currentBattleState = E_BATTLE_STATE.IN_BATTLE
    isRunning = true
    lastUpdateTime = os.clock()

    -- 发布战斗开始事件（旧版兼容）
    BattleEvent.Publish("BattleStart", battleBeginState)
    
    -- 触发可视化战斗开始事件
    BattleEvent.Publish(BattleVisualEvents.BATTLE_STARTED, {
        eventType = BattleVisualEvents.BATTLE_STARTED,
        teamLeft = beginState.teamLeft,
        teamRight = beginState.teamRight,
    })

    BattlePassiveSkill.RunSkillOnBattleBegin()

    Logger.Log("BattleMain.Start - 战斗初始化完成，进入战斗状态")
end

--- 选择可用技能（优先选择冷却完成且能量足够的大招技能）
---@param hero table 英雄对象
---@return table 技能对象
local function SelectAvailableSkill(hero)
    -- 优先使用 skillsConfig（包含完整的技能配置信息）
    local skillsConfig = hero.skillsConfig
    if not skillsConfig or #skillsConfig == 0 then
        -- 回退到旧的 skills 格式
        if not hero.skills or #hero.skills == 0 then
            return nil
        end
        -- 将旧的格式转换为技能对象格式
        -- skills 可能是 {skillId, level} 对象数组，也可能是数字数组
        skillsConfig = {}
        for _, skillData in ipairs(hero.skills) do
            local skillId, skillType, skillName, skillCost
            if type(skillData) == "table" then
                -- 新格式: {skillId = xxx, level = yyy}
                skillId = skillData.skillId
                skillType = E_SKILL_TYPE_NORMAL
                skillName = "Skill_" .. tostring(skillId)
                skillCost = 0
            else
                -- 旧格式: 数字ID
                skillId = skillData
                skillType = E_SKILL_TYPE_NORMAL
                skillName = "Skill_" .. tostring(skillId)
                skillCost = 0
            end
            table.insert(skillsConfig, {
                skillId = skillId,
                skillType = skillType,
                name = skillName,
                skillCost = skillCost
            })
        end
    end
    
    -- 从 hero.skillData.skillInstances 中获取实际可用的技能
    local availableSkills = hero.skillData and hero.skillData.skillInstances or {}
    
    -- 遍历所有可用技能，找到冷却完成且能量足够的大招技能
    for skillId, skill in pairs(availableSkills) do
        if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then
            -- 检查冷却
            local cd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
            if cd == 0 then
                -- 检查能量
                local energyCost = skill.skillCost or 0
                if hero.curEnergy and hero.curEnergy >= energyCost then
                    Logger.Log(string.format("[SelectAvailableSkill] %s 选择大招: %s (能量:%d/%d)", 
                        hero.name or "Unknown", skill.name or tostring(skillId),
                        hero.curEnergy, energyCost))
                    return skill
                else
                    Logger.Log(string.format("[SelectAvailableSkill] %s 能量不足，无法使用大招 %s (能量:%d/%d)", 
                        hero.name or "Unknown", skill.name or tostring(skillId),
                        hero.curEnergy or 0, energyCost))
                end
            end
        end
    end
    
    -- 如果没有可用的大招，使用普通攻击
    for skillId, skill in pairs(availableSkills) do
        if skill and skill.skillType == E_SKILL_TYPE_NORMAL then
            return skill
        end
    end
    
    -- 默认返回第一个可用技能
    for _, skill in pairs(availableSkills) do
        if skill then
            return skill
        end
    end
    
    return nil
end

--- 执行英雄行动
---@param hero table 英雄对象
function BattleMain.ExecuteHeroAction(hero)
    if not hero or not hero.isAlive then
        return
    end

    -- 触发回合开始被动技能
    BattlePassiveSkill.RunSkillOnSelfTurnBegin(hero)

    -- 智能选择可用技能
    local skill = SelectAvailableSkill(hero)
    if not skill then
        Logger.LogWarning(string.format("[ExecuteHeroAction] %s 没有可用技能，跳过行动", hero.name or "Unknown"))
        return
    end
    
    if skill and skill.skillId then
        -- 获取随机敌人作为目标
        local targetId = BattleFormation.GetRandomEnemyInstanceId(hero)
        if targetId then
            local target = BattleFormation.FindHeroByInstanceId(targetId)
            if target then
                Logger.Log(string.format("[行动]   %s 对 %s 使用技能 [%s]", 
                    hero.name or "Unknown", 
                    target.name or "Unknown", 
                    skill.name or tostring(skill.skillId)))
                
                -- 如果是大招，消耗能量
                if skill.skillType == E_SKILL_TYPE_ULTIMATE then
                    local energyCost = skill.skillCost or 0
                    if energyCost > 0 then
                        BattleEnergy.ConsumeEnergy(hero, energyCost)
                    end
                end
                
                -- 执行技能
                BattleSkill.CastSkillInSeq(hero, target, skill.skillId)
            end
        end
    end

    -- 触发回合结束被动技能
    BattlePassiveSkill.RunSkillOnSelfTurnEnd(hero)

    -- 回合结束增加能量
    BattleEnergy.OnActionEnd(hero)
    
    -- 减少技能冷却
    BattleSkill.ReduceCoolDown(hero, 1)
end

--- 更新战斗（每帧调用）
function BattleMain.Update()
    if not isRunning then
        return
    end

    -- 检查是否需要更新（基于 updateInterval）
    local currentTime = os.clock()
    local timeDiff = currentTime - lastUpdateTime
    
    if timeDiff < updateInterval then
        return
    end
    lastUpdateTime = currentTime

    -- 更新计时器
    BattleTimer.Update()

    -- 如果战斗已结束，不再执行逻辑
    if battleResult.isFinished then
        return
    end

    -- 如果未暂停，执行战斗逻辑
    if not isPaused then
        BeginNextAction()
    end
end

--- 暂停战斗
function BattleMain.Pause()
    if not isRunning then
        Logger.LogWarning("BattleMain.Pause - 战斗未在运行")
        return
    end

    if isPaused then
        Logger.LogWarning("BattleMain.Pause - 战斗已经处于暂停状态")
        return
    end

    isPaused = true
    Logger.Log("BattleMain.Pause - 战斗已暂停")
    BattleEvent.Publish("BattlePause")
end

--- 恢复战斗
function BattleMain.Resume()
    if not isRunning then
        Logger.LogWarning("BattleMain.Resume - 战斗未在运行")
        return
    end

    if not isPaused then
        Logger.LogWarning("BattleMain.Resume - 战斗未处于暂停状态")
        return
    end

    isPaused = false
    lastUpdateTime = os.clock()  -- 重置时间戳，防止瞬间大量更新
    Logger.Log("BattleMain.Resume - 战斗已恢复")
    BattleEvent.Publish("BattleResume")
end

--- 退出战斗
function BattleMain.Quit()
    if not isRunning then
        Logger.LogWarning("BattleMain.Quit - 战斗未在运行")
        return
    end

    Logger.Log("BattleMain.Quit - 正在退出战斗")

    -- 触发战斗结束（无获胜方）
    TriggerBattleEnd(nil, "主动退出")

    -- 清理子系统
    FinalizeSubsystems()

    -- 重置状态
    ResetState()

    Logger.Log("BattleMain.Quit - 战斗已退出")
end

--- 检查战斗是否正在运行
---@return boolean 是否正在运行
function BattleMain.IsRunning()
    return isRunning
end

--- 检查战斗是否暂停
---@return boolean 是否暂停
function BattleMain.IsPaused()
    return isPaused
end

--- 设置更新间隔
---@param interval number 更新间隔（秒），设置为0表示无间隔
function BattleMain.SetUpdateInterval(interval)
    if type(interval) ~= "number" or interval < 0 then
        Logger.LogError("BattleMain.SetUpdateInterval - interval 必须是大于等于 0 的数字")
        return
    end

    updateInterval = interval
    Logger.Log(string.format("BattleMain.SetUpdateInterval - 更新间隔设置为 %.3f 秒", interval))
end

--- 获取更新间隔
---@return number 更新间隔（秒）
function BattleMain.GetUpdateInterval()
    return updateInterval
end

--- 获取当前战斗状态
---@return number 战斗状态 (E_BATTLE_STATE)
function BattleMain.GetBattleState()
    return currentBattleState
end

--- 获取当前回合数
---@return number 当前回合数
function BattleMain.GetCurrentRound()
    return currentRound
end

--- 获取战斗结果
---@return table 战斗结果 {winner, isFinished, reason}
function BattleMain.GetBattleResult()
    return battleResult
end

--- 获取战斗开始状态
---@return table 战斗开始状态
function BattleMain.GetBeginState()
    return battleBeginState
end

return BattleMain
