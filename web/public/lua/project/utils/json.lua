local json = {}

local function isArray(t)
    if type(t) ~= "table" then
        return false
    end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            return false
        end
    end
    return true
end

local function escapeString(s)
    s = tostring(s)
    local replacements = {
        ['\\'] = '\\\\',
        ['"'] = '\\"',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t'
    }
    return s:gsub('[\\"\b\f\n\r\t]', replacements)
end

local function encodeValue(value, indent, pretty, level, visited)
    visited = visited or {}
    level = level or 0
    
    local t = type(value)
    
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        if value ~= value then
            return "null"
        end
        if value == math.huge then
            return "null"
        end
        if value == -math.huge then
            return "null"
        end
        return tostring(value)
    elseif t == "string" then
        return '"' .. escapeString(value) .. '"'
    elseif t == "table" then
        if visited[value] then
            error("Circular reference detected")
        end
        visited[value] = true
        
        local result = {}
        local nextIndent = pretty and (indent .. "  ") or ""
        local newline = pretty and "\n" or ""
        local space = pretty and " " or ""
        
        if isArray(value) then
            for i, v in ipairs(value) do
                table.insert(result, encodeValue(v, nextIndent, pretty, level + 1, visited))
            end
            
            if #result == 0 then
                visited[value] = nil
                return "[]"
            end
            
            if pretty then
                visited[value] = nil
                return "[" .. newline .. nextIndent .. table.concat(result, "," .. newline .. nextIndent) .. newline .. indent .. "]"
            else
                visited[value] = nil
                return "[" .. table.concat(result, ",") .. "]"
            end
        else
            local keys = {}
            for k in pairs(value) do
                if type(k) ~= "string" and type(k) ~= "number" then
                    error("JSON object keys must be strings or numbers")
                end
                table.insert(keys, k)
            end
            
            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)
            
            for _, k in ipairs(keys) do
                local v = value[k]
                local keyStr = type(k) == "number" and tostring(k) or escapeString(k)
                table.insert(result, '"' .. keyStr .. '":' .. space .. encodeValue(v, nextIndent, pretty, level + 1, visited))
            end
            
            if #result == 0 then
                visited[value] = nil
                return "{}"
            end
            
            if pretty then
                visited[value] = nil
                return "{" .. newline .. nextIndent .. table.concat(result, "," .. newline .. nextIndent) .. newline .. indent .. "}"
            else
                visited[value] = nil
                return "{" .. table.concat(result, ",") .. "}"
            end
        end
    else
        error("Unsupported type: " .. t)
    end
end

function json.JsonEncode(value, pretty)
    pretty = pretty or false
    local indent = pretty and "" or ""
    return encodeValue(value, indent, pretty, 0, {})
end

local function skipWhitespace(str, pos)
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == " " or c == "\t" or c == "\n" or c == "\r" then
            pos = pos + 1
        else
            break
        end
    end
    return pos
end

local function parseValue(str, pos)
    pos = skipWhitespace(str, pos)
    
    if pos > #str then
        error("Unexpected end of input at position " .. pos)
    end
    
    local c = str:sub(pos, pos)
    
    if c == '"' then
        return parseString(str, pos)
    elseif c == '{' then
        return parseObject(str, pos)
    elseif c == '[' then
        return parseArray(str, pos)
    elseif c == 't' and str:sub(pos, pos + 3) == "true" then
        return true, pos + 4
    elseif c == 'f' and str:sub(pos, pos + 4) == "false" then
        return false, pos + 5
    elseif c == 'n' and str:sub(pos, pos + 3) == "null" then
        return nil, pos + 4
    elseif c == '-' or (c >= '0' and c <= '9') then
        return parseNumber(str, pos)
    else
        error("Unexpected character '" .. c .. "' at position " .. pos)
    end
end

function parseString(str, pos)
    pos = pos + 1
    local result = {}
    local startPos = pos
    
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == '"' then
            return table.concat(result), pos + 1
        elseif c == '\\' then
            if pos + 1 > #str then
                error("Unexpected end of input in string escape at position " .. pos)
            end
            local nextChar = str:sub(pos + 1, pos + 1)
            if nextChar == '"' then
                table.insert(result, '"')
            elseif nextChar == '\\' then
                table.insert(result, '\\')
            elseif nextChar == '/' then
                table.insert(result, '/')
            elseif nextChar == 'b' then
                table.insert(result, '\b')
            elseif nextChar == 'f' then
                table.insert(result, '\f')
            elseif nextChar == 'n' then
                table.insert(result, '\n')
            elseif nextChar == 'r' then
                table.insert(result, '\r')
            elseif nextChar == 't' then
                table.insert(result, '\t')
            elseif nextChar == 'u' then
                if pos + 5 > #str then
                    error("Invalid unicode escape at position " .. pos)
                end
                local hex = str:sub(pos + 2, pos + 5)
                local code = tonumber(hex, 16)
                if not code then
                    error("Invalid unicode escape sequence at position " .. pos)
                end
                table.insert(result, utf8.char(code))
                pos = pos + 4
            else
                error("Invalid escape sequence '\\" .. nextChar .. "' at position " .. pos)
            end
            pos = pos + 2
        elseif c:byte() < 32 then
            error("Unescaped control character at position " .. pos)
        else
            table.insert(result, c)
            pos = pos + 1
        end
    end
    
    error("Unterminated string at position " .. (pos - 1))
end

function parseNumber(str, pos)
    local startPos = pos
    local c = str:sub(pos, pos)
    
    if c == '-' then
        pos = pos + 1
    end
    
    if pos > #str then
        error("Invalid number at position " .. startPos)
    end
    
    c = str:sub(pos, pos)
    if c == '0' then
        pos = pos + 1
    elseif c >= '1' and c <= '9' then
        while pos <= #str do
            c = str:sub(pos, pos)
            if c >= '0' and c <= '9' then
                pos = pos + 1
            else
                break
            end
        end
    else
        error("Invalid number at position " .. startPos)
    end
    
    if pos <= #str and str:sub(pos, pos) == '.' then
        pos = pos + 1
        if pos > #str or str:sub(pos, pos) < '0' or str:sub(pos, pos) > '9' then
            error("Invalid number at position " .. startPos)
        end
        while pos <= #str do
            c = str:sub(pos, pos)
            if c >= '0' and c <= '9' then
                pos = pos + 1
            else
                break
            end
        end
    end
    
    if pos <= #str then
        c = str:sub(pos, pos)
        if c == 'e' or c == 'E' then
            pos = pos + 1
            if pos <= #str then
                c = str:sub(pos, pos)
                if c == '+' or c == '-' then
                    pos = pos + 1
                end
            end
            if pos > #str or str:sub(pos, pos) < '0' or str:sub(pos, pos) > '9' then
                error("Invalid number at position " .. startPos)
            end
            while pos <= #str do
                c = str:sub(pos, pos)
                if c >= '0' and c <= '9' then
                    pos = pos + 1
                else
                    break
                end
            end
        end
    end
    
    local numStr = str:sub(startPos, pos - 1)
    local num = tonumber(numStr)
    if not num then
        error("Invalid number '" .. numStr .. "' at position " .. startPos)
    end
    
    return num, pos
end

function parseArray(str, pos)
    pos = pos + 1
    local result = {}
    pos = skipWhitespace(str, pos)
    
    if pos <= #str and str:sub(pos, pos) == ']' then
        return result, pos + 1
    end
    
    while pos <= #str do
        local value
        value, pos = parseValue(str, pos)
        table.insert(result, value)
        
        pos = skipWhitespace(str, pos)
        
        if pos > #str then
            error("Unexpected end of input in array at position " .. pos)
        end
        
        local c = str:sub(pos, pos)
        if c == ']' then
            return result, pos + 1
        elseif c == ',' then
            pos = pos + 1
            pos = skipWhitespace(str, pos)
            if pos <= #str and str:sub(pos, pos) == ']' then
                error("Trailing comma in array at position " .. pos)
            end
        else
            error("Expected ',' or ']' in array at position " .. pos)
        end
    end
    
    error("Unterminated array at position " .. (pos - 1))
end

function parseObject(str, pos)
    pos = pos + 1
    local result = {}
    pos = skipWhitespace(str, pos)
    
    if pos <= #str and str:sub(pos, pos) == '}' then
        return result, pos + 1
    end
    
    while pos <= #str do
        pos = skipWhitespace(str, pos)
        
        if pos > #str or str:sub(pos, pos) ~= '"' then
            error("Expected string key in object at position " .. pos)
        end
        
        local key
        key, pos = parseString(str, pos)
        
        pos = skipWhitespace(str, pos)
        
        if pos > #str or str:sub(pos, pos) ~= ':' then
            error("Expected ':' after object key at position " .. pos)
        end
        pos = pos + 1
        
        local value
        value, pos = parseValue(str, pos)
        result[key] = value
        
        pos = skipWhitespace(str, pos)
        
        if pos > #str then
            error("Unexpected end of input in object at position " .. pos)
        end
        
        local c = str:sub(pos, pos)
        if c == '}' then
            return result, pos + 1
        elseif c == ',' then
            pos = pos + 1
            pos = skipWhitespace(str, pos)
            if pos <= #str and str:sub(pos, pos) == '}' then
                error("Trailing comma in object at position " .. pos)
            end
        else
            error("Expected ',' or '}' in object at position " .. pos)
        end
    end
    
    error("Unterminated object at position " .. (pos - 1))
end

function json.JsonDecode(jsonString)
    if type(jsonString) ~= "string" then
        error("JsonDecode expects a string argument")
    end
    
    local success, result, pos = pcall(function()
        local value, endPos = parseValue(jsonString, 1)
        endPos = skipWhitespace(jsonString, endPos)
        if endPos <= #jsonString then
            error("Unexpected trailing data at position " .. endPos)
        end
        return value, endPos
    end)
    
    if not success then
        error("JSON decode error: " .. tostring(result))
    end
    
    return result
end

return json
