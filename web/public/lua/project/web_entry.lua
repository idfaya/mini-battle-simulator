package.path = package.path
    .. ";?.lua"
    .. ";core/?.lua"
    .. ";modules/?.lua"
    .. ";config/?.lua"
    .. ";utils/?.lua"
    .. ";ui/?.lua"

io = io or {}
os = os or {}

io.read = io.read or function()
    return nil
end

io.open = io.open or function()
    return nil, "browser io.open is not ready"
end

os.execute = os.execute or function()
    return nil
end

print = function(...)
    return nil
end

require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")
require("modules.BattleDefaultTypesOpt")

local JSON = require("utils.json")
local Logger = require("utils.logger")
local WebFiles = require("web_generated_files")

Logger.SetLogLevel(Logger.LOG_LEVELS.ERROR)

local function createVirtualFile(path)
    local content = WebFiles[path]
        or WebFiles[path:gsub("\\", "/")]
        or WebFiles[path:gsub("^%./", "")]
        or WebFiles[path:gsub("^%.%./", "")]

    if not content then
        return nil
    end

    local cursor = 1
    return {
        read = function(_, mode)
            local effectiveMode = mode or "*l"
            if effectiveMode == "*a" or effectiveMode == "*all" then
                if cursor > #content then
                    return ""
                end
                local chunk = content:sub(cursor)
                cursor = #content + 1
                return chunk
            end

            if effectiveMode == "*l" then
                if cursor > #content then
                    return nil
                end
                local newline = content:find("\n", cursor, true)
                if not newline then
                    local chunk = content:sub(cursor)
                    cursor = #content + 1
                    return chunk
                end
                local chunk = content:sub(cursor, newline - 1)
                cursor = newline + 1
                return chunk
            end

            return nil
        end,
        close = function()
            return true
        end
    }
end

do
    local originalIoOpen = io.open
    io.open = function(path, mode)
        local normalized = tostring(path or ""):gsub("\\", "/")
        local openMode = mode or "r"
        if openMode ~= "r" and openMode ~= "rb" then
            return nil, "browser io.open is read-only"
        end

        local virtualFile = createVirtualFile(normalized)
        if virtualFile then
            return virtualFile
        end

        if originalIoOpen then
            return originalIoOpen(path, mode)
        end

        return nil, "file not found"
    end
end

local Runtime = require("modules.browser_battle_runtime")

MiniBattleWebApi = {}

local function safeCall(fn)
    local ok, result = xpcall(fn, function(err)
        local trace = ""
        if debug and debug.traceback then
            trace = debug.traceback("", 2)
        end

        return {
            message = tostring(err),
            errType = type(err),
            trace = trace,
        }
    end)
    if not ok then
        if type(result) == "table" then
            local message = (result.message or "unknown error")
                .. " [type=" .. tostring(result.errType) .. "]"
            if result.trace and result.trace ~= "" then
                message = message .. "\n" .. tostring(result.trace)
            end
            error(message)
        end
        error(tostring(result))
    end
    return result
end

function MiniBattleWebApi.init_battle(configJson)
    return safeCall(function()
        local config = nil
        if configJson and configJson ~= "" then
            config = JSON.JsonDecode(configJson)
        end
        local ok, result = pcall(Runtime.init, config)
        if not ok then
            error("Runtime.init failed [type=" .. type(result) .. "] " .. tostring(result))
        end
        return JSON.JsonEncode(result)
    end)
end

function MiniBattleWebApi.tick(deltaJson)
    return safeCall(function()
        local payload = nil
        if deltaJson and deltaJson ~= "" then
            payload = JSON.JsonDecode(deltaJson)
        end
        local deltaMs = payload and payload.deltaMs or 16
        return JSON.JsonEncode(Runtime.tick(deltaMs))
    end)
end

function MiniBattleWebApi.get_snapshot()
    return safeCall(function()
        return JSON.JsonEncode(Runtime.getSnapshot())
    end)
end

function MiniBattleWebApi.queue_command(commandJson)
    return safeCall(function()
        local command = JSON.JsonDecode(commandJson)
        return JSON.JsonEncode({
            accepted = Runtime.queueCommand(command),
        })
    end)
end

function MiniBattleWebApi.restart_battle(configJson)
    return safeCall(function()
        local config = nil
        if configJson and configJson ~= "" then
            config = JSON.JsonDecode(configJson)
        end
        return JSON.JsonEncode(Runtime.restart(config))
    end)
end
