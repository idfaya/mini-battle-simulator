---@class Rng
---@field nextInt fun(self: Rng, minValue: integer, maxValue: integer): integer
---@field pick fun(self: Rng, list: any[]): any|nil
---@field weightedPick fun(self: Rng, entries: any[], weightKey: string|nil): any|nil

---@class RngModule
---@field New fun(seed: integer|nil): Rng

local Rng = {}

---@param seed integer|nil
---@return Rng
function Rng.New(seed)
    local state = math.max(1, math.floor(tonumber(seed) or 1) % 2147483647)
    local self = {}

    function self:nextInt(minValue, maxValue)
        state = (state * 48271) % 2147483647
        local minV = math.floor(tonumber(minValue) or 0)
        local maxV = math.floor(tonumber(maxValue) or minV)
        if maxV < minV then
            minV, maxV = maxV, minV
        end
        local span = maxV - minV + 1
        if span <= 1 then
            return minV
        end
        return minV + (state % span)
    end

    function self:pick(list)
        if not list or #list <= 0 then
            return nil
        end
        return list[self:nextInt(1, #list)]
    end

    function self:weightedPick(entries, weightKey)
        local total = 0
        for _, entry in ipairs(entries or {}) do
            total = total + math.max(0, tonumber(entry[weightKey or "weight"]) or 0)
        end
        if total <= 0 then
            return entries and entries[1] or nil
        end
        local roll = self:nextInt(1, total)
        local running = 0
        for _, entry in ipairs(entries or {}) do
            running = running + math.max(0, tonumber(entry[weightKey or "weight"]) or 0)
            if roll <= running then
                return entry
            end
        end
        return entries and entries[#entries] or nil
    end

    return self
end

return Rng
