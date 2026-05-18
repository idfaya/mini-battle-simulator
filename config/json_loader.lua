local JSON = require("utils.json")

local ConfigJsonLoader = {}

local DEFAULT_ROOTS = {
    "config",
    "../config",
}

local function joinPath(root, relativePath)
    if not root or root == "" then
        return relativePath
    end
    return root .. "/" .. relativePath
end

function ConfigJsonLoader.FindPath(relativePath, searchRoots)
    for _, root in ipairs(searchRoots or DEFAULT_ROOTS) do
        local path = joinPath(root, relativePath)
        local file = io.open(path, "r")
        if file then
            file:close()
            return path
        end
    end
    return nil
end

function ConfigJsonLoader.Read(relativePath, options)
    local opts = options or {}
    local path = ConfigJsonLoader.FindPath(relativePath, opts.searchRoots)
    if not path then
        return nil, string.format("cannot find config/%s", relativePath)
    end

    local file = io.open(path, "r")
    if not file then
        return nil, string.format("cannot open %s", path)
    end

    local content = file:read("*a")
    file:close()
    return content, path
end

function ConfigJsonLoader.Load(relativePath, options)
    local opts = options or {}
    local content, pathOrErr = ConfigJsonLoader.Read(relativePath, opts)
    if not content then
        return nil, pathOrErr
    end

    local success, data = pcall(JSON.JsonDecode, content)
    if not success then
        return nil, string.format("failed to decode config/%s: %s", relativePath, tostring(data))
    end

    if opts.expectedType and type(data) ~= opts.expectedType then
        return nil, string.format("config/%s must decode to a %s", relativePath, opts.expectedType)
    end

    return data, pathOrErr
end

return ConfigJsonLoader
