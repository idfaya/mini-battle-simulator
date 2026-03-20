---
--- Battle Display Module
--- 战斗显示模块 - 在控制台显示战斗状态
--- 提供美观的ASCII图形界面展示战斗信息
---

local Logger = require("utils.logger")
local BattleFormation = require("modules.battle_formation")
local BattleBuff = require("modules.battle_buff")
local BattleSkill = require("modules.battle_skill")
local BattleMain = require("modules.battle_main")

---@class BattleDisplay
local BattleDisplay = {}

-- ==================== 配置常量 ====================

-- 颜色代码 (ANSI转义序列)
local COLORS = {
    RESET = "\27[0m",
    BLACK = "\27[30m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
    MAGENTA = "\27[35m",
    CYAN = "\27[36m",
    WHITE = "\27[37m",
    BRIGHT_BLACK = "\27[90m",
    BRIGHT_RED = "\27[91m",
    BRIGHT_GREEN = "\27[92m",
    BRIGHT_YELLOW = "\27[93m",
    BRIGHT_BLUE = "\27[94m",
    BRIGHT_MAGENTA = "\27[95m",
    BRIGHT_CYAN = "\27[96m",
    BRIGHT_WHITE = "\27[97m",
    BG_RED = "\27[41m",
    BG_GREEN = "\27[42m",
    BG_YELLOW = "\27[43m",
    BG_BLUE = "\27[44m",
    BG_MAGENTA = "\27[45m",
    BG_CYAN = "\27[46m",
    BG_WHITE = "\27[47m",
}

-- 边框字符
local BORDERS = {
    TOP_LEFT = "╔",
    TOP_RIGHT = "╗",
    BOTTOM_LEFT = "╚",
    BOTTOM_RIGHT = "╝",
    HORIZONTAL = "═",
    VERTICAL = "║",
    T_LEFT = "╠",
    T_RIGHT = "╣",
    T_TOP = "╦",
    T_BOTTOM = "╩",
    CROSS = "╬",
}

-- 显示配置
local DISPLAY_CONFIG = {
    CARD_WIDTH = 25,  -- 从28减小到25，适应3个卡片一行（25*3+4=79<80）
    CARD_HEIGHT = 12,
    HP_BAR_WIDTH = 18,  -- 从20减小到18
    ENERGY_BAR_WIDTH = 18,  -- 从20减小到18
    MAX_LOG_LINES = 8,
    TEAM_GAP = 2,  -- 从4减小到2
}

-- 战斗日志缓存
local battleLogCache = {}
local maxLogCacheSize = 50

-- ==================== 颜色工具函数 ====================

--- 给文本添加颜色
---@param text string 原始文本
---@param color string 颜色代码
---@return string 带颜色的文本
local function ColorText(text, color)
    return color .. text .. COLORS.RESET
end

--- 根据HP百分比获取颜色
---@param hpPercent number HP百分比 (0-1)
---@return string 颜色代码
local function GetHpColor(hpPercent)
    if hpPercent > 0.6 then
        return COLORS.BRIGHT_GREEN
    elseif hpPercent > 0.3 then
        return COLORS.BRIGHT_YELLOW
    else
        return COLORS.BRIGHT_RED
    end
end

--- 根据阵营获取颜色
---@param isLeft boolean 是否为左侧队伍
---@return string 颜色代码
local function GetTeamColor(isLeft)
    return isLeft and COLORS.BRIGHT_CYAN or COLORS.BRIGHT_MAGENTA
end

-- ==================== 基础绘制函数 ====================

--- 清屏
function BattleDisplay.ClearScreen()
    -- 使用ANSI转义码清屏，比调用系统命令更可靠
    io.write("\27[2J\27[H")
    io.flush()
end

--- 绘制水平线
---@param width number 线宽
---@param char string 使用的字符 (可选)
---@param color string 颜色 (可选)
---@return string 水平线字符串
function BattleDisplay.DrawHorizontalLine(width, char, color)
    char = char or BORDERS.HORIZONTAL
    local line = string.rep(char, width)
    if color then
        line = ColorText(line, color)
    end
    return line
end

--- 绘制边框行
---@param width number 宽度
---@param leftChar string 左边字符
---@param rightChar string 右边字符
---@param fillChar string 填充字符
---@param color string 颜色 (可选)
---@return string 边框行字符串
local function DrawBorderRow(width, leftChar, rightChar, fillChar, color)
    fillChar = fillChar or " "
    local line = leftChar .. string.rep(fillChar, width - 2) .. rightChar
    if color then
        line = ColorText(line, color)
    end
    return line
end

-- ==================== HP/能量条绘制 ====================

--- 绘制HP条
---@param current number 当前HP
---@param max number 最大HP
---@param width number 条宽度 (可选，默认20)
---@return string HP条字符串
function BattleDisplay.ShowHpBar(current, max, width)
    width = width or DISPLAY_CONFIG.HP_BAR_WIDTH
    current = math.max(0, math.min(current, max))
    local percent = current / max
    local filled = math.floor(width * percent)
    local empty = width - filled
    
    local filledChar = "█"
    local emptyChar = "░"
    
    local hpColor = GetHpColor(percent)
    local bar = string.rep(filledChar, filled) .. string.rep(emptyChar, empty)
    
    -- 只返回HP条，不嵌入数字，避免长度不固定导致错位
    return ColorText("[" .. bar .. "]", hpColor)
end

--- 获取HP数值文本（单独显示在HP条下方）
---@param current number 当前HP
---@param max number 最大HP
---@return string HP数值字符串
function BattleDisplay.ShowHpText(current, max)
    current = math.max(0, math.min(current, max))
    local percent = current / max
    local hpColor = GetHpColor(percent)
    return ColorText(string.format("%d/%d", current, max), hpColor)
end

--- 绘制能量条（只返回条，不返回数值）
---@param points number 当前能量点数
---@param maxPoints number 最大能量点数
---@param width number 条宽度 (可选，默认20)
---@return string 能量条字符串
function BattleDisplay.ShowEnergyBar(points, maxPoints, width)
    width = width or DISPLAY_CONFIG.ENERGY_BAR_WIDTH
    points = math.max(0, math.min(points, maxPoints))
    
    local bar = ""
    local energyColor = COLORS.BRIGHT_YELLOW
    
    -- 使用方块表示能量点
    for i = 1, maxPoints do
        if i <= points then
            bar = bar .. ColorText("◆", energyColor)
        else
            bar = bar .. ColorText("◇", COLORS.BRIGHT_BLACK)
        end
    end
    
    return "[" .. bar .. "]"
end

--- 获取能量数值文本
---@param points number 当前能量点数
---@param maxPoints number 最大能量点数
---@return string 能量数值字符串
function BattleDisplay.ShowEnergyText(points, maxPoints)
    points = math.max(0, math.min(points, maxPoints))
    local energyColor = COLORS.BRIGHT_YELLOW
    return ColorText(tostring(points) .. "/" .. maxPoints, energyColor)
end

--- 绘制能量条(Bar类型)（只返回条，不返回百分比）
---@param current number 当前能量
---@param max number 最大能量
---@param width number 条宽度
---@return string 能量条字符串
function BattleDisplay.ShowEnergyBarType(current, max, width)
    width = width or DISPLAY_CONFIG.ENERGY_BAR_WIDTH
    current = math.max(0, math.min(current, max))
    local percent = current / max
    local filled = math.floor(width * percent)
    local empty = width - filled
    
    local filledChar = "="
    local emptyChar = "-"
    
    local bar = string.rep(filledChar, filled) .. string.rep(emptyChar, empty)
    
    return ColorText("[" .. bar .. "]", COLORS.BRIGHT_YELLOW)
end

--- 获取能量百分比文本
---@param current number 当前能量
---@param max number 最大能量
---@return string 能量百分比字符串
function BattleDisplay.ShowEnergyPercent(current, max)
    current = math.max(0, math.min(current, max))
    local percent = current / max
    local energyText = string.format("%d%%", math.floor(percent * 100))
    return ColorText(energyText, COLORS.BRIGHT_YELLOW)
end

-- ==================== Buff列表绘制 ====================

--- 获取Buff类型颜色
---@param mainType number Buff主类型
---@return string 颜色代码
local function GetBuffTypeColor(mainType)
    if mainType == E_BUFF_MAIN_TYPE.GOOD then
        return COLORS.BRIGHT_GREEN
    elseif mainType == E_BUFF_MAIN_TYPE.BAD then
        return COLORS.BRIGHT_RED
    elseif mainType == E_BUFF_MAIN_TYPE.CONTROL then
        return COLORS.BRIGHT_MAGENTA
    else
        return COLORS.BRIGHT_WHITE
    end
end

--- 显示Buff列表
---@param buffList table Buff列表
---@param x number 显示位置X (控制台列)
---@param y number 显示位置Y (控制台行)
---@return table { plain = 纯文本, colored = 带颜色文本 }
function BattleDisplay.ShowBuffList(buffList, x, y)
    if not buffList or #buffList == 0 then
        return { plain = "", colored = "" }
    end
    
    -- 限制显示的buff数量
    local maxDisplay = 4
    local displayCount = math.min(#buffList, maxDisplay)
    
    local buffIconsPlain = ""
    local buffIconsColored = ""
    for i = 1, displayCount do
        local buff = buffList[i]
        local icon = buff.icon or "*"
        local color = GetBuffTypeColor(buff.mainType)
        
        -- 显示层数
        local stackText = ""
        if buff.stackCount and buff.stackCount > 1 then
            stackText = tostring(buff.stackCount)
        end
        
        buffIconsPlain = buffIconsPlain .. icon .. stackText .. " "
        buffIconsColored = buffIconsColored .. ColorText(icon .. stackText, color) .. " "
    end
    
    -- 如果还有更多buff，显示省略号
    if #buffList > maxDisplay then
        buffIconsPlain = buffIconsPlain .. "..."
        buffIconsColored = buffIconsColored .. ColorText("...", COLORS.BRIGHT_BLACK)
    end
    
    return { plain = buffIconsPlain, colored = buffIconsColored }
end

--- 获取Buff详细描述
---@param buffList table Buff列表
---@return table Buff描述字符串数组
local function GetBuffDescriptions(buffList)
    local descriptions = {}
    if not buffList or #buffList == 0 then
        return descriptions
    end
    
    for _, buff in ipairs(buffList) do
        local color = GetBuffTypeColor(buff.mainType)
        local stackText = ""
        if buff.stackCount and buff.stackCount > 1 then
            stackText = "x" .. buff.stackCount
        end
        local desc = ColorText(buff.name .. stackText, color)
        table.insert(descriptions, desc)
    end
    
    return descriptions
end

-- ==================== 技能冷却显示 ====================

--- 计算字符串的显示宽度（中文字符算2个宽度）
---@param str string 字符串
---@return number 显示宽度
local function GetDisplayWidth(str)
    local width = 0
    for i = 1, #str do
        local byte = str:byte(i)
        -- UTF-8中文字符：第一个字节 >= 0xE0 (224)
        if byte >= 224 then
            width = width + 2
        elseif byte < 128 then
            -- ASCII字符
            width = width + 1
        end
        -- 忽略UTF-8后续字节 (128-191)
    end
    return width
end

--- 截断字符串到指定显示宽度（中文字符算2个宽度）
---@param str string 原始字符串
---@param maxWidth number 最大显示宽度
---@return string 截断后的字符串
local function TruncateToWidth(str, maxWidth)
    local result = ""
    local width = 0
    local i = 1
    while i <= #str do
        local byte = str:byte(i)
        if byte >= 224 then
            -- UTF-8中文字符（3字节）
            if width + 2 > maxWidth then break end
            result = result .. str:sub(i, i + 2)
            width = width + 2
            i = i + 3
        elseif byte >= 192 then
            -- UTF-8双字节字符
            if width + 2 > maxWidth then break end
            result = result .. str:sub(i, i + 1)
            width = width + 2
            i = i + 2
        elseif byte < 128 then
            -- ASCII字符
            if width + 1 > maxWidth then break end
            result = result .. str:sub(i, i)
            width = width + 1
            i = i + 1
        else
            -- UTF-8后续字节，跳过
            i = i + 1
        end
    end
    return result
end

--- 显示技能冷却状态
---@param hero table 英雄对象
---@return table 技能冷却字符串 { plain = 纯文本, colored = 带颜色文本, displayWidth = 显示宽度 }
local function ShowSkillCooldowns(hero)
    if not hero or not hero.skills then
        return { plain = "", colored = "", displayWidth = 0 }
    end
    
    local cooldownTextPlain = ""
    local cooldownTextColored = ""
    local displayWidth = 0
    local skillCount = 0
    
    for _, skill in ipairs(hero.skills) do
        if skillCount >= 3 then break end -- 最多显示3个技能
        
        local skillName = skill.name or "Skill"
        -- 缩短技能名到4个显示宽度（中文字符算2个宽度）
        if GetDisplayWidth(skillName) > 4 then
            skillName = TruncateToWidth(skillName, 4)
        end
        
        local cd = skill.coolDown or 0
        local maxCd = skill.maxCoolDown or 0
        local skillNameWidth = GetDisplayWidth(skillName)
        
        if cd > 0 then
            local text = skillName .. "(" .. cd .. ")"
            cooldownTextPlain = cooldownTextPlain .. text
            cooldownTextColored = cooldownTextColored .. ColorText(skillName .. "(" .. cd .. ")", COLORS.BRIGHT_RED)
            -- 数字和括号都是单字节
            displayWidth = displayWidth + skillNameWidth + 1 + #tostring(cd) + 1
        else
            local text = skillName .. "(✓)"
            cooldownTextPlain = cooldownTextPlain .. text
            cooldownTextColored = cooldownTextColored .. ColorText(skillName .. "(✓)", COLORS.BRIGHT_GREEN)
            -- ✓ 占用1个字符宽度
            displayWidth = displayWidth + skillNameWidth + 1 + 1 + 1
        end
        
        -- 不是最后一个技能才加空格
        if skillCount < 2 then
            cooldownTextPlain = cooldownTextPlain .. " "
            cooldownTextColored = cooldownTextColored .. " "
            displayWidth = displayWidth + 1
        end
        
        skillCount = skillCount + 1
    end
    
    return { plain = cooldownTextPlain, colored = cooldownTextColored, displayWidth = displayWidth }
end

-- ==================== 英雄卡片绘制 ====================

--- 显示英雄卡片
---@param hero table 英雄对象
---@param x number 显示位置X (控制台列，可选)
---@param y number 显示位置Y (控制台行，可选)
---@return table 卡片行数组
function BattleDisplay.ShowHeroCard(hero, x, y)
    if not hero then
        return {}
    end
    
    local width = DISPLAY_CONFIG.CARD_WIDTH
    local lines = {}
    local teamColor = GetTeamColor(hero.isLeft)
    local isDead = not hero.isAlive or hero.isDead
    
    -- 卡片顶部边框
    table.insert(lines, teamColor .. BORDERS.TOP_LEFT .. string.rep(BORDERS.HORIZONTAL, width - 2) .. BORDERS.TOP_RIGHT .. COLORS.RESET)
    
    -- 英雄名称行
    local name = hero.name or "Unknown"
    -- 内容区域宽度 = 总宽度 - 2(左右边框)
    local contentWidth = width - 2
    if #name > contentWidth - 2 then
        name = name:sub(1, contentWidth - 2)
    end
    -- 左右各一个空格，所以padding = contentWidth - 2(空格) - #name
    local namePadding = contentWidth - 2 - #name
    local nameLineContent = " " .. name .. string.rep(" ", namePadding) .. " "
    -- 始终显示边框，死亡时只改变文字颜色
    if isDead then
        nameLineContent = ColorText(nameLineContent, COLORS.BRIGHT_BLACK)
    else
        nameLineContent = ColorText(nameLineContent, teamColor)
    end
    local nameLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. nameLineContent .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, nameLine)
    
    -- 分隔线
    table.insert(lines, teamColor .. BORDERS.T_LEFT .. string.rep(BORDERS.HORIZONTAL, width - 2) .. BORDERS.T_RIGHT .. COLORS.RESET)
    
    -- HP条
    -- ShowHpBar 返回的格式是 [████░░░░░░]，包含 [] 共2个字符
    -- 所以传入的宽度应该是 contentWidth - 2，这样返回的总长度 = contentWidth
    local hpBar = BattleDisplay.ShowHpBar(hero.hp or 0, hero.maxHp or 100, contentWidth - 2)
    local hpLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. hpBar .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, hpLine)
    
    -- HP数值（单独一行，右对齐）
    local hpTextPlain = string.format("%d/%d", hero.hp or 0, hero.maxHp or 100)
    local hpTextColored = BattleDisplay.ShowHpText(hero.hp or 0, hero.maxHp or 100)
    -- 内容区域宽度 = 总宽度 - 2(左右边框)，右侧一个空格
    local hpTextPadding = contentWidth - 1 - #hpTextPlain
    if hpTextPadding < 0 then hpTextPadding = 0 end
    local hpTextLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. string.rep(" ", hpTextPadding) .. hpTextColored .. " " .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, hpTextLine)
    
    -- 能量条
    -- 注意：能量系统使用 hero.curEnergy 而不是 hero.energy
    local curEnergy = hero.curEnergy or hero.energy or 0
    local maxEnergy = hero.maxEnergy or 100
    
    -- ShowEnergyBar 返回 [◆◆◇◇◇]，长度 = maxPoints + 2
    -- 传入 maxPoints，返回长度 = maxPoints + 2，需要 contentWidth - 2
    local energyLine = ""
    local energyTextPlain = ""
    local energyTextColored = ""
    if hero.energyType == E_ENERGY_TYPE.Point then
        local maxPoints = maxEnergy
        local energyBar = BattleDisplay.ShowEnergyBar(curEnergy, maxPoints, maxPoints)
        energyLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. energyBar .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
        energyTextPlain = tostring(curEnergy) .. "/" .. maxPoints
        energyTextColored = BattleDisplay.ShowEnergyText(curEnergy, maxPoints)
    else
        -- ShowEnergyBarType 返回 [====----]，长度 = width + 2
        local barWidth = contentWidth - 2
        local energyBar = BattleDisplay.ShowEnergyBarType(curEnergy, maxEnergy, barWidth)
        energyLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. energyBar .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
        local percent = math.floor((curEnergy / maxEnergy) * 100)
        energyTextPlain = percent .. "%"
        energyTextColored = BattleDisplay.ShowEnergyPercent(curEnergy, maxEnergy)
    end
    table.insert(lines, energyLine)
    
    -- 能量数值（单独一行，右对齐）
    local energyTextPadding = contentWidth - 1 - #energyTextPlain
    if energyTextPadding < 0 then energyTextPadding = 0 end
    local energyTextLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. string.rep(" ", energyTextPadding) .. energyTextColored .. " " .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, energyTextLine)
    
    -- Buff列表
    local buffList = BattleBuff.GetAllBuffs(hero)
    local buffResult = BattleDisplay.ShowBuffList(buffList, 0, 0) or { plain = "", colored = "" }
    -- Buff列表
    -- "Buff:" 前缀占 5 个字符
    local buffPadding = contentWidth - 5 - #buffResult.plain
    if buffPadding < 0 then buffPadding = 0 end
    local buffLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. "Buff:" .. buffResult.colored .. string.rep(" ", buffPadding) .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, buffLine)
    
    -- 技能冷却
    local cooldownResult = ShowSkillCooldowns(hero)
    -- 使用 displayWidth 计算 padding，因为 ✓ 可能占用2个字符宽度
    local cdPadding = contentWidth - cooldownResult.displayWidth
    if cdPadding < 0 then cdPadding = 0 end
    local cdLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. cooldownResult.colored .. string.rep(" ", cdPadding) .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, cdLine)
    
    -- 状态信息
    -- 注意：中文字符在终端中占用2个字符宽度
    local statusTextPlain = ""
    local statusTextColored = ""
    local statusDisplayWidth = 0
    if isDead then
        statusTextPlain = "☠ 已阵亡"
        statusTextColored = ColorText(statusTextPlain, COLORS.BRIGHT_RED)
        -- ☠(1) + 空格(1) + 已(2) + 阵(2) + 亡(2) = 8
        statusDisplayWidth = 1 + 1 + 2 + 2 + 2
    elseif BattleBuff.IsHeroUnderControl(hero) then
        statusTextPlain = "⚠ 被控制"
        statusTextColored = ColorText(statusTextPlain, COLORS.BRIGHT_YELLOW)
        -- ⚠(1) + 空格(1) + 被(2) + 控(2) + 制(2) = 8
        statusDisplayWidth = 1 + 1 + 2 + 2 + 2
    else
        statusTextPlain = "♥ 存活"
        statusTextColored = ColorText(statusTextPlain, COLORS.BRIGHT_GREEN)
        -- ♥(1) + 空格(1) + 存(2) + 活(2) = 6
        statusDisplayWidth = 1 + 1 + 2 + 2
    end
    -- 计算padding使总长度 = contentWidth
    local statusPadding = contentWidth - statusDisplayWidth
    if statusPadding < 0 then statusPadding = 0 end
    local statusLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. statusTextColored .. string.rep(" ", statusPadding) .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, statusLine)
    
    -- 卡片底部边框
    table.insert(lines, teamColor .. BORDERS.BOTTOM_LEFT .. string.rep(BORDERS.HORIZONTAL, width - 2) .. BORDERS.BOTTOM_RIGHT .. COLORS.RESET)
    
    return lines
end

-- ==================== 战场显示 ====================

--- 显示战场 (双方队伍，上下排列)
---@param teamLeft table 左侧队伍
---@param teamRight table 右侧队伍
function BattleDisplay.ShowBattleField(teamLeft, teamRight)
    teamLeft = teamLeft or BattleFormation.teamLeft
    teamRight = teamRight or BattleFormation.teamRight
    
    print("")
    print(ColorText("                    [ BATTLE FIELD ]", COLORS.BRIGHT_WHITE))
    print("")
    
    -- 显示上方队伍（左侧队伍）
    local leftTitle = ColorText("【上方队伍 - 左侧】", COLORS.BRIGHT_CYAN)
    print(leftTitle)
    print("")
    
    -- 准备左侧队伍卡片
    local leftCards = {}
    for _, hero in ipairs(teamLeft) do
        table.insert(leftCards, BattleDisplay.ShowHeroCard(hero))
    end
    
    -- 显示左侧队伍卡片（每行3个）
    local cardsPerRow = 3
    for row = 1, math.ceil(#leftCards / cardsPerRow) do
        local heroes = {}
        for i = 1, cardsPerRow do
            local idx = (row - 1) * cardsPerRow + i
            if idx <= #teamLeft then
                table.insert(heroes, teamLeft[idx])
            end
        end
        
        -- 生成卡片行
        local cardLines = {}
        for _, hero in ipairs(heroes) do
            table.insert(cardLines, BattleDisplay.ShowHeroCard(hero))
        end
        
        -- 打印卡片行
        local maxCardHeight = DISPLAY_CONFIG.CARD_HEIGHT
        for lineIdx = 1, maxCardHeight do
            local line = ""
            for _, card in ipairs(cardLines) do
                if card[lineIdx] then
                    line = line .. card[lineIdx] .. "  "
                else
                    line = line .. string.rep(" ", DISPLAY_CONFIG.CARD_WIDTH + 2)
                end
            end
            print(line)
        end
        print("")
    end
    
    -- 显示队伍分隔
    print(ColorText(string.rep("─", 70), COLORS.BRIGHT_BLACK))
    print("")
    
    -- 显示下方队伍（右侧队伍）
    local rightTitle = ColorText("【下方队伍 - 右侧】", COLORS.BRIGHT_MAGENTA)
    print(rightTitle)
    print("")
    
    -- 准备右侧队伍卡片
    local rightCards = {}
    for _, hero in ipairs(teamRight) do
        table.insert(rightCards, BattleDisplay.ShowHeroCard(hero))
    end
    
    -- 显示右侧队伍卡片（每行3个）
    for row = 1, math.ceil(#rightCards / cardsPerRow) do
        local heroes = {}
        for i = 1, cardsPerRow do
            local idx = (row - 1) * cardsPerRow + i
            if idx <= #teamRight then
                table.insert(heroes, teamRight[idx])
            end
        end
        
        -- 生成卡片行
        local cardLines = {}
        for _, hero in ipairs(heroes) do
            table.insert(cardLines, BattleDisplay.ShowHeroCard(hero))
        end
        
        -- 打印卡片行
        local maxCardHeight = DISPLAY_CONFIG.CARD_HEIGHT
        for lineIdx = 1, maxCardHeight do
            local line = ""
            for _, card in ipairs(cardLines) do
                if card[lineIdx] then
                    line = line .. card[lineIdx] .. "  "
                else
                    line = line .. string.rep(" ", DISPLAY_CONFIG.CARD_WIDTH + 2)
                end
            end
            print(line)
        end
        print("")
    end
end

-- ==================== 回合信息 ====================

--- 显示回合信息
---@param round number 当前回合
---@param maxRound number 最大回合数
function BattleDisplay.ShowRoundInfo(round, maxRound)
    round = round or BattleMain.GetCurrentRound() or 0
    maxRound = maxRound or 100
    
    local percent = round / maxRound
    local roundColor = COLORS.BRIGHT_GREEN
    if percent > 0.7 then
        roundColor = COLORS.BRIGHT_RED
    elseif percent > 0.4 then
        roundColor = COLORS.BRIGHT_YELLOW
    end
    
    local roundText = string.format(" ╔══════════════════════════════════════════════════════════════════╗")
    print(ColorText(roundText, COLORS.BRIGHT_WHITE))
    
    roundText = string.format(" ║                    ROUND %3d / %3d                               ║", round, maxRound)
    print(ColorText(roundText, roundColor))
    
    roundText = string.format(" ╚══════════════════════════════════════════════════════════════════╝")
    print(ColorText(roundText, COLORS.BRIGHT_WHITE))
end

-- ==================== 行动顺序 ====================

--- 显示行动顺序条
---@param heroList table 英雄列表 (按行动顺序)
function BattleDisplay.ShowActionOrder(heroList)
    if not heroList or #heroList == 0 then
        return
    end
    
    print("")
    print(ColorText("【行动顺序】", COLORS.BRIGHT_WHITE))
    
    local actionBar = " "
    for i, hero in ipairs(heroList) do
        if i > 6 then break end -- 最多显示6个
        
        local teamColor = GetTeamColor(hero.isLeft)
        local heroName = hero.name or "?"
        if #heroName > 3 then
            heroName = heroName:sub(1, 3)
        end
        
        local arrow = (i < #heroList and i < 6) and ColorText(" → ", COLORS.BRIGHT_BLACK) or ""
        actionBar = actionBar .. teamColor .. heroName .. COLORS.RESET .. arrow
    end
    
    print(actionBar)
end

-- ==================== 战斗日志 ====================

--- 添加战斗日志
---@param message string 日志消息
function BattleDisplay.AddBattleLog(message)
    if not message then
        return
    end
    
    table.insert(battleLogCache, 1, message)
    
    -- 限制缓存大小
    if #battleLogCache > maxLogCacheSize then
        table.remove(battleLogCache)
    end
end

--- 显示战斗日志
---@param messages table 消息列表 (可选，使用缓存)
function BattleDisplay.ShowBattleLog(messages)
    messages = messages or {}
    
    -- 如果有传入消息，添加到缓存
    if #messages > 0 then
        for i = #messages, 1, -1 do
            BattleDisplay.AddBattleLog(messages[i])
        end
    end
    
    print("")
    print(ColorText("【战斗日志】", COLORS.BRIGHT_WHITE))
    print(ColorText("────────────────────────────────────────────────────────────────────", COLORS.BRIGHT_BLACK))
    
    local displayCount = math.min(#battleLogCache, DISPLAY_CONFIG.MAX_LOG_LINES)
    for i = displayCount, 1, -1 do
        local msg = battleLogCache[i]
        if msg then
            -- 根据消息类型着色
            local msgColor = COLORS.WHITE
            if msg:find("伤害") or msg:find("攻击") then
                msgColor = COLORS.BRIGHT_RED
            elseif msg:find("治疗") or msg:find("恢复") then
                msgColor = COLORS.BRIGHT_GREEN
            elseif msg:find("Buff") or msg:find("buff") then
                msgColor = COLORS.BRIGHT_YELLOW
            elseif msg:find("阵亡") or msg:find("死亡") then
                msgColor = COLORS.BRIGHT_MAGENTA
            elseif msg:find("胜利") or msg:find("获胜") then
                msgColor = COLORS.BRIGHT_CYAN
            end
            
            print(" " .. ColorText("> " .. msg, msgColor))
        end
    end
    
    print(ColorText("────────────────────────────────────────────────────────────────────", COLORS.BRIGHT_BLACK))
end

--- 清空战斗日志
function BattleDisplay.ClearBattleLog()
    battleLogCache = {}
end

-- ==================== 胜利/失败画面 ====================

--- 显示胜利/失败画面
---@param winner string 获胜方 ("left", "right", "draw", nil)
function BattleDisplay.ShowVictoryScreen(winner)
    print("")
    print("")
    
    local victoryArt = {
        "╔══════════════════════════════════════════════════════════════════════╗",
        "║                                                                      ║",
        "║   ██╗   ██╗██╗ ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗            ║",
        "║   ██║   ██║██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝            ║",
        "║   ██║   ██║██║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝             ║",
        "║   ╚██╗ ██╔╝██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝              ║",
        "║    ╚████╔╝ ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║               ║",
        "║     ╚═══╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝               ║",
        "║                                                                      ║",
        "╚══════════════════════════════════════════════════════════════════════╝",
    }
    
    local defeatArt = {
        "╔══════════════════════════════════════════════════════════════════════╗",
        "║                                                                      ║",
        "║   ██████╗ ███████╗███████╗███████╗ █████╗ ████████╗                  ║",
        "║   ██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗╚══██╔══╝                  ║",
        "║   ██║  ██║█████╗  █████╗  █████╗  ███████║   ██║                     ║",
        "║   ██║  ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██║   ██║                     ║",
        "║   ██████╔╝███████╗██║     ███████╗██║  ██║   ██║                     ║",
        "║   ╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝                     ║",
        "║                                                                      ║",
        "╚══════════════════════════════════════════════════════════════════════╝",
    }
    
    local drawArt = {
        "╔══════════════════════════════════════════════════════════════════════╗",
        "║                                                                      ║",
        "║   ██████╗ ██████╗  █████╗ ██╗    ██╗                                 ║",
        "║   ██╔══██╗██╔══██╗██╔══██╗██║    ██║                                 ║",
        "║   ██║  ██║██████╔╝███████║██║ █╗ ██║                                 ║",
        "║   ██║  ██║██╔══██╗██╔══██║██║███╗██║                                 ║",
        "║   ██████╔╝██║  ██║██║  ██║╚███╔███╔╝                                 ║",
        "║   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝                                  ║",
        "║                                                                      ║",
        "╚══════════════════════════════════════════════════════════════════════╝",
    }
    
    local art = victoryArt
    local resultColor = COLORS.BRIGHT_GREEN
    local resultText = ""
    
    if winner == "left" then
        art = victoryArt
        resultColor = COLORS.BRIGHT_CYAN
        resultText = "左侧队伍获胜！"
    elseif winner == "right" then
        art = victoryArt
        resultColor = COLORS.BRIGHT_MAGENTA
        resultText = "右侧队伍获胜！"
    elseif winner == "draw" then
        art = drawArt
        resultColor = COLORS.BRIGHT_YELLOW
        resultText = "平局！"
    else
        art = defeatArt
        resultColor = COLORS.BRIGHT_RED
        resultText = "战斗结束"
    end
    
    -- 打印艺术字
    for _, line in ipairs(art) do
        print(ColorText(line, resultColor))
    end
    
    print("")
    print(ColorText("                    " .. resultText, resultColor))
    print("")
    
    -- 显示统计信息
    local leftAlive = BattleFormation.GetAliveHeroCount(true)
    local rightAlive = BattleFormation.GetAliveHeroCount(false)
    local leftTotal = #BattleFormation.teamLeft
    local rightTotal = #BattleFormation.teamRight
    
    print(ColorText(string.format("              左侧队伍存活: %d/%d", leftAlive, leftTotal), COLORS.BRIGHT_CYAN))
    print(ColorText(string.format("              右侧队伍存活: %d/%d", rightAlive, rightTotal), COLORS.BRIGHT_MAGENTA))
    print("")
end

-- ==================== 刷新显示 ====================

--- 刷新整个显示
function BattleDisplay.Refresh()
    BattleDisplay.ClearScreen()
    
    -- 显示回合信息
    BattleDisplay.ShowRoundInfo()
    
    -- 显示战场
    BattleDisplay.ShowBattleField()
    
    -- 显示行动顺序
    local allHeroes = BattleFormation.GetAllAliveHeroes()
    -- 按行动力排序 (简化版)
    table.sort(allHeroes, function(a, b)
        return (a.actionForce or 0) > (b.actionForce or 0)
    end)
    BattleDisplay.ShowActionOrder(allHeroes)
    
    -- 显示战斗日志
    BattleDisplay.ShowBattleLog()
end

-- ==================== 其他显示功能 ====================

--- 显示分隔线
---@param title string 标题 (可选)
function BattleDisplay.ShowSeparator(title)
    if title then
        local line = "═══ " .. title .. " "
        local remaining = 70 - #line
        if remaining > 0 then
            line = line .. string.rep("═", remaining)
        end
        print(ColorText(line, COLORS.BRIGHT_WHITE))
    else
        print(ColorText(string.rep("═", 70), COLORS.BRIGHT_BLACK))
    end
end

--- 显示标题
---@param title string 标题文本
function BattleDisplay.ShowTitle(title)
    print("")
    local padding = math.floor((70 - #title) / 2)
    local line = string.rep(" ", padding) .. ColorText(title, COLORS.BRIGHT_WHITE .. "\27[1m")
    print(line)
    print(ColorText(string.rep("─", 70), COLORS.BRIGHT_BLACK))
end

--- 显示提示信息
---@param message string 消息
---@param messageType string 消息类型 ("info", "warning", "error", "success")
function BattleDisplay.ShowMessage(message, messageType)
    messageType = messageType or "info"
    local color = COLORS.WHITE
    local prefix = "[INFO]"
    
    if messageType == "warning" then
        color = COLORS.BRIGHT_YELLOW
        prefix = "[WARN]"
    elseif messageType == "error" then
        color = COLORS.BRIGHT_RED
        prefix = "[ERROR]"
    elseif messageType == "success" then
        color = COLORS.BRIGHT_GREEN
        prefix = "[SUCCESS]"
    end
    
    print(ColorText(prefix .. " " .. message, color))
end

--- 显示加载画面
---@param progress number 进度 (0-1)
---@param message string 加载消息
function BattleDisplay.ShowLoading(progress, message)
    message = message or "Loading..."
    local width = 40
    local filled = math.floor(width * progress)
    local empty = width - filled
    
    local bar = "[" .. string.rep("█", filled) .. string.rep("░", empty) .. "]"
    local percent = math.floor(progress * 100)
    
    io.write("\r" .. message .. " " .. bar .. " " .. percent .. "%")
    io.flush()
    
    if progress >= 1 then
        print("")
    end
end

-- ==================== 事件监听器注册 ====================

local BattleEvent = require("core.battle_event")

--- 注册战斗显示相关的事件监听器
-- 应在 BattleMain.Start 之后调用（因为 Start 会清空监听器）
function BattleDisplay.RegisterEventListeners()
    -- 伤害事件
    BattleEvent.AddListener("Damage", function(target, amount, isCrit)
        local critMark = isCrit and " ⚡" or ""
        local msg = string.format("%s 受到 %d 点伤害%s", target.name, amount, critMark)
        BattleDisplay.AddBattleLog(msg)
    end)
    
    -- 治疗事件
    BattleEvent.AddListener("Heal", function(target, amount)
        local msg = string.format("%s 恢复 %d 点生命", target.name, amount)
        BattleDisplay.AddBattleLog(msg)
    end)
    
    -- Buff添加事件
    BattleEvent.AddListener("BUFF_ADDED", function(caster, target, buff)
        local msg = string.format("%s 获得 Buff [%s]", target.name, buff.name)
        BattleDisplay.AddBattleLog(msg)
    end)
    
    -- 技能施放事件
    BattleEvent.AddListener("SkillCast", function(hero, target, skillName)
        local msg = string.format("%s 对 %s 使用 [%s]", hero.name, target.name, skillName)
        BattleDisplay.AddBattleLog(msg)
    end)
    
    -- 能量消耗事件
    BattleEvent.AddListener("ENERGY_CONSUMED", function(hero, amount)
        BattleDisplay.Refresh()
    end)
end

return BattleDisplay
