--[[
    战斗驱动模块
    负责驱动战斗循环，处理回合更新和显示刷新
--]]

local BattleDriver = {}

-- 依赖模块
local BattleMain = require("modules.battle_main")
local ConsoleRenderer = require("ui.console_renderer")
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

local _startCounter = 0

--- 生成战斗随机种子，确保每次开局（包括重开）都不同
---@return table
local function GenerateSeedArray()
    _startCounter = _startCounter + 1

    local now = os.time()
    local clockMicros = math.floor((os.clock() * 1000000) % 2147483647)

    local seed1 = (now + _startCounter * 10007) % 2147483647
    local seed2 = (clockMicros + _startCounter * 30011 + now) % 2147483647
    local seed3 = (seed1 ~ seed2) % 2147483647
    local seed4 = (seed1 * 1103515245 + seed2 * 12345 + _startCounter) % 2147483647

    if seed1 == 0 then seed1 = 123456789 end
    if seed2 == 0 then seed2 = 362436069 end
    if seed3 == 0 then seed3 = 521288629 end
    if seed4 == 0 then seed4 = 88675123 end

    return {seed1, seed2, seed3, seed4}
end

--- 简单的睡眠函数（毫秒）
local function Sleep(ms)
    if ms <= 0 then return end
    local start = os.clock()
    while (os.clock() - start) * 1000 < ms do
        -- 忙等待
    end
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
    if not battleConfig.disableDefaultRenderer then
        ConsoleRenderer.ClearScreen()
        
        -- 显示初始战场
        ConsoleRenderer.Refresh()
    end
    
    -- 每次开局都刷新随机种子，避免重开关卡时复用同一套随机序列
    battleConfig.seedArray = GenerateSeedArray()

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
    
    -- 根据速度设置添加延迟
    if _config.updateInterval > 0 then
        Sleep(_config.updateInterval)
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
    ConsoleRenderer.ClearBattleLog()
    _isRunning = false
    _battleFinished = false
    _battleResult = nil
end

return BattleDriver
