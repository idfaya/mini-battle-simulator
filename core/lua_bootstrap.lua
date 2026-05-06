local LuaBootstrap = {}

local DEFAULT_ROOT_DIRS = {
    "",
    "core",
    "modules",
    "config",
    "utils",
    "ui",
    "skills",
    "roguelike",
    "runtime",
}

local function normalizePath(path)
    return (tostring(path or ""):gsub("\\", "/"))
end

local function ensureTrailingSlash(path)
    local normalized = normalizePath(path)
    if normalized == "" or normalized:sub(-1) == "/" then
        return normalized
    end
    return normalized .. "/"
end

local function appendSearchPattern(pattern)
    if pattern ~= "" and not package.path:find(pattern, 1, true) then
        package.path = package.path .. ";" .. pattern
    end
end

local function appendRoot(root)
    local baseRoot = ensureTrailingSlash(root)
    for _, dir in ipairs(DEFAULT_ROOT_DIRS) do
        if dir == "" then
            appendSearchPattern(baseRoot .. "?.lua")
            appendSearchPattern(baseRoot .. "?/init.lua")
        else
            appendSearchPattern(baseRoot .. dir .. "/?.lua")
            appendSearchPattern(baseRoot .. dir .. "/?/init.lua")
        end
    end
end

local function getScriptDir(scriptSource)
    local source = tostring(scriptSource or "")
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end
    source = normalizePath(source)
    return source:match("(.+/)") or "./"
end

function LuaBootstrap.PreloadCore()
    require("core.battle_types")
    require("core.battle_enum")
    require("core.battle_default_types")
end

function LuaBootstrap.SetupFromSource(scriptSource, opts)
    opts = opts or {}
    local scriptDir = getScriptDir(scriptSource)

    appendRoot(scriptDir)
    if opts.includeParent then
        appendRoot(scriptDir .. "../")
    end

    for _, extraRoot in ipairs(opts.extraRoots or {}) do
        appendRoot(extraRoot)
    end

    for _, extraPattern in ipairs(opts.extraPatterns or {}) do
        appendSearchPattern(normalizePath(extraPattern))
    end

    if opts.includeLegacyAssets then
        appendSearchPattern(scriptDir .. "Assets/Lua/Modules/Battle/SkillNewLua/?.lua")
        appendSearchPattern(scriptDir .. "Assets/Lua/Modules/?.lua")
        appendSearchPattern(scriptDir .. "Assets/Lua/?.lua")
    end

    if opts.preload ~= false then
        LuaBootstrap.PreloadCore()
    end

    return scriptDir
end

return LuaBootstrap
