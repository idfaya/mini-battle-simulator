local oneFrameTick = 30
local curTick = 0
local callbacks = {}
local firstPassCallbacks = {}

local function Reset()
    curTick = 0
    callbacks = {}
    firstPassCallbacks = {}
end

local function RunCallbacks(lCallback, curTick)
    local n = #lCallback
    local removeIndex = {}

    for i = 1, n do
        local instance = lCallback[i]
        if instance.endTick <= curTick then
            instance.callback()
            table.insert(removeIndex, i)
        end
    end

    for i = #removeIndex, 1, -1 do
        table.remove(lCallback, removeIndex[i])
    end
end

local function Ceil(value)
    return math.ceil(value)
end

local function TableQuickInsert(t, value)
    table.insert(t, value)
end

BattleTimer = {}

function BattleTimer.Init()
    Reset()
end

function BattleTimer.OnFinal()
    Reset()
end

function BattleTimer.GetTick()
    return curTick
end

function BattleTimer.Update()
    curTick = curTick + 1

    RunCallbacks(firstPassCallbacks, curTick)
    RunCallbacks(callbacks, curTick)
end

function BattleTimer.AddTimer(duration, callback)
    local tick = Ceil(duration * oneFrameTick)
    TableQuickInsert(callbacks, {endTick = curTick + tick, callback = callback})
end

function BattleTimer.AddTickTimer(tick, callback)
    TableQuickInsert(callbacks, {endTick = curTick + tick, callback = callback})
end

function BattleTimer.AddFirstPassTimer(duration, callback)
    local tick = Ceil(duration * oneFrameTick)
    TableQuickInsert(firstPassCallbacks, {endTick = curTick + tick, callback = callback})
end

function BattleTimer.AddFirstPassTickTimer(tick, callback)
    TableQuickInsert(firstPassCallbacks, {endTick = curTick + tick, callback = callback})
end

function BattleTimer.Duration2Tick(duration)
    local tick = Ceil(duration * oneFrameTick)
    return tick
end

function BattleTimer.Tick2Duration(tick)
    return tick / oneFrameTick
end

return BattleTimer
