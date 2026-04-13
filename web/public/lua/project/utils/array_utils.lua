--[[
    数组工具函数模块
    提供常用的数组操作功能
--]]

local ArrayUtils = {}

--- 随机打乱数组（Fisher-Yates 洗牌算法）
---@param arr table 原始数组
---@return table 打乱后的新数组
function ArrayUtils.Shuffle(arr)
    if not arr or #arr == 0 then
        return {}
    end
    
    -- 复制数组
    local result = {}
    for i = 1, #arr do
        result[i] = arr[i]
    end
    
    -- Fisher-Yates 洗牌
    for i = #result, 2, -1 do
        local j = math.random(i)
        result[i], result[j] = result[j], result[i]
    end
    
    return result
end

--- 从数组中随机选择 N 个元素
---@param arr table 原始数组
---@param n number 选择数量
---@return table 选中的元素数组
function ArrayUtils.RandomSelect(arr, n)
    if not arr or #arr == 0 then
        return {}
    end
    
    n = math.min(n, #arr)
    
    if #arr <= n then
        -- 如果数组长度小于等于n，返回数组副本
        local result = {}
        for i = 1, #arr do
            result[i] = arr[i]
        end
        return result
    end
    
    -- 打乱后取前n个
    local shuffled = ArrayUtils.Shuffle(arr)
    local result = {}
    for i = 1, n do
        result[i] = shuffled[i]
    end
    
    return result
end

--- 数组是否包含指定元素
---@param arr table 数组
---@param element any 要查找的元素
---@return boolean 是否包含
function ArrayUtils.Contains(arr, element)
    if not arr then return false end
    for _, v in ipairs(arr) do
        if v == element then
            return true
        end
    end
    return false
end

--- 过滤数组
---@param arr table 原始数组
---@param predicate function 过滤函数 (element) -> boolean
---@return table 过滤后的数组
function ArrayUtils.Filter(arr, predicate)
    if not arr then return {} end
    local result = {}
    for _, v in ipairs(arr) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

--- 映射数组
---@param arr table 原始数组
---@param mapper function 映射函数 (element) -> newElement
---@return table 映射后的数组
function ArrayUtils.Map(arr, mapper)
    if not arr then return {} end
    local result = {}
    for _, v in ipairs(arr) do
        table.insert(result, mapper(v))
    end
    return result
end

return ArrayUtils
