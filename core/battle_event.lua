---
--- Battle Event Module
--- 战斗事件模块
---

local Logger = require("utils.logger")

local BattleEvent = {}

-- 空函数占位符，用于标记已移除的监听器
local nullFunction = function() end

-- 监听器存储表：{ [eventName] = { handler1, handler2, ... } }
local listeners = {}

-- 迭代锁计数器，用于安全迭代
local lockCount = 0

-- 延迟移除标志
local hasDelayRemove = false

--- 初始化事件模块
function BattleEvent.Init()
    -- 清空所有监听器
    for k, _ in pairs(listeners) do
        listeners[k] = nil
    end
    lockCount = 0
    hasDelayRemove = false
    Logger.Debug("BattleEvent.Init() - 事件模块已初始化")
end

--- 清理所有监听器（在模块结束时调用）
function BattleEvent.OnFinal()
    for k, _ in pairs(listeners) do
        listeners[k] = nil
    end
    lockCount = 0
    hasDelayRemove = false
    Logger.Debug("BattleEvent.OnFinal() - 所有监听器已清除")
end

--- 添加事件监听器
---@param eventName string 事件名称
---@param handler function 事件处理函数
function BattleEvent.AddListener(eventName, handler)
    if type(eventName) ~= "string" then
        Logger.LogError(string.format("BattleEvent.AddListener: eventName must be string, got %s", type(eventName)))
        return
    end
    if type(handler) ~= "function" then
        Logger.LogError(string.format("BattleEvent.AddListener: handler must be function, got %s", type(handler)))
        return
    end

    if not listeners[eventName] then
        listeners[eventName] = {}
    end

    table.insert(listeners[eventName], handler)
    Logger.Debug(string.format("BattleEvent.AddListener: 已添加监听器 [%s]", eventName))
end

--- 移除事件监听器
--- 如果在迭代过程中（lock > 0），则使用延迟移除策略（替换为 nullFunction）
---@param eventName string 事件名称
---@param handler function 要移除的事件处理函数
function BattleEvent.RemoveListener(eventName, handler)
    if type(eventName) ~= "string" then
        Logger.LogError(string.format("BattleEvent.RemoveListener: eventName must be string, got %s", type(eventName)))
        return
    end
    if type(handler) ~= "function" then
        Logger.LogError(string.format("BattleEvent.RemoveListener: handler must be function, got %s", type(handler)))
        return
    end

    local eventListeners = listeners[eventName]
    if not eventListeners then
        return
    end

    for i, h in ipairs(eventListeners) do
        if h == handler then
            if lockCount > 0 then
                -- 处于迭代中，使用占位符标记延迟移除
                eventListeners[i] = nullFunction
                hasDelayRemove = true
                Logger.Debug(string.format("BattleEvent.RemoveListener: 标记延迟移除 [%s]", eventName))
            else
                -- 直接移除
                table.remove(eventListeners, i)
                Logger.Debug(string.format("BattleEvent.RemoveListener: 已移除监听器 [%s]", eventName))
            end
            return
        end
    end
end

--- 发布事件
--- 使用 pcall 保护每个处理器的执行
---@param eventName string 事件名称
---@param ... any 传递给处理器的参数
function BattleEvent.Publish(eventName, ...)
    if type(eventName) ~= "string" then
        Logger.LogError(string.format("BattleEvent.Publish: eventName must be string, got %s", type(eventName)))
        return
    end

    local eventListeners = listeners[eventName]
    if not eventListeners or #eventListeners == 0 then
        return
    end

    -- 增加锁计数，防止在迭代过程中修改列表
    lockCount = lockCount + 1

    for i, handler in ipairs(eventListeners) do
        if handler ~= nullFunction then
            -- 使用 pcall 保护执行
            local success, err = pcall(handler, ...)
            if not success then
                Logger.LogError(string.format("BattleEvent.Publish: 事件处理器执行失败 [%s] - %s", eventName, tostring(err)))
            end
        end
    end

    -- 减少锁计数
    lockCount = lockCount - 1

    -- 如果没有锁了且有延迟移除的标记，清理 nullFunction
    if lockCount == 0 and hasDelayRemove then
        BattleEvent.CleanNullListeners()
    end
end

--- 清理所有标记为 nullFunction 的监听器
--- 在迭代完成后调用
function BattleEvent.CleanNullListeners()
    for eventName, eventListeners in pairs(listeners) do
        local writeIndex = 1
        for readIndex = 1, #eventListeners do
            local handler = eventListeners[readIndex]
            if handler ~= nullFunction then
                if writeIndex ~= readIndex then
                    eventListeners[writeIndex] = handler
                end
                writeIndex = writeIndex + 1
            end
        end
        -- 移除末尾多余的元素
        for i = #eventListeners, writeIndex, -1 do
            eventListeners[i] = nil
        end

        -- 如果该事件没有监听器了，删除该键
        if #eventListeners == 0 then
            listeners[eventName] = nil
        end
    end
    hasDelayRemove = false
    Logger.Debug("BattleEvent.CleanNullListeners: 已清理所有 null 监听器")
end

--- 获取指定事件的监听器数量（用于测试）
---@param eventName string 事件名称
---@return number 监听器数量
function BattleEvent.GetListenerCount(eventName)
    local eventListeners = listeners[eventName]
    if not eventListeners then
        return 0
    end

    local count = 0
    for _, handler in ipairs(eventListeners) do
        if handler ~= nullFunction then
            count = count + 1
        end
    end
    return count
end

--- 获取 nullFunction（用于测试比较）
function BattleEvent.GetNullFunction()
    return nullFunction
end

return BattleEvent
