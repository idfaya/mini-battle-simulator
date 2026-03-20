--[[
    战斗驱动模块
    负责驱动战斗循环，处理回合更新和显示刷新
--]]

local BattleDriver = {}

-- 依赖模块
local BattleMain = require("modules.battle_main")
local BattleDisplay = require("ui.battle_display")
local BattleEvent = require("core.battle_event")
local BattleFormation = require("modules.battle_formation")
local BattleActionOrder = require("modules.battle_action_order")

-- 默认配置
local DEFAULT_CONFIG = {
    maxSteps = 20000,        -- 最大步数
    updateInterval = 0,      -- 更新间隔（毫秒）
    refreshInterval = 10,    -- 每N步强制刷新一次
}

-- 当前状态
local _isRunning = false
local _step = 0
local _lastRound = -1
local _lastActionHero = nil
local _battleFinished = false
local _battleResult = nil
local _config = {}

--- 简单的睡眠函数（毫秒）
local function Sleep(ms)
    if ms <= 0 then return end
    local start = os.clock()
    while (os.clock() - start) * 1000 < ms do
        -- 忙等待
    end
end

--- 检查是否需要刷新显示
---@return boolean 是否需要刷新
local function ShouldRefresh()
    -- 获取当前回合和行动英雄
    local currentRound = BattleMain.GetCurrentRound()
    local currentActionHero = nil
    
    if BattleActionOrder and BattleActionOrder.GetCurrentHero then
        currentActionHero = BattleActionOrder.GetCurrentHero()
    end
    
    local shouldRefresh = false
    
    -- 回合变化时刷新
    if currentRound ~= _lastRound then
        BattleDisplay.AddBattleLog(string.format("========== 回合 %d ==========", currentRound))
        _lastRound = currentRound
        shouldRefresh = true
    end
    
    -- 行动英雄变化时刷新
    if currentActionHero and currentActionHero ~= _lastActionHero then
        _lastActionHero = currentActionHero
        shouldRefresh = true
    end
    
    -- 定期刷新（确保事件被显示）
    if _step % _config.refreshInterval == 0 then
        shouldRefresh = true
    end
    
    return shouldRefresh
end

--- 初始化战斗驱动
---@param config table 配置参数
function BattleDriver.Init(config)
    _config = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        _config[k] = config and config[k] or v
    end
    
    _isRunning = false
    _step = 0
    _lastRound = -1
    _lastActionHero = nil
    _battleFinished = false
    _battleResult = nil
end

--- 开始战斗
---@param battleConfig table 战斗配置 {teamLeft, teamRight, seedArray}
---@param onBattleEnd function 战斗结束回调 function(result)
function BattleDriver.Start(battleConfig, onBattleEnd)
    if _isRunning then
        return false, "战斗正在进行中"
    end
    
    _isRunning = true
    _step = 0
    _lastRound = -1
    _lastActionHero = nil
    _battleFinished = false
    _battleResult = nil
    
    -- 清屏准备战斗显示
    BattleDisplay.ClearScreen()
    
    -- 启动战斗
    BattleMain.Start(battleConfig, function(result)
        _battleResult = result
        _battleFinished = true
        _isRunning = false
        
        if onBattleEnd then
            onBattleEnd(result)
        end
    end)
    
    return true
end

--- 更新战斗（每帧调用）
---@return boolean 是否继续运行
function BattleDriver.Update()
    if not _isRunning or _battleFinished then
        return false
    end
    
    if _step >= _config.maxSteps then
        _isRunning = false
        return false
    end
    
    -- 执行战斗更新
    BattleMain.Update()
    _step = _step + 1
    
    -- 检查是否需要刷新显示
    if ShouldRefresh() then
        BattleDisplay.Refresh()
        
        -- 根据速度设置添加延迟
        if _config.updateInterval > 0 then
            Sleep(_config.updateInterval)
        end
    end
    
    return true
end

--- 驱动战斗直到结束（阻塞式）
---@return table 战斗结果
function BattleDriver.RunUntilEnd()
    while BattleDriver.Update() do
        -- 继续循环
    end
    return _battleResult
end

--- 获取当前状态
---@return table 当前状态 {isRunning, step, currentRound}
function BattleDriver.GetStatus()
    return {
        isRunning = _isRunning,
        step = _step,
        currentRound = _lastRound,
        battleFinished = _battleFinished
    }
end

--- 停止战斗
function BattleDriver.Stop()
    _isRunning = false
    _battleFinished = true
end

--- 清理资源
function BattleDriver.Cleanup()
    BattleMain.Quit()
    BattleDisplay.ClearBattleLog()
    _isRunning = false
    _battleFinished = false
    _battleResult = nil
end

return BattleDriver
