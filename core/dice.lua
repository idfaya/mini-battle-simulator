---
--- Dice utilities (DND-style)
--- Supports expressions like:
--- - "2d6+4"
--- - "1d8-1"
--- - "2d6+4;1d6" (multi-part, separated by ';')
---

local Dice = {}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clampInt(v, minV, maxV)
    v = math.floor(tonumber(v) or 0)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function parsePart(part)
    part = trim(part)
    if part == "" then
        return nil, "empty dice part"
    end

    -- Accept:
    --  - "XdY+Z"
    --  - "XdY-Z"
    --  - "XdY"
    --  - "Z" (flat)
    --
    -- Lua patterns do not support "?" quantifier, so we match bonus in a second pass.
    local n, sides, bonus = part:match("^(%d+)[dD](%d+)%s*([%+%-]%s*%d+)$")
    if not n then
        n, sides = part:match("^(%d+)[dD](%d+)$")
    end
    if n and sides then
        n = clampInt(n, 0, 200)
        sides = clampInt(sides, 1, 1000)
        local b = 0
        if bonus and bonus ~= "" then
            b = tonumber((bonus:gsub("%s+", ""))) or 0
        end
        return { n = n, sides = sides, bonus = b }, nil
    end

    local flat = tonumber(part)
    if flat then
        return { n = 0, sides = 1, bonus = math.floor(flat) }, nil
    end

    return nil, "invalid dice part: " .. part
end

local function split(expr, sep)
    local result = {}
    expr = tostring(expr or "")
    sep = sep or ";"
    local pattern = string.format("([^%s]+)", sep)
    for token in expr:gmatch(pattern) do
        result[#result + 1] = trim(token)
    end
    return result
end

--- Roll a single dice part.
--- @param part table {n, sides, bonus}
--- @return number total
--- @return table detail { rolls = {..}, bonus = number }
function Dice.RollPart(part)
    if type(part) ~= "table" then
        return 0, { rolls = {}, bonus = 0 }
    end
    local n = clampInt(part.n or 0, 0, 200)
    local sides = clampInt(part.sides or 1, 1, 1000)
    local bonus = math.floor(tonumber(part.bonus) or 0)

    local rolls = {}
    local sum = 0
    for _ = 1, n do
        local r = math.random(1, sides)
        rolls[#rolls + 1] = r
        sum = sum + r
    end
    return sum + bonus, { rolls = rolls, bonus = bonus }
end

--- Roll an expression. Supports multi-part separated by ';'.
--- @param expr string
--- @param opts table|nil { crit = boolean } -- crit doubles dice count (n), not the bonus
--- @return number total
--- @return table detail { parts = { {total, rolls, bonus, n, sides}... }, expr = string }
function Dice.Roll(expr, opts)
    expr = trim(expr)
    opts = opts or {}

    local total = 0
    local detail = { expr = expr, parts = {} }

    for _, token in ipairs(split(expr, ";")) do
        if token ~= "" then
            local part, err = parsePart(token)
            if not part then
                -- Invalid part -> treat as 0 (safe) but keep error for debugging.
                detail.parts[#detail.parts + 1] = { total = 0, error = err, token = token }
            else
                local rollPart = {
                    n = part.n,
                    sides = part.sides,
                    bonus = part.bonus,
                }
                if opts.crit == true and rollPart.n > 0 then
                    rollPart.n = rollPart.n * 2
                end
                local partTotal, partDetail = Dice.RollPart(rollPart)
                total = total + partTotal
                detail.parts[#detail.parts + 1] = {
                    total = partTotal,
                    rolls = partDetail.rolls,
                    bonus = partDetail.bonus,
                    n = rollPart.n,
                    sides = rollPart.sides,
                }
            end
        end
    end

    return total, detail
end

--- Roll d20 with optional advantage/disadvantage.
--- @param mode string|nil "normal"|"adv"|"disadv"
--- @return number roll
--- @return table meta { nat20, nat1, raw = {..} }
function Dice.RollD20(mode)
    mode = mode or "normal"
    local r1 = math.random(1, 20)
    local r2 = math.random(1, 20)
    local chosen = r1
    local raw = { r1 }

    if mode == "adv" then
        raw = { r1, r2 }
        chosen = math.max(r1, r2)
    elseif mode == "disadv" then
        raw = { r1, r2 }
        chosen = math.min(r1, r2)
    end

    return chosen, {
        raw = raw,
        nat20 = (chosen == 20),
        nat1 = (chosen == 1),
    }
end

return Dice
