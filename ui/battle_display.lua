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
    CARD_WIDTH = 28,
    CARD_HEIGHT = 10,
    HP_BAR_WIDTH = 20,
    ENERGY_BAR_WIDTH = 20,
    MAX_LOG_LINES = 8,
    TEAM_GAP = 4,
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
    -- Windows使用cls，Unix使用clear
    if package.config:sub(1, 1) == "\\" then
        os.execute("cls")
    else
        os.execute("clear")
    end
    -- 备用方案：打印空行
    for i = 1, 50 do
        print("")
    end
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
    
    local hpText = string.format("%d/%d", current, max)
    -- 将数字居中显示在条上
    local textStart = math.floor((width - #hpText) / 2)
    if textStart > 0 and textStart + #hpText <= width then
        bar = bar:sub(1, textStart) .. hpText .. bar:sub(textStart + #hpText + 1)
    end
    
    return ColorText("[" .. bar .. "]", hpColor)
end

--- 绘制能量条
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
        if i < maxPoints then
            bar = bar .. ""
        end
    end
    
    return "[" .. bar .. "] " .. ColorText(tostring(points) .. "/" .. maxPoints, energyColor)
end

--- 绘制能量条(Bar类型)
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
    
    local filledChar = "█"
    local emptyChar = "░"
    
    local bar = string.rep(filledChar, filled) .. string.rep(emptyChar, empty)
    local energyText = string.format("%d%%", math.floor(percent * 100))
    
    return ColorText("[" .. bar .. "] " .. energyText, COLORS.BRIGHT_YELLOW)
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
function BattleDisplay.ShowBuffList(buffList, x, y)
    if not buffList or #buffList == 0 then
        return
    end
    
    -- 限制显示的buff数量
    local maxDisplay = 4
    local displayCount = math.min(#buffList, maxDisplay)
    
    local buffIcons = ""
    for i = 1, displayCount do
        local buff = buffList[i]
        local icon = buff.icon or "●"
        local color = GetBuffTypeColor(buff.mainType)
        
        -- 显示层数
        local stackText = ""
        if buff.stackCount and buff.stackCount > 1 then
            stackText = tostring(buff.stackCount)
        end
        
        buffIcons = buffIcons .. ColorText(icon .. stackText, color) .. " "
    end
    
    -- 如果还有更多buff，显示省略号
    if #buffList > maxDisplay then
        buffIcons = buffIcons .. ColorText("...", COLORS.BRIGHT_BLACK)
    end
    
    return buffIcons
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

--- 显示技能冷却状态
---@param hero table 英雄对象
---@return string 技能冷却字符串
local function ShowSkillCooldowns(hero)
    if not hero or not hero.skills then
        return ""
    end
    
    local cooldownText = ""
    local skillCount = 0
    
    for _, skill in ipairs(hero.skills) do
        if skillCount >= 3 then break end -- 最多显示3个技能
        
        local skillName = skill.name or "Skill"
        -- 缩短技能名
        if #skillName > 4 then
            skillName = skillName:sub(1, 4)
        end
        
        local cd = skill.coolDown or 0
        local maxCd = skill.maxCoolDown or 0
        
        if cd > 0 then
            cooldownText = cooldownText .. ColorText(skillName .. "(" .. cd .. ")", COLORS.BRIGHT_RED) .. " "
        else
            cooldownText = cooldownText .. ColorText(skillName .. "(✓)", COLORS.BRIGHT_GREEN) .. " "
        end
        
        skillCount = skillCount + 1
    end
    
    return cooldownText
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
    if #name > width - 4 then
        name = name:sub(1, width - 4)
    end
    local namePadding = width - 4 - #name
    local nameLine = " " .. name .. string.rep(" ", namePadding) .. " "
    if isDead then
        nameLine = ColorText(nameLine, COLORS.BRIGHT_BLACK)
    else
        nameLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. ColorText(nameLine, teamColor) .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    end
    table.insert(lines, nameLine)
    
    -- 分隔线
    table.insert(lines, teamColor .. BORDERS.T_LEFT .. string.rep(BORDERS.HORIZONTAL, width - 2) .. BORDERS.T_RIGHT .. COLORS.RESET)
    
    -- HP条
    local hpBar = BattleDisplay.ShowHpBar(hero.hp or 0, hero.maxHp or 100, width - 4)
    local hpLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. " " .. hpBar .. " " .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, hpLine)
    
    -- 能量条
    local energyLine = ""
    if hero.energyType == E_ENERGY_TYPE.Point then
        local energyBar = BattleDisplay.ShowEnergyBar(hero.energy or 0, hero.maxEnergy or 5, width - 4)
        energyLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. " " .. energyBar .. " " .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    else
        local energyBar = BattleDisplay.ShowEnergyBarType(hero.energy or 0, hero.maxEnergy or 100, width - 4)
        energyLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. " " .. energyBar .. " " .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    end
    table.insert(lines, energyLine)
    
    -- Buff列表
    local buffList = BattleBuff.GetAllBuffs(hero)
    local buffText = BattleDisplay.ShowBuffList(buffList, 0, 0) or ""
    local buffPadding = width - 4 - #buffText
    if buffPadding < 0 then buffPadding = 0 end
    local buffLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. " Buff:" .. buffText .. string.rep(" ", buffPadding) .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, buffLine)
    
    -- 技能冷却
    local cooldownText = ShowSkillCooldowns(hero)
    local cdPadding = width - 4 - #cooldownText
    if cdPadding < 0 then cdPadding = 0 end
    local cdLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. " " .. cooldownText .. string.rep(" ", cdPadding) .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, cdLine)
    
    -- 状态信息
    local statusText = ""
    if isDead then
        statusText = ColorText(" ☠ 已阵亡 ", COLORS.BRIGHT_RED)
    elseif BattleBuff.IsHeroUnderControl(hero) then
        statusText = ColorText(" ⚠ 被控制 ", COLORS.BRIGHT_YELLOW)
    else
        statusText = ColorText(" ♥ 存活 ", COLORS.BRIGHT_GREEN)
    end
    local statusPadding = width - 4 - #statusText
    if statusPadding < 0 then statusPadding = 0 end
    local statusLine = teamColor .. BORDERS.VERTICAL .. COLORS.RESET .. " " .. statusText .. string.rep(" ", statusPadding) .. teamColor .. BORDERS.VERTICAL .. COLORS.RESET
    table.insert(lines, statusLine)
    
    -- 卡片底部边框
    table.insert(lines, teamColor .. BORDERS.BOTTOM_LEFT .. string.rep(BORDERS.HORIZONTAL, width - 2) .. BORDERS.BOTTOM_RIGHT .. COLORS.RESET)
    
    return lines
end

-- ==================== 战场显示 ====================

--- 显示战场 (双方队伍)
---@param teamLeft table 左侧队伍
---@param teamRight table 右侧队伍
function BattleDisplay.ShowBattleField(teamLeft, teamRight)
    teamLeft = teamLeft or BattleFormation.teamLeft
    teamRight = teamRight or BattleFormation.teamRight
    
    print("")
    print(ColorText("                    ⚔ BATTLE FIELD ⚔", COLORS.BRIGHT_WHITE))
    print("")
    
    -- 显示队伍标题
    local leftTitle = ColorText("【左侧队伍】", COLORS.BRIGHT_CYAN)
    local rightTitle = ColorText("【右侧队伍】", COLORS.BRIGHT_MAGENTA)
    local gap = string.rep(" ", DISPLAY_CONFIG.TEAM_GAP)
    print(leftTitle .. string.rep(" ", DISPLAY_CONFIG.CARD_WIDTH * 2 + DISPLAY_CONFIG.TEAM_GAP - 16) .. rightTitle)
    print("")
    
    -- 准备所有英雄卡片
    local leftCards = {}
    for _, hero in ipairs(teamLeft) do
        table.insert(leftCards, BattleDisplay.ShowHeroCard(hero))
    end
    
    local rightCards = {}
    for _, hero in ipairs(teamRight) do
        table.insert(rightCards, BattleDisplay.ShowHeroCard(hero))
    end
    
    -- 计算最大行数
    local maxCards = math.max(#leftCards, #rightCards)
    local cardsPerRow = 2 -- 每行显示2个英雄
    
    -- 显示英雄卡片 (左右并排)
    for row = 1, math.ceil(maxCards / cardsPerRow) do
        -- 获取当前行的英雄
        local leftHeroes = {}
        local rightHeroes = {}
        
        for i = 1, cardsPerRow do
            local idx = (row - 1) * cardsPerRow + i
            if idx <= #teamLeft then
                table.insert(leftHeroes, teamLeft[idx])
            end
            if idx <= #teamRight then
                table.insert(rightHeroes, teamRight[idx])
            end
        end
        
        -- 生成卡片行
        local leftCardLines = {}
        for _, hero in ipairs(leftHeroes) do
            table.insert(leftCardLines, BattleDisplay.ShowHeroCard(hero))
        end
        
        local rightCardLines = {}
        for _, hero in ipairs(rightHeroes) do
            table.insert(rightCardLines, BattleDisplay.ShowHeroCard(hero))
        end
        
        -- 合并打印左右卡片
        local maxCardHeight = DISPLAY_CONFIG.CARD_HEIGHT
        for lineIdx = 1, maxCardHeight do
            local line = ""
            
            -- 左侧卡片
            for _, card in ipairs(leftCardLines) do
                if card[lineIdx] then
                    line = line .. card[lineIdx] .. "  "
                else
                    line = line .. string.rep(" ", DISPLAY_CONFIG.CARD_WIDTH + 2)
                end
            end
            
            -- 中间间隔
            line = line .. string.rep(" ", DISPLAY_CONFIG.TEAM_GAP)
            
            -- 右侧卡片
            for _, card in ipairs(rightCardLines) do
                if card[lineIdx] then
                    line = line .. card[lineIdx] .. "  "
                else
                    line = line .. string.rep(" ", DISPLAY_CONFIG.CARD_WIDTH + 2)
                end
            end
            
            print(line)
        end
        
        print("") -- 行间隔
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

return BattleDisplay
