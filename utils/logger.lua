local Logger = {}

local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
}

local LOG_LEVEL_NAMES = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
}

local ANSI_COLORS = {
    RESET = "\27[0m",
    RED = "\27[31m",
    YELLOW = "\27[33m",
    GREEN = "\27[32m",
    CYAN = "\27[36m",
}

local currentLogLevel = LOG_LEVELS.DEBUG
local logFile = nil

local function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function getColorForLevel(level)
    if level == LOG_LEVELS.DEBUG then
        return ANSI_COLORS.CYAN
    elseif level == LOG_LEVELS.INFO then
        return ANSI_COLORS.GREEN
    elseif level == LOG_LEVELS.WARN then
        return ANSI_COLORS.YELLOW
    elseif level == LOG_LEVELS.ERROR then
        return ANSI_COLORS.RED
    end
    return ANSI_COLORS.RESET
end

local function formatMessage(level, message)
    local timestamp = getTimestamp()
    local levelName = LOG_LEVEL_NAMES[level] or "UNKNOWN"
    return string.format("[%s] [%s] %s", timestamp, levelName, message)
end

local function formatColoredMessage(level, message)
    local timestamp = getTimestamp()
    local levelName = LOG_LEVEL_NAMES[level] or "UNKNOWN"
    local color = getColorForLevel(level)
    return string.format("%s[%s] [%s] %s%s", color, timestamp, levelName, message, ANSI_COLORS.RESET)
end

local function writeToFile(message)
    if logFile then
        local file, err = io.open(logFile, "a")
        if file then
            file:write(message .. "\n")
            file:close()
        end
    end
end

local function log(level, message)
    if level < currentLogLevel then
        return
    end

    local formattedMessage = formatMessage(level, message)
    local coloredMessage = formatColoredMessage(level, message)

    print(coloredMessage)
    writeToFile(formattedMessage)
end

function Logger.SetLogLevel(level)
    if type(level) == "number" and level >= 1 and level <= 4 then
        currentLogLevel = level
    elseif type(level) == "string" then
        local upperLevel = string.upper(level)
        if LOG_LEVELS[upperLevel] then
            currentLogLevel = LOG_LEVELS[upperLevel]
        end
    end
end

function Logger.SetLogFile(filename)
    logFile = filename
end

function Logger.Log(message)
    log(LOG_LEVELS.INFO, message)
end

function Logger.LogError(message)
    log(LOG_LEVELS.ERROR, message)
end

function Logger.LogWarning(message)
    log(LOG_LEVELS.WARN, message)
end

function Logger.Debug(message)
    log(LOG_LEVELS.DEBUG, message)
end

function Logger.Error(message)
    Logger.LogError(message)
end

function Logger.Warn(message)
    Logger.LogWarning(message)
end

function Logger.Info(message)
    Logger.Log(message)
end

Logger.LOG_LEVELS = LOG_LEVELS

return Logger
