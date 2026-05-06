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
local SkillTimeline = require("core.skill_timeline")
local BattleVisualEvents = require("ui.battle_visual_events")
local ConsoleRenderer = require("ui.console_renderer")
local BattleRhythmConfig = require("config.battle_rhythm_config")

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
local roundParticipants = {}
local roundActed = {}

-- 战斗结果
local battleResult = {
    winner = nil,  -- "left", "right", "draw", nil
    isFinished = false,
    reason = nil,  -- 结束原因
}

local currentAction = nil
local actionPostGapRemainingMs = 0
local queuedUltimateByHero = {}

local function SafeClock()
    local ok, result = pcall(function()
        if os and os.clock then
            return os.clock()
        end
        return 0
    end)

    if ok and type(result) == "number" then
        return result
    end

    return 0
end

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
    roundParticipants = {}
    roundActed = {}
    queuedUltimateByHero = {}
    battleResult = {
        winner = nil,
        isFinished = false,
        reason = nil,
    }
    currentAction = nil
    actionPostGapRemainingMs = 0
end

local function GetHeroBattleId(hero)
    if not hero then
        return nil
    end
    return hero.instanceId or hero.id
end

local function BuildRoundParticipants()
    local participants = {}
    for _, hero in ipairs(BattleFormation.GetAllHeroes() or {}) do
        local heroId = GetHeroBattleId(hero)
        if hero and heroId and hero.isAlive and not hero.isDead then
            participants[heroId] = true
        end
    end
    return participants
end

local function StartNextCombatRound()
    currentRound = currentRound + 1
    roundParticipants = BuildRoundParticipants()
    roundActed = {}
end

local function EnsureCombatRound(hero)
    if currentRound <= 0 then
        StartNextCombatRound()
    end

    local heroId = GetHeroBattleId(hero)
    if heroId and not roundParticipants[heroId] then
        roundParticipants[heroId] = true
    end
end

local function MarkHeroActedAndAdvanceRound(hero)
    local heroId = GetHeroBattleId(hero)
    if heroId then
        roundActed[heroId] = true
    end

    for participantId in pairs(roundParticipants) do
        local participant = BattleFormation.FindHeroByInstanceId(participantId)
        local stillNeedsTurn = participant and participant.isAlive and not participant.isDead and not roundActed[participantId]
        if stillNeedsTurn then
            return
        end
    end

    StartNextCombatRound()
end

local function SelectNextRoundHero()
    if currentRound <= 0 then
        StartNextCombatRound()
    end

    local candidates = {}
    for _, hero in ipairs(BattleFormation.GetAllHeroes() or {}) do
        local heroId = GetHeroBattleId(hero)
        if hero and heroId and roundParticipants[heroId] and not roundActed[heroId] and hero.isAlive and not hero.isDead then
            local initiative = BattleActionOrder.GetHeroInitiative and BattleActionOrder.GetHeroInitiative(hero) or { total = 0 }
            candidates[#candidates + 1] = {
                hero = hero,
                initiative = initiative.total or 0,
                id = heroId,
            }
        end
    end

    if #candidates == 0 then
        StartNextCombatRound()
        for _, hero in ipairs(BattleFormation.GetAllHeroes() or {}) do
            local heroId = GetHeroBattleId(hero)
            if hero and heroId and roundParticipants[heroId] and not roundActed[heroId] and hero.isAlive and not hero.isDead then
                local initiative = BattleActionOrder.GetHeroInitiative and BattleActionOrder.GetHeroInitiative(hero) or { total = 0 }
                candidates[#candidates + 1] = {
                    hero = hero,
                    initiative = initiative.total or 0,
                    id = heroId,
                }
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.initiative ~= b.initiative then
            return a.initiative > b.initiative
        end
        return tostring(a.id) < tostring(b.id)
    end)

    return candidates[1] and candidates[1].hero or nil
end

--- 初始化所有子系统
---@param beginState table 战斗开始状态
local function InitSubsystems(beginState)
    Logger.Log("BattleMain.InitSubsystems - 开始初始化子系统")

    -- 1. 初始化战斗数学模块（随机数生成器）
    if beginState.seedArray then
        BattleMath.Init(beginState.seedArray)
        -- Keep Lua's global RNG deterministic too, since some subsystems still use math.random.
        math.randomseed(tonumber(beginState.seedArray[1]) or 123456789)
    else
        -- 使用默认种子
        BattleMath.Init({123456789, 362436069, 521288629, 88675123})
        math.randomseed(123456789)
    end
    Logger.Debug("  BattleMath 初始化完成")

    -- 2. 初始化事件系统
    BattleEvent.Init()
    Logger.Debug("  BattleEvent 初始化完成")

    SkillTimeline.Reset()
    Logger.Debug("  SkillTimeline 状态重置完成")

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

    BattlePassiveSkill.Init()
    Logger.Debug("  BattlePassiveSkill 初始化完成")

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

    -- Seed initial energy for CLI/runtime battles driven by BattleMain.
    -- (Browser runtime seeds energy separately.)
    local initialEnergy = beginState and beginState.initialEnergy
    if initialEnergy == nil then
        initialEnergy = BattleEnergy.GetDefaultInitialEnergy()
    end
    initialEnergy = tonumber(initialEnergy) or 0
    if initialEnergy > 0 then
        for _, hero in ipairs(allHeroes) do
            if hero and not hero.isDead then
                BattleEnergy.AddEnergy(hero, initialEnergy, "initial_energy", { silent = true })
            end
        end
    end

    -- 10. 初始化伤害/治疗系统
    BattleDmgHeal.Init()
    Logger.Debug("  BattleDmgHeal 初始化完成")

    -- 11.5 注册Roguelike被动技能到 BattlePassiveSkill 系统
    -- 被动技能已经在英雄创建时通过 AddPassiveSkill2TriggerTime 注册
    Logger.Debug("  Roguelike被动技能注册完成")

    -- 12. 初始化渲染器
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
    BattlePassiveSkill.OnFinal()
    BattleDmgHeal.OnFinal()
    BattleEnergy.OnFinal()
    BattleBuff.OnFinal()
    BattleSkill.OnFinal()
    BattleAttribute.OnFinal()
    BattleActionOrder.OnFinal()
    SkillTimeline.Reset()
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
    if currentAction then
        return
    end

    if not isRunning or isPaused then
        return
    end

    -- 检查战斗是否已结束
    local isEnd, winner, reason = CheckBattleEnd()
    if isEnd then
        TriggerBattleEnd(winner, reason)
        return
    end

    local hero = SelectNextRoundHero()

    if hero then
        Logger.Log(string.format("[行动] 英雄 %s 开始行动", hero.name or "Unknown"))

        -- 触发回合开始事件
        BattleEvent.Publish(BattleVisualEvents.TURN_STARTED, BattleVisualEvents.BuildTurnEvent(
            BattleVisualEvents.TURN_STARTED, currentRound, hero))

        currentAction = {
            hero = hero,
            waitingForTimeline = false,
            completed = false,
        }

        local isPending = BattleMain.ExecuteHeroAction(hero, currentAction)
        if not isPending then
            BattleMain.CompleteHeroAction(currentAction)
        end
    end
end

-- ==================== 公共接口 ====================

--- 启动战斗
---@param beginState table 战斗开始状态，包含 teamLeft, teamRight, seedArray 等
---@param onBattleEnd function 战斗结束回调函数 (result)
function BattleMain.Start(beginState, onBattleEnd)
    local function runStage(name, fn)
        local ok, result = pcall(fn)
        if not ok then
            error("BattleMain.Start stage '" .. tostring(name) .. "' failed [type=" .. type(result) .. "] " .. tostring(result))
        end
        return result
    end

    Logger.Log("============================================")
    Logger.Log("BattleMain.Start - 战斗开始")
    Logger.Log("============================================")

    -- 重置状态
    runStage("reset_state", function()
        ResetState()
    end)

    -- 保存参数
    battleBeginState = beginState or {}
    onBattleEndCallback = onBattleEnd

    -- 初始化所有子系统
    runStage("init_subsystems", function()
        InitSubsystems(battleBeginState)
    end)

    -- 设置战斗状态
    runStage("set_running_state", function()
        currentBattleState = E_BATTLE_STATE.IN_BATTLE
        isRunning = true
        lastUpdateTime = SafeClock()
    end)

    -- 发布战斗开始事件（旧版兼容）
    runStage("publish_battle_start", function()
        BattleEvent.Publish("BattleStart", battleBeginState)
    end)
    
    -- 触发可视化战斗开始事件
    runStage("publish_visual_battle_started", function()
        BattleEvent.Publish(BattleVisualEvents.BATTLE_STARTED, {
            eventType = BattleVisualEvents.BATTLE_STARTED,
            teamLeft = beginState.teamLeft,
            teamRight = beginState.teamRight,
        })
    end)

    runStage("run_passives_on_battle_begin", function()
        BattlePassiveSkill.RunSkillOnBattleBegin()
    end)

    Logger.Log("BattleMain.Start - 战斗初始化完成，进入战斗状态")
end

--- 选择可用技能（玩家侧大招由外部指令触发；敌方 AI 可自动释放大招）
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

    local heroId = GetHeroBattleId(hero)
    local queuedUltimate = heroId and queuedUltimateByHero[tostring(heroId)]
    if hero and hero.isLeft and queuedUltimate then
        for skillId, skill in pairs(availableSkills) do
            if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then
                local cd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
                local charges = tonumber(hero.ultimateCharges)
                local maxCharges = tonumber(hero.ultimateChargesMax) or 1
                if charges == nil then
                    charges = maxCharges
                end
                queuedUltimateByHero[tostring(heroId)] = nil
                if cd == 0 and charges > 0 then
                    Logger.Log(string.format("[SelectAvailableSkill] %s 使用已排队大招: %s",
                        hero.name or "Unknown", skill.name or tostring(skillId)))
                    return skill
                end
                break
            end
        end
    end

    -- Enemy AI auto-casts ultimate when ready. Player side still uses manual/auto queue.
    if hero and not hero.isLeft then
        for skillId, skill in pairs(availableSkills) do
            if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then
                local cd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
                if cd == 0 and BattleEnergy.CanCastUltimate(hero, skill) then
                    Logger.Log(string.format("[SelectAvailableSkill] %s 敌方自动选择大招: %s",
                        hero.name or "Unknown", skill.name or tostring(skillId)))
                    return skill
                end
            end
        end
    end
    
    -- 如果没有可用的大招，检查主动技能（不耗能量，有CD冷却）
    for skillId, skill in pairs(availableSkills) do
        if skill and skill.skillType == E_SKILL_TYPE_ACTIVE then
            local cd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
            if cd == 0 then
                Logger.Log(string.format("[SelectAvailableSkill] %s 选择主动技能: %s (CD:%d/%d)",
                    hero.name or "Unknown", skill.name or tostring(skillId),
                    cd, skill.maxCoolDown or 0))
                return skill
            else
                Logger.Log(string.format("[SelectAvailableSkill] %s 主动技能冷却中: %s (剩余CD:%d)",
                    hero.name or "Unknown", skill.name or tostring(skillId), cd))
            end
        end
    end
    
    -- 如果没有可用的大招和主动技能，使用普通攻击
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
local function FinalizeHeroTurn(hero)
    if not hero or not hero.isAlive then
        return
    end

    -- 回合结束增加能量
    BattleEnergy.OnActionEnd(hero)

    -- 减少技能冷却
    BattleSkill.ReduceCoolDown(hero, 1)

    -- 更新 Buff 持续时间
    local BattleBuff = require("modules.battle_buff")
    BattleBuff.OnRoundEnd(hero)
end

function BattleMain.ExecuteHeroAction(hero, actionState)
    if not hero or not hero.isAlive then
        return false
    end

    -- 触发回合开始被动技能
    BattlePassiveSkill.RunSkillOnSelfTurnBegin(hero)
    if not BattleSkill.ProcessTurnStartStatus(hero) then
        return false
    end

    -- 智能选择可用技能
    local skill = SelectAvailableSkill(hero)
    if not skill then
        Logger.LogWarning(string.format("[ExecuteHeroAction] %s 没有可用技能，跳过行动", hero.name or "Unknown"))
        return false
    end
    
    if skill and skill.skillId then
        -- 获取随机敌人作为目标
        -- region debug-point enemy-no-damage-target
        local targetId = BattleFormation.GetRandomEnemyInstanceId(hero)
        Logger.Log(string.format("[DBG enemy-no-damage target] actor=%s actorId=%s isLeft=%s targetId=%s",
            tostring(hero.name), tostring(hero.instanceId), tostring(hero.isLeft), tostring(targetId)))
        -- endregion debug-point enemy-no-damage-target
        if targetId then
            local target = BattleFormation.FindHeroByInstanceId(targetId)
            if target then
                -- region debug-point enemy-no-damage-target-resolved
                Logger.Log(string.format("[DBG enemy-no-damage target-resolved] actor=%s actorLeft=%s target=%s targetLeft=%s",
                    tostring(hero.name), tostring(hero.isLeft), tostring(target.name), tostring(target.isLeft)))
                -- endregion debug-point enemy-no-damage-target-resolved
                Logger.Log(string.format("[行动]   %s 对 %s 使用技能 [%s]", 
                    hero.name or "Unknown", 
                    target.name or "Unknown", 
                    skill.name or tostring(skill.skillId)))
                
                -- 执行技能
                local started = BattleSkill.StartSkillCastInSeq(hero, target, skill.skillId, function(success, result)
                    if actionState then
                        actionState.timelineSucceeded = success
                        actionState.timelineResult = result
                        actionState.completed = true
                    end
                end)
                if started then
                    if actionState then
                        actionState.waitingForTimeline = true
                    end
                    return true
                end
            end
        end
    end

    return false
end

function BattleMain.CompleteHeroAction(actionState)
    if not actionState or not actionState.hero then
        currentAction = nil
        return
    end

    local hero = actionState.hero
    BattlePassiveSkill.RunSkillOnSelfTurnEnd(hero)
    FinalizeHeroTurn(hero)

    BattleActionOrder.OnHeroActionFinish(hero)

    BattleEvent.Publish(BattleVisualEvents.TURN_ENDED, BattleVisualEvents.BuildTurnEvent(
        BattleVisualEvents.TURN_ENDED, currentRound, hero))
    MarkHeroActedAndAdvanceRound(hero)

    Logger.Log(string.format("[行动] 英雄 %s 行动结束", hero.name or "Unknown"))
    actionPostGapRemainingMs = math.max(0, tonumber(BattleRhythmConfig.postGapMs) or 0)
    currentAction = nil
end

--- 更新战斗（每帧调用）
function BattleMain.Update(deltaMs)
    if not isRunning then
        return
    end

    -- 检查是否需要更新（基于 updateInterval）
    local currentTime = SafeClock()
    local timeDiff = currentTime - lastUpdateTime
    
    if timeDiff < updateInterval then
        return
    end
    lastUpdateTime = currentTime

    -- 更新计时器
    BattleTimer.Update()

    if SkillTimeline.IsRunning() then
        SkillTimeline.Update(deltaMs)
        if SkillTimeline.IsRunning() then
            return
        end
    end

    -- 如果战斗已结束，不再执行逻辑
    if battleResult.isFinished then
        return
    end

    -- 如果未暂停，执行战斗逻辑
    if not isPaused then
        if currentAction then
            if currentAction.waitingForTimeline and not SkillTimeline.IsRunning() and currentAction.completed then
                BattleMain.CompleteHeroAction(currentAction)
            end
            return
        end
        if actionPostGapRemainingMs > 0 then
            actionPostGapRemainingMs = math.max(0, actionPostGapRemainingMs - math.max(0, deltaMs or 0))
            return
        end
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
    lastUpdateTime = SafeClock()  -- 重置时间戳，防止瞬间大量更新
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

function BattleMain.GetActiveHeroInstanceId()
    if currentAction and currentAction.hero then
        return currentAction.hero.instanceId or currentAction.hero.id
    end
    return SkillTimeline.GetActiveHeroId()
end

function BattleMain.QueueUltimate(heroId)
    if heroId == nil then
        return false
    end
    queuedUltimateByHero[tostring(heroId)] = true
    return true
end

function BattleMain.HasQueuedUltimate(heroId)
    if heroId == nil then
        return false
    end
    return queuedUltimateByHero[tostring(heroId)] == true
end

function BattleMain.GetQueuedUltimateCount()
    local count = 0
    for _ in pairs(queuedUltimateByHero) do
        count = count + 1
    end
    return count
end

-- Browser/runtime command gate:
-- accept manual/auto commands only when battle is idle and not in post-gap.
function BattleMain.CanAcceptExternalCommand()
    if not isRunning or isPaused then
        return false
    end
    if battleResult and battleResult.isFinished then
        return false
    end
    if currentAction then
        return false
    end
    if SkillTimeline.IsRunning() then
        return false
    end
    return (tonumber(actionPostGapRemainingMs) or 0) <= 0
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
