local ConsoleRenderer = {}

-- 颜色代码定义 (ANSI)
ConsoleRenderer.Colors = {
    RESET = "\27[0m",
    BOLD = "\27[1m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
    MAGENTA = "\27[35m",
    CYAN = "\27[36m",
    WHITE = "\27[37m",
    BRIGHT_RED = "\27[91m",
    BRIGHT_GREEN = "\27[92m",
    BRIGHT_YELLOW = "\27[93m",
    BRIGHT_BLUE = "\27[94m",
    BRIGHT_MAGENTA = "\27[95m",
    BRIGHT_CYAN = "\27[96m",
    BRIGHT_WHITE = "\27[97m",
}

-- 检测操作系统
local isWindows = package.config:sub(1, 1) == "\\"

-- 内部缓冲区用于批量输出
local outputBuffer = {}
local useBuffer = false

-- 清屏
function ConsoleRenderer.Clear()
    if isWindows then
        os.execute("cls")
    else
        io.write("\27[2J\27[H")
    end
    ConsoleRenderer.Flush()
end

-- 设置光标位置 (1-based)
function ConsoleRenderer.SetCursorPosition(x, y)
    x = math.max(1, math.floor(x))
    y = math.max(1, math.floor(y))
    io.write(string.format("\27[%d;%dH", y, x))
    if not useBuffer then
        io.flush()
    end
end

-- 隐藏光标
function ConsoleRenderer.HideCursor()
    io.write("\27[?25l")
    if not useBuffer then
        io.flush()
    end
end

-- 显示光标
function ConsoleRenderer.ShowCursor()
    io.write("\27[?25h")
    if not useBuffer then
        io.flush()
    end
end

-- 设置文本颜色
function ConsoleRenderer.SetColor(colorCode)
    local color = ConsoleRenderer.Colors[colorCode]
    if color then
        io.write(color)
        if not useBuffer then
            io.flush()
        end
    end
end

-- 重置颜色
function ConsoleRenderer.ResetColor()
    io.write(ConsoleRenderer.Colors.RESET)
    if not useBuffer then
        io.flush()
    end
end

-- 绘制进度条
function ConsoleRenderer.DrawProgressBar(progress, width)
    width = width or 20
    progress = math.max(0, math.min(1, progress))
    local filled = math.floor(progress * width)
    local empty = width - filled
    local bar = string.rep("█", filled) .. string.rep("░", empty)
    io.write(bar)
    if not useBuffer then
        io.flush()
    end
end

-- 绘制边框
function ConsoleRenderer.DrawBox(x, y, width, height)
    if width < 2 or height < 2 then
        return
    end

    -- 左上角
    ConsoleRenderer.SetCursorPosition(x, y)
    io.write("┌")

    -- 上边
    ConsoleRenderer.DrawHorizontalLine(x + 1, y, width - 2, "─")

    -- 右上角
    ConsoleRenderer.SetCursorPosition(x + width - 1, y)
    io.write("┐")

    -- 左边和右边
    for i = 1, height - 2 do
        ConsoleRenderer.SetCursorPosition(x, y + i)
        io.write("│")
        ConsoleRenderer.SetCursorPosition(x + width - 1, y + i)
        io.write("│")
    end

    -- 左下角
    ConsoleRenderer.SetCursorPosition(x, y + height - 1)
    io.write("└")

    -- 下边
    ConsoleRenderer.DrawHorizontalLine(x + 1, y + height - 1, width - 2, "─")

    -- 右下角
    ConsoleRenderer.SetCursorPosition(x + width - 1, y + height - 1)
    io.write("┘")

    if not useBuffer then
        io.flush()
    end
end

-- 绘制水平线
function ConsoleRenderer.DrawHorizontalLine(x, y, width, char)
    char = char or "─"
    ConsoleRenderer.SetCursorPosition(x, y)
    io.write(string.rep(char, width))
    if not useBuffer then
        io.flush()
    end
end

-- 绘制垂直线
function ConsoleRenderer.DrawVerticalLine(x, y, height, char)
    char = char or "│"
    for i = 0, height - 1 do
        ConsoleRenderer.SetCursorPosition(x, y + i)
        io.write(char)
    end
    if not useBuffer then
        io.flush()
    end
end

-- 在指定位置打印文本
function ConsoleRenderer.PrintAt(x, y, text)
    ConsoleRenderer.SetCursorPosition(x, y)
    io.write(tostring(text))
    if not useBuffer then
        io.flush()
    end
end

-- 获取终端尺寸
function ConsoleRenderer.GetTerminalSize()
    local width, height = 80, 24

    if not isWindows then
        -- Unix-like 系统使用 stty
        local handle = io.popen("stty size 2>/dev/null")
        if handle then
            local result = handle:read("*a")
            handle:close()
            if result then
                local h, w = result:match("(%d+) (%d+)")
                if h and w then
                    height = tonumber(h)
                    width = tonumber(w)
                end
            end
        end
    else
        -- Windows 使用 mode 命令
        local handle = io.popen("mode con")
        if handle then
            local result = handle:read("*a")
            handle:close()
            if result then
                local w = result:match("Columns:%s*(%d+)")
                local h = result:match("Lines:%s*(%d+)")
                if w then
                    width = tonumber(w)
                end
                if h then
                    height = tonumber(h)
                end
            end
        end
    end

    return width, height
end

-- 刷新输出
function ConsoleRenderer.Flush()
    io.flush()
end

-- 启用/禁用缓冲模式
function ConsoleRenderer.SetBufferMode(enabled)
    useBuffer = enabled
end

-- 保存光标位置
function ConsoleRenderer.SaveCursor()
    io.write("\27[s")
    if not useBuffer then
        io.flush()
    end
end

-- 恢复光标位置
function ConsoleRenderer.RestoreCursor()
    io.write("\27[u")
    if not useBuffer then
        io.flush()
    end
end

-- 清除从光标到行尾
function ConsoleRenderer.ClearLineEnd()
    io.write("\27[K")
    if not useBuffer then
        io.flush()
    end
end

-- 清除整行
function ConsoleRenderer.ClearLine()
    io.write("\27[2K")
    if not useBuffer then
        io.flush()
    end
end

-- 移动光标到指定行
function ConsoleRenderer.MoveToLine(line)
    io.write(string.format("\27[%dH", line))
    if not useBuffer then
        io.flush()
    end
end

return ConsoleRenderer
