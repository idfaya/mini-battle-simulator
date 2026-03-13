local Inspect = {}

local DEFAULT_OPTIONS = {
    depth = 10,
    indent = "  ",
    showMetatable = false,
    showAddress = true,
    sortKeys = true,
    maxArrayElements = 100,
    maxStringLength = 1000,
}

local function isArray(t)
    if type(t) ~= "table" then
        return false
    end
    local count = 0
    for k, v in pairs(t) do
        if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
            return false
        end
        count = count + 1
    end
    return count == #t
end

local function formatString(s, maxLength)
    if #s > maxLength then
        s = s:sub(1, maxLength) .. "..."
    end
    return string.format("%q", s)
end

local function formatKey(k, visited, options, depth, indent)
    local keyType = type(k)
    if keyType == "string" then
        if k:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
            return k
        else
            return "[" .. formatString(k, options.maxStringLength) .. "]"
        end
    elseif keyType == "number" then
        return "[" .. tostring(k) .. "]"
    elseif keyType == "boolean" then
        return "[" .. tostring(k) .. "]"
    elseif keyType == "table" then
        return "[" .. Inspect.inspect(k, options, depth + 1, visited, indent) .. "]"
    else
        return "[" .. tostring(k) .. "]"
    end
end

local function sortKeys(a, b)
    local ta, tb = type(a), type(b)
    if ta == tb then
        if ta == "number" then
            return a < b
        elseif ta == "string" then
            return a < b
        else
            return tostring(a) < tostring(b)
        end
    end
    return ta < tb
end

function Inspect.inspect(value, options, depth, visited, currentIndent)
    options = options or DEFAULT_OPTIONS
    depth = depth or 0
    visited = visited or {}
    currentIndent = currentIndent or ""

    if depth > options.depth then
        return "... (depth limit reached)"
    end

    local valueType = type(value)

    if valueType == "nil" then
        return "nil"
    elseif valueType == "boolean" then
        return tostring(value)
    elseif valueType == "number" then
        if value ~= value then
            return "nan"
        elseif value == math.huge then
            return "inf"
        elseif value == -math.huge then
            return "-inf"
        else
            return tostring(value)
        end
    elseif valueType == "string" then
        return formatString(value, options.maxStringLength)
    elseif valueType == "function" then
        local info = debug.getinfo(value, "nS")
        local name = info.name or "?"
        local source = info.source or "?"
        local line = info.linedefined or 0
        return string.format("<function: %s (%s:%d)>", name, source, line)
    elseif valueType == "userdata" then
        return string.format("<userdata: %s>", tostring(value))
    elseif valueType == "thread" then
        return string.format("<thread: %s>", tostring(value))
    elseif valueType == "table" then
        if visited[value] then
            return string.format("<circular reference: %s>", tostring(value))
        end

        visited[value] = true

        local nextIndent = currentIndent .. options.indent
        local lines = {}
        local arrayLength = #value
        local isArr = isArray(value)

        if options.showAddress then
            table.insert(lines, string.format("<%s> {", tostring(value):gsub("table: ", "table ")))
        else
            table.insert(lines, "{")
        end

        local keys = {}
        for k, v in pairs(value) do
            table.insert(keys, k)
        end

        if options.sortKeys then
            table.sort(keys, sortKeys)
        end

        local count = 0
        for _, k in ipairs(keys) do
            local v = value[k]
            count = count + 1

            if isArr and type(k) == "number" and k <= options.maxArrayElements then
                local formattedValue = Inspect.inspect(v, options, depth + 1, visited, nextIndent)
                table.insert(lines, nextIndent .. formattedValue .. ",")
            else
                local formattedKey = formatKey(k, visited, options, depth + 1, nextIndent)
                local formattedValue = Inspect.inspect(v, options, depth + 1, visited, nextIndent)
                table.insert(lines, nextIndent .. formattedKey .. " = " .. formattedValue .. ",")
            end
        end

        if isArr and arrayLength > options.maxArrayElements then
            table.insert(lines, nextIndent .. string.format("... (%d more elements)", arrayLength - options.maxArrayElements))
        end

        if options.showMetatable then
            local mt = getmetatable(value)
            if mt then
                local formattedMt = Inspect.inspect(mt, options, depth + 1, visited, nextIndent)
                table.insert(lines, nextIndent .. "<metatable> = " .. formattedMt .. ",")
            end
        end

        table.insert(lines, currentIndent .. "}")

        visited[value] = nil

        return table.concat(lines, "\n")
    else
        return string.format("<unknown: %s>", tostring(value))
    end
end

function Inspect.Inspect(value, customOptions)
    local opts = {}
    for k, v in pairs(DEFAULT_OPTIONS) do
        opts[k] = v
    end
    if customOptions then
        for k, v in pairs(customOptions) do
            opts[k] = v
        end
    end
    return Inspect.inspect(value, opts, 0, {}, "")
end

function Inspect.print(value, customOptions)
    print(Inspect.Inspect(value, customOptions))
end

function Inspect.printf(fmt, ...)
    print(string.format(fmt, ...))
end

setmetatable(Inspect, {
    __call = function(_, value, customOptions)
        return Inspect.Inspect(value, customOptions)
    end
})

return Inspect
