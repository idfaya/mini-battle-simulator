require("modules.BattleDefaultTypes")

local function ValueEquals(t1, t2)
    if t1 == t2 then return true end
    local o1Type = type(t1)
    local o2Type = type(t2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    for k, v in pairs(t1) do
        local v2 = t2[k]
        if not ValueEquals(v, v2) then return false end
    end

    return true
end

local function DelDefault(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return
    end

    for k, value in pairs(t1) do
        if ValueEquals(value, t2[k]) then
            t1[k] = nil
        end
    end

    for k, value in pairs(t1) do
        if type(value) == "table" then
            --value是数组部分

            if BattleCArrayName2Type[k] and #value > 0 then
                for _, arrayValue in ipairs(value) do
                    DelDefault(arrayValue, BattleCArrayName2Type[k])
                end
            else
                DelDefault(value, t2[k])
            end
        end
    end
end

local defaultMetaTables = {}
local function GetDefaultMetaTable(key, defaultTable)
    if defaultMetaTables[key] == nil then
        defaultMetaTables[key] = {__index = defaultTable}
    end
    return defaultMetaTables[key]
end



local function AddDefault(t1, t2, key)
    --if type(t1) ~= "table" or type(t2) ~= "table" then
    --    return
    --end

    setmetatable(t1, GetDefaultMetaTable(key, t2))

    for k, value in pairs(t1) do
        if type(value) == "table" then
            if BattleCArrayName2Type[k] and #value > 0 then
                for _, arrayValue in ipairs(value) do
                    AddDefault(arrayValue, BattleCArrayName2Type[k], k)
                end
            else
                --这里使用key连接k，避免同名变量造成的bug
                AddDefault(value, t2[k], key .. "_" .. k)
            end
        end
    end
end


local function Optimize(tbl, default)
    DelDefault(tbl, default)
end

local function SetDefault(tbl, default, defaultName)
    AddDefault(tbl, default, defaultName)
end


BattleDefaultTypesOpt = {}
BattleDefaultTypesOpt.Optimize = Optimize
BattleDefaultTypesOpt.SetDefault = SetDefault
