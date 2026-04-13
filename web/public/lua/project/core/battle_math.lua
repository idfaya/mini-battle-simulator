---
--- Battle Math Module
--- 战斗数学模块 - 提供可复现的随机数和数学工具函数
--- 使用 Xorshift128 算法确保客户端与服务器随机序列一致
---

local BattleMath = {}

-- Xorshift128 状态变量
local stateA, stateB, stateC, stateD

-- 是否已初始化
local isInitialized = false

--- 初始化随机数生成器
--- @param seedArray table 种子数组，包含4个整数
function BattleMath.Init(seedArray)
    if not seedArray or #seedArray < 4 then
        error("BattleMath.Init: seedArray must contain at least 4 integers")
    end
    
    -- 使用种子数组初始化 Xorshift128 状态
    -- 确保种子不为0
    stateA = seedArray[1] ~= 0 and seedArray[1] or 123456789
    stateB = seedArray[2] ~= 0 and seedArray[2] or 362436069
    stateC = seedArray[3] ~= 0 and seedArray[3] or 521288629
    stateD = seedArray[4] ~= 0 and seedArray[4] or 88675123
    
    isInitialized = true
end

--- 获取下一个随机数 (Xorshift128 算法)
--- @return number 32位无符号整数
local function NextRandom()
    if not isInitialized then
        error("BattleMath: not initialized, call Init() first")
    end
    
    local t = bit32.bxor(stateD, bit32.lshift(stateD, 11))
    stateD = stateC
    stateC = stateB
    stateB = stateA
    stateA = bit32.bxor(bit32.bxor(stateA, bit32.rshift(stateA, 19)), bit32.bxor(t, bit32.rshift(t, 8)))
    
    -- 确保返回正整数
    return stateA % 0x100000000
end

--- 生成指定范围内的随机整数 [min, max]
--- @param min number 最小值 (包含)
--- @param max number 最大值 (包含)
--- @return number 随机整数
function BattleMath.Random(min, max)
    if min > max then
        min, max = max, min
    end
    
    local range = max - min + 1
    local randomValue = NextRandom()
    
    return min + (randomValue % range)
end

--- 生成 0 到 1 之间的随机浮点数
--- @return number 0-1 之间的随机浮点数
function BattleMath.RandomProb()
    local randomValue = NextRandom()
    -- 将 32 位整数转换为 0-1 之间的浮点数
    return randomValue / 0xFFFFFFFF
end

--- 向下取整
--- @param x number 输入值
--- @return number 向下取整后的值
function BattleMath.Floor(x)
    return math.floor(x)
end

--- 向上取整
--- @param x number 输入值
--- @return number 向上取整后的值
function BattleMath.Ceil(x)
    return math.ceil(x)
end

--- 四舍五入到最近的整数
--- @param x number 输入值
--- @return number 四舍五入后的整数
function BattleMath.Round(x)
    return math.floor(x + 0.5)
end

--- 将值限制在指定范围内
--- @param x number 输入值
--- @param min number 最小值
--- @param max number 最大值
--- @return number 限制后的值
function BattleMath.Clamp(x, min, max)
    if x < min then
        return min
    elseif x > max then
        return max
    else
        return x
    end
end

--- 返回两个数中的较大值
--- @param a number 第一个数
--- @param b number 第二个数
--- @return number 较大值
function BattleMath.Max(a, b)
    return a > b and a or b
end

--- 返回两个数中的较小值
--- @param a number 第一个数
--- @param b number 第二个数
--- @return number 较小值
function BattleMath.Min(a, b)
    return a < b and a or b
end

--- 检查是否已初始化
--- @return boolean 是否已初始化
function BattleMath.IsInitialized()
    return isInitialized
end

--- 获取当前状态 (用于调试或保存状态)
--- @return table 包含当前4个状态值的表
function BattleMath.GetState()
    return { stateA, stateB, stateC, stateD }
end

return BattleMath
