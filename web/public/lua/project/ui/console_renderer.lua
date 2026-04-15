---
--- Console Renderer
--- 控制台渲染器 - 订阅战斗可视化事件，用文本方式呈现战斗
---
--- 该模块订阅 BattleVisualEvents 定义的事件，使用 ANSI 颜色代码
--- 和 ASCII 字符在控制台中呈现战斗画面。
---
--- 未来可扩展：
--- - WebRenderer: 用 2D Sprite 呈现
--- - UnityRenderer: 用 3D Animation 呈现
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")
local BattleFormation = require("modules.battle_formation")

---@class ConsoleRenderer
local ConsoleRenderer = {}

-- 临时状态缓存
local tempState = {
    -- 伤害数字缓存：heroId => { value, type } (按回合记录，不自动消失)
    damageNumbers = {},
    -- 高亮状态缓存：heroId => { type, time }
    highlight = {},
    -- 本回合是否已经刷新过（用于减少冗余显示）
    hasRefreshedThisTurn = false,
}

-- ==================== 配置常量 ====================

-- ANSI 颜色代码
local COLORS = {
    RESET = "\27[0m",
    BOLD = "\27[1m",
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
}

-- 显示配置
-- 每行3个卡片，每个卡片宽度 = (80 - 2*2) / 3 ≈ 25
-- 80列终端 - 2个间距(2*2=4) = 76，76/3 ≈ 25
local CONFIG = {
    CARD_WIDTH = 25,
    CARD_HEIGHT = 12,  -- 增加1行用于显示伤害数字
    HP_BAR_WIDTH = 18,
    ENERGY_BAR_WIDTH = 18,
    MAX_LOG_LINES = 8,
}

-- 状态
local isInitialized = false
local battleLogCache = {}
local maxLogCacheSize = 50

local GetBuffDisplaySuffix

-- ==================== 初始化与清理 ====================

--- 初始化控制台渲染器
function ConsoleRenderer.Init()
    if isInitialized then
        return
    end
    
    -- 清空临时状态
    tempState.damageNumbers = {}
    tempState.highlight = {}
    tempState.hasRefreshedThisTurn = false
    
    -- 订阅战斗可视化事件
    ConsoleRenderer.RegisterEventListeners()
    
    isInitialized = true
    Logger.Log("[ConsoleRenderer] 控制台渲染器初始化完成")
end

--- 清理控制台渲染器
function ConsoleRenderer.OnFinal()
    -- 取消订阅事件（逐个移除）
    BattleEvent.RemoveListener(BattleVisualEvents.BATTLE_STARTED, ConsoleRenderer.OnBattleStarted)
    BattleEvent.RemoveListener(BattleVisualEvents.BATTLE_ENDED, ConsoleRenderer.OnBattleEnded)
    BattleEvent.RemoveListener(BattleVisualEvents.VICTORY, ConsoleRenderer.OnVictory)
    BattleEvent.RemoveListener(BattleVisualEvents.DEFEAT, ConsoleRenderer.OnDefeat)
    BattleEvent.RemoveListener(BattleVisualEvents.DRAW, ConsoleRenderer.OnDraw)
    BattleEvent.RemoveListener(BattleVisualEvents.TURN_STARTED, ConsoleRenderer.OnTurnStarted)
    BattleEvent.RemoveListener(BattleVisualEvents.TURN_ENDED, ConsoleRenderer.OnTurnEnded)
    BattleEvent.RemoveListener(BattleVisualEvents.HERO_STATE_CHANGED, ConsoleRenderer.OnHeroStateChanged)
    BattleEvent.RemoveListener(BattleVisualEvents.HERO_DIED, ConsoleRenderer.OnHeroDied)
    BattleEvent.RemoveListener(BattleVisualEvents.DAMAGE_DEALT, ConsoleRenderer.OnDamageDealt)
    BattleEvent.RemoveListener(BattleVisualEvents.HEAL_RECEIVED, ConsoleRenderer.OnHealReceived)
    BattleEvent.RemoveListener(BattleVisualEvents.SKILL_CAST_STARTED, ConsoleRenderer.OnSkillCastStarted)
    BattleEvent.RemoveListener(BattleVisualEvents.BUFF_ADDED, ConsoleRenderer.OnBuffAdded)
    BattleEvent.RemoveListener(BattleVisualEvents.BUFF_REMOVED, ConsoleRenderer.OnBuffRemoved)
    BattleEvent.RemoveListener(BattleVisualEvents.DODGE, ConsoleRenderer.OnDodge)
    BattleEvent.RemoveListener(BattleVisualEvents.CRIT, ConsoleRenderer.OnCrit)
    BattleEvent.RemoveListener(BattleVisualEvents.BLOCK, ConsoleRenderer.OnBlock)
    
    isInitialized = false
    Logger.Log("[ConsoleRenderer] 控制台渲染器已清理")
end

--- 注册事件监听器
function ConsoleRenderer.RegisterEventListeners()
    -- 战斗开始/结束
    BattleEvent.AddListener(BattleVisualEvents.BATTLE_STARTED, ConsoleRenderer.OnBattleStarted, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.BATTLE_ENDED, ConsoleRenderer.OnBattleEnded, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.VICTORY, ConsoleRenderer.OnVictory, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.DEFEAT, ConsoleRenderer.OnDefeat, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.DRAW, ConsoleRenderer.OnDraw, "ConsoleRenderer")
    
    -- 回合事件
    BattleEvent.AddListener(BattleVisualEvents.TURN_STARTED, ConsoleRenderer.OnTurnStarted, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.TURN_ENDED, ConsoleRenderer.OnTurnEnded, "ConsoleRenderer")
    
    -- 英雄状态
    BattleEvent.AddListener(BattleVisualEvents.HERO_STATE_CHANGED, ConsoleRenderer.OnHeroStateChanged, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.HERO_DIED, ConsoleRenderer.OnHeroDied, "ConsoleRenderer")
    
    -- 战斗动作
    BattleEvent.AddListener(BattleVisualEvents.DAMAGE_DEALT, ConsoleRenderer.OnDamageDealt, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.HEAL_RECEIVED, ConsoleRenderer.OnHealReceived, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.SKILL_CAST_STARTED, ConsoleRenderer.OnSkillCastStarted, "ConsoleRenderer")
    
    -- Buff事件
    BattleEvent.AddListener(BattleVisualEvents.BUFF_ADDED, ConsoleRenderer.OnBuffAdded, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.BUFF_REMOVED, ConsoleRenderer.OnBuffRemoved, "ConsoleRenderer")
    
    -- 特殊事件
    BattleEvent.AddListener(BattleVisualEvents.DODGE, ConsoleRenderer.OnDodge, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.CRIT, ConsoleRenderer.OnCrit, "ConsoleRenderer")
    BattleEvent.AddListener(BattleVisualEvents.BLOCK, ConsoleRenderer.OnBlock, "ConsoleRenderer")
end

-- ==================== 工具函数 ====================

--- 给文本添加颜色
local function ColorText(text, color)
    return color .. text .. COLORS.RESET
end

--- 获取HP颜色
local function GetHpColor(hpPercent)
    if hpPercent > 0.6 then
        return COLORS.BRIGHT_GREEN
    elseif hpPercent > 0.3 then
        return COLORS.BRIGHT_YELLOW
    else
        return COLORS.BRIGHT_RED
    end
end

--- 获取队伍颜色
local function GetTeamColor(isLeft)
    return isLeft and COLORS.BRIGHT_CYAN or COLORS.BRIGHT_MAGENTA
end

--- 清屏
function ConsoleRenderer.ClearScreen()
    io.write("\27[2J\27[H")
    io.flush()
end

--- 添加战斗日志
function ConsoleRenderer.AddBattleLog(message)
    if not message then
        return
    end
    
    table.insert(battleLogCache, 1, message)
    
    if #battleLogCache > maxLogCacheSize then
        table.remove(battleLogCache)
    end
end

-- ==================== 事件处理器 ====================

--- 战斗开始
function ConsoleRenderer.OnBattleStarted(data)
    -- 清空临时状态
    tempState.damageNumbers = {}
    tempState.highlight = {}
    tempState.hasRefreshedThisTurn = false
    
    ConsoleRenderer.ClearScreen()
    print("")
    print(ColorText("╔══════════════════════════════════════════════════════════════════════╗", COLORS.BRIGHT_WHITE))
    print(ColorText("║                    BATTLE STARTED                                    ║", COLORS.BRIGHT_GREEN))
    print(ColorText("╚══════════════════════════════════════════════════════════════════════╝", COLORS.BRIGHT_WHITE))
    print("")
end

--- 战斗结束
function ConsoleRenderer.OnBattleEnded(data)
    print("")
    print(ColorText("═══════════════════════════════════════════════════════════════════════", COLORS.BRIGHT_BLACK))
    print(ColorText("                        BATTLE ENDED                                   ", COLORS.BRIGHT_WHITE))
    print(ColorText("═══════════════════════════════════════════════════════════════════════", COLORS.BRIGHT_BLACK))
    print("")
end

--- 胜利
function ConsoleRenderer.OnVictory(data)
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
    
    print("")
    for _, line in ipairs(victoryArt) do
        print(ColorText(line, COLORS.BRIGHT_GREEN))
    end
    
    local winnerText = data.winner == "left" and "左侧队伍获胜！" or "右侧队伍获胜！"
    print("")
    print(ColorText("                    " .. winnerText, COLORS.BRIGHT_GREEN))
    print("")
end

--- 失败
function ConsoleRenderer.OnDefeat(data)
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
    
    print("")
    for _, line in ipairs(defeatArt) do
        print(ColorText(line, COLORS.BRIGHT_RED))
    end
    print("")
end

--- 平局
function ConsoleRenderer.OnDraw(data)
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
    
    print("")
    for _, line in ipairs(drawArt) do
        print(ColorText(line, COLORS.BRIGHT_YELLOW))
    end
    print("")
    print(ColorText("                        平局！", COLORS.BRIGHT_YELLOW))
    print("")
end

--- 回合开始
function ConsoleRenderer.OnTurnStarted(data)
    -- 1. 先清空上一回合的伤害数字记录
    tempState.damageNumbers = {}
    tempState.hasRefreshedThisTurn = false
    
    -- 2. 显示回合信息
    print("")
    local roundText = string.format("═══════════════════ ROUND %3d ═══════════════════", data.round)
    print(ColorText(roundText, COLORS.BRIGHT_WHITE))
    
    if data.heroName then
        local heroText = string.format("→ %s 的回合", data.heroName)
        local teamColor = GetTeamColor(data.team == "left")
        print(ColorText(heroText, teamColor))
    end
end

--- 回合结束
function ConsoleRenderer.OnTurnEnded(data)
    -- 如果这一回合没有任何重要事件触发过刷新，则在回合结束时刷新一次
    if not tempState.hasRefreshedThisTurn then
        ConsoleRenderer.Refresh()
    end
end

--- 英雄状态变化
function ConsoleRenderer.OnHeroStateChanged(data)
    -- 状态变化时更新显示（可选：实时刷新英雄卡片）
    -- 在控制台中，我们只在关键事件时刷新
end

--- 英雄阵亡
function ConsoleRenderer.OnHeroDied(data)
    local msg = string.format("☠ %s 阵亡了！", data.heroName)
    print(ColorText(msg, COLORS.BRIGHT_RED))
    ConsoleRenderer.AddBattleLog(msg)
    
    -- 英雄阵亡后刷新战场
    tempState.hasRefreshedThisTurn = true
    ConsoleRenderer.Refresh()
end

--- 伤害事件
function ConsoleRenderer.OnDamageDealt(data)
    local color = data.isCrit and COLORS.BRIGHT_RED or COLORS.RED
    local critMark = data.isCrit and " ⚡暴击⚡ " or " "
    local dodgeMark = data.isDodged and " 闪避!" or ""
    local blockMark = data.isBlocked and " 格挡!" or ""
    
    local msg
    if data.isDodged then
        msg = string.format("%s 闪避了 %s 的攻击", data.targetName, data.attackerName)
        color = COLORS.BRIGHT_YELLOW
    elseif data.damage > 0 then
        msg = string.format("%s%s对 %s 造成 %d 点伤害%s", 
            data.attackerName or "未知", critMark, data.targetName, data.damage, blockMark)
            
        -- 记录伤害数字到目标（直接覆盖最新伤害）
        local heroId = data.targetId
        if heroId then
            tempState.damageNumbers[heroId] = {
                value = -data.damage,
                type = data.isCrit and "crit" or "damage"
            }
        end
        
        -- 高亮攻击者
        local attackerId = data.attackerId
        if attackerId then
            tempState.highlight[attackerId] = {
                type = "attack",
                time = os.clock()
            }
        end
        
        -- 高亮目标（被攻击）
        if heroId then
            tempState.highlight[heroId] = {
                type = "defend",
                time = os.clock()
            }
        end
    else
        return -- 无伤害不显示
    end
    
    -- 使用io.write和flush确保立即输出
    io.write(ColorText("⚔ " .. msg, color) .. "\n")
    io.flush()
    ConsoleRenderer.AddBattleLog(msg)
    
    -- 立即刷新战场显示，显示伤害数字
    tempState.hasRefreshedThisTurn = true
    ConsoleRenderer.Refresh()
end

--- 治疗事件
function ConsoleRenderer.OnHealReceived(data)
    local color = COLORS.BRIGHT_GREEN
    local msg = string.format("%s 恢复 %d 点生命", data.targetName, data.healAmount)
    
    if data.healerName then
        msg = string.format("%s 治疗 %s %d 点生命", data.healerName, data.targetName, data.healAmount)
    end
    
    -- 记录治疗数字到目标（直接覆盖最新治疗）
    local targetId = data.targetId
    if targetId then
        tempState.damageNumbers[targetId] = {
            value = "+" .. data.healAmount,
            type = "heal"
        }
    end
    
    -- 高亮治疗者
    local healerId = data.healerId
    if healerId then
        tempState.highlight[healerId] = {
            type = "heal",
            time = os.clock()
        }
    end
    
    print(ColorText("✚ " .. msg, color))
    ConsoleRenderer.AddBattleLog(msg)
    
    -- 治疗后刷新战场
    tempState.hasRefreshedThisTurn = true
    ConsoleRenderer.Refresh()
end

--- 技能释放开始
function ConsoleRenderer.OnSkillCastStarted(data)
    local teamColor = GetTeamColor(data.heroId and string.find(data.heroId, "left"))
    local msg = string.format("%s 使用技能 【%s】", data.heroName, data.skillName)
    
    if data.targets and #data.targets > 0 then
        local targetNames = {}
        for _, t in ipairs(data.targets) do
            table.insert(targetNames, t.name)
        end
        msg = msg .. " → " .. table.concat(targetNames, ", ")
    end
    
    print("")
    print(ColorText("▶ " .. msg, teamColor))
    ConsoleRenderer.AddBattleLog(msg)
end

--- Buff添加
function ConsoleRenderer.OnBuffAdded(data)
    local typeColor = COLORS.BRIGHT_WHITE
    if data.buffType == E_BUFF_MAIN_TYPE.GOOD then
        typeColor = COLORS.BRIGHT_GREEN
    elseif data.buffType == E_BUFF_MAIN_TYPE.BAD then
        typeColor = COLORS.BRIGHT_RED
    elseif data.buffType == E_BUFF_MAIN_TYPE.CONTROL then
        typeColor = COLORS.BRIGHT_MAGENTA
    end
    
    local suffix = GetBuffDisplaySuffix(data)
    local msg = string.format("%s 获得 [%s%s]", data.targetName, data.buffName, suffix)
    
    print(ColorText("✦ " .. msg, typeColor))
    ConsoleRenderer.AddBattleLog(msg)
end

--- Buff移除
function ConsoleRenderer.OnBuffRemoved(data)
    local msg = string.format("%s 的 [%s] 效果消失", data.targetName, data.buffName)
    print(ColorText("✧ " .. msg, COLORS.BRIGHT_BLACK))
    ConsoleRenderer.AddBattleLog(msg)
end

--- 闪避
function ConsoleRenderer.OnDodge(data)
    local msg = string.format("%s 闪避了 %s 的攻击！", data.targetName, data.attackerName)
    print(ColorText("↷ " .. msg, COLORS.BRIGHT_YELLOW))
    ConsoleRenderer.AddBattleLog(msg)
end

--- 暴击
function ConsoleRenderer.OnCrit(data)
    -- 暴击通常在伤害事件中一起显示
end

--- 格挡
function ConsoleRenderer.OnBlock(data)
    local msg = string.format("%s 格挡了部分伤害！", data.targetName)
    print(ColorText("🛡 " .. msg, COLORS.BRIGHT_BLUE))
    ConsoleRenderer.AddBattleLog(msg)
end

-- ==================== 显示功能 ====================

--- 显示英雄卡片（简化版）
function ConsoleRenderer.ShowHeroCard(hero)
    if not hero then
        return
    end
    
    local teamColor = GetTeamColor(hero.isLeft)
    local hpPercent = hero.hp / hero.maxHp
    local hpColor = GetHpColor(hpPercent)
    
    -- 简化卡片显示
    print(string.format("%s%s%s", teamColor, hero.name, COLORS.RESET))
    
    -- HP条
    local filled = math.floor(CONFIG.HP_BAR_WIDTH * hpPercent)
    local empty = CONFIG.HP_BAR_WIDTH - filled
    local hpBar = string.rep("█", filled) .. string.rep("░", empty)
    print(string.format("  HP: %s%s%s %d/%d", hpColor, hpBar, COLORS.RESET, hero.hp, hero.maxHp))
    
    -- 能量
    print(string.format("  Energy: %d/%d", hero.energy or 0, hero.maxEnergy or 100))
    print("")
end

--- 显示战场
function ConsoleRenderer.ShowBattleField()
    local teamLeft = BattleFormation.teamLeft
    local teamRight = BattleFormation.teamRight
    
    if not teamLeft or not teamRight then
        return
    end
    
    print("")
    print(ColorText("【左侧队伍】", COLORS.BRIGHT_CYAN))
    for _, hero in ipairs(teamLeft) do
        if hero.isAlive then
            ConsoleRenderer.ShowHeroCard(hero)
        end
    end
    
    print(ColorText("【右侧队伍】", COLORS.BRIGHT_MAGENTA))
    for _, hero in ipairs(teamRight) do
        if hero.isAlive then
            ConsoleRenderer.ShowHeroCard(hero)
        end
    end
end

--- 显示战斗日志
function ConsoleRenderer.ShowBattleLog()
    if #battleLogCache == 0 then
        return
    end
    
    print("")
    print(ColorText("【战斗日志】", COLORS.BRIGHT_WHITE))
    print(ColorText("────────────────────────────────────────────────────────────────────", COLORS.BRIGHT_BLACK))
    
    local displayCount = math.min(#battleLogCache, CONFIG.MAX_LOG_LINES)
    for i = displayCount, 1, -1 do
        local msg = battleLogCache[i]
        if msg then
            print("  " .. msg)
        end
    end
end

--- 清空战斗日志
function ConsoleRenderer.ClearBattleLog()
    battleLogCache = {}
end

-- ==================== 战场显示功能（从 BattleDisplay 合并）====================

--- 获取字符串的实际显示宽度（处理中文、emoji和ANSI序列）
---@param str string 字符串
---@return number 显示宽度
local function GetDisplayWidth(str)
    if not str then return 0 end
    
    -- 1. 移除 ANSI 转义序列（颜色代码等）
    local cleanStr = str:gsub("\27%[[%d;]*%a", "")
    
    local width = 0
    local i = 1
    while i <= #cleanStr do
        local byte = cleanStr:byte(i)
        
        -- UTF-8 变体选择器 (U+FE0E, U+FE0F): EF B8 8E, EF B8 8F
        -- 这些字符在终端中宽度为 0，必须跳过
        if byte == 0xEF and cleanStr:byte(i+1) == 0xB8 and (cleanStr:byte(i+2) == 0x8E or cleanStr:byte(i+2) == 0x8F) then
            i = i + 3
        elseif byte < 128 then
            -- ASCII 字符
            width = width + 1
            i = i + 1
        elseif byte >= 192 and byte < 224 then
            -- 2 字节字符 (如 U+0080 - U+07FF)
            width = width + 1
            i = i + 2
        elseif byte >= 224 and byte < 240 then
            -- 3 字节字符 (如 中文 U+0800 - U+FFFF)
            width = width + 2
            i = i + 3
        elseif byte >= 240 then
            -- 4 字节字符 (如 Emoji U+10000 - U+10FFFF)
            width = width + 2
            i = i + 4
        else
            -- 无效字节，按 1 宽度跳过
            i = i + 1
        end
    end
    return width
end

--- 显示技能冷却状态
---@param hero table 英雄对象
---@return table {plain, colored, displayWidth}
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
        -- 缩短技能名到4个显示宽度
        if #skillName > 4 then
            skillName = skillName:sub(1, 4)
        end
        
        local cd = skill.coolDown or 0
        local skillNameWidth = #skillName
        
        if cd > 0 then
            local text = skillName .. "(" .. cd .. ")"
            cooldownTextPlain = cooldownTextPlain .. text
            cooldownTextColored = cooldownTextColored .. ColorText(skillName .. "(" .. cd .. ")", COLORS.BRIGHT_RED)
            displayWidth = displayWidth + skillNameWidth + 1 + #tostring(cd) + 1
        else
            local text = skillName .. "(✓)"
            cooldownTextPlain = cooldownTextPlain .. text
            cooldownTextColored = cooldownTextColored .. ColorText(skillName .. "(✓)", COLORS.BRIGHT_GREEN)
            displayWidth = displayWidth + skillNameWidth + 3
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

--- 显示HP条
---@param current number 当前HP
---@param max number 最大HP
---@param width number 条宽度
---@return string 格式化后的HP条
local function ShowHpBar(current, max, width)
    width = width or 20
    current = math.max(0, math.min(current, max))
    local percent = max > 0 and current / max or 0
    local filled = math.floor(width * percent)
    local empty = width - filled
    
    local filledChar = "█"
    local emptyChar = "░"
    
    local hpColor = GetHpColor(percent)
    local bar = string.rep(filledChar, filled) .. string.rep(emptyChar, empty)
    
    -- 返回带颜色的HP条（包括[]）
    return ColorText("[" .. bar .. "]", hpColor)
end

--- 显示能量条（Bar类型，使用=和-）
---@param current number 当前能量
---@param max number 最大能量
---@param width number 条宽度
---@return string 格式化后的能量条
local function ShowEnergyBar(current, max, width)
    width = width or 20
    local percent = max > 0 and current / max or 0
    local filled = math.floor(width * percent)
    local empty = width - filled
    
    local bar = "["
    for i = 1, filled do
        bar = bar .. "="
    end
    for i = 1, empty do
        bar = bar .. "-"
    end
    bar = bar .. "]"
    
    return ColorText(bar, COLORS.BRIGHT_YELLOW)
end

--- 显示能量条（Point类型，使用◆和◇）
---@param points number 当前能量点数
---@param maxPoints number 最大能量点数
---@return string 能量条字符串
local function ShowEnergyBarPoints(points, maxPoints)
    points = math.max(0, math.min(points, maxPoints))
    
    local bar = "["
    for i = 1, maxPoints do
        if i <= points then
            bar = bar .. ColorText("◆", COLORS.BRIGHT_YELLOW)
        else
            bar = bar .. ColorText("◇", COLORS.BRIGHT_BLACK)
        end
    end
    bar = bar .. "]"
    
    return bar
end

--- 获取能量数值文本（Point类型）
---@param points number 当前能量点数
---@param maxPoints number 最大能量点数
---@return string 能量数值字符串
local function ShowEnergyText(points, maxPoints)
    points = math.max(0, math.min(points, maxPoints))
    return ColorText(tostring(points) .. "/" .. maxPoints, COLORS.BRIGHT_YELLOW)
end

--- 获取能量百分比文本
---@param current number 当前能量
---@param max number 最大能量
---@return string 能量百分比字符串
local function ShowEnergyPercent(current, max)
    current = math.max(0, math.min(current, max))
    local percent = current / max
    local energyText = string.format("%d%%", math.floor(percent * 100))
    return ColorText(energyText, COLORS.BRIGHT_YELLOW)
end

--- 获取Buff类型颜色
---@param mainType number Buff主类型
---@return string 颜色代码
local function GetBuffTypeColor(mainType)
    if mainType == E_BUFF_MAIN_TYPE.GOOD then
        return COLORS.BRIGHT_GREEN
    elseif mainType == E_BUFF_MAIN_TYPE.BAD then
        return COLORS.BRIGHT_RED
    else
        return COLORS.BRIGHT_YELLOW
    end
end

GetBuffDisplaySuffix = function(buff)
    if not buff then
        return ""
    end

    if buff.displayMode == "pct" and type(buff.value) == "number" then
        return string.format(" %d%%", math.floor(buff.value / 100))
    end

    if buff.displayMode == "raw" and buff.value ~= nil then
        return " " .. tostring(buff.value)
    end

    if type(buff.stackCount) == "number" and buff.stackCount > 1 then
        return "x" .. tostring(buff.stackCount)
    end

    return ""
end

--- 显示Buff列表
---@param buffList table Buff列表
---@return table {plain, colored}
local function ShowBuffList(buffList)
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
        local stackText = GetBuffDisplaySuffix(buff)
        
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

--- 获取HP颜色
---@param percent number HP百分比
---@return string 颜色代码
local function GetHpColor(percent)
    if percent > 0.5 then
        return COLORS.BRIGHT_GREEN
    elseif percent > 0.25 then
        return COLORS.BRIGHT_YELLOW
    else
        return COLORS.BRIGHT_RED
    end
end

--- 显示英雄卡片（完整版）
---@param hero table 英雄对象
---@return table 卡片行列表
function ConsoleRenderer.ShowHeroCardFull(hero)
    if not hero then
        return {}
    end
    
    local BattleAttribute = require("modules.battle_attribute")
    
    -- 卡片配置（与 BattleDisplay 保持一致）
    local CARD_WIDTH = CONFIG.CARD_WIDTH
    local CONTENT_WIDTH = CARD_WIDTH - 2  -- 去掉左右边框
    
    -- 职业图标映射
    local JOB_ICONS = {
        [1] = "🛡️", -- 坦克
        [2] = "⚔️", -- 战士/物理输出
        [3] = "🔮", -- 法师/法术输出
        [4] = "💚", -- 治疗
        [5] = "✨", -- 辅助
        [6] = "🏹", -- 射手
    }
    
    local heroName = hero.name or "Unknown"
    local curHp = BattleAttribute.GetHeroCurHp(hero) or 0
    local maxHp = BattleAttribute.GetHeroMaxHp(hero) or 1
    
    -- 职业图标
    local jobIcon = JOB_ICONS[hero.class] or JOB_ICONS[hero.job] or "⚔️"
    -- 位置标识（前后排）
    local positionIcon = ""
    if hero.position then
        -- 位置1-2为前排，3-6为后排
        positionIcon = hero.position <= 2 and "前排" or "后排"
    end
    local hpPercent = maxHp > 0 and curHp / maxHp or 0
    local energy = hero.curEnergy or 0
    local maxEnergy = 100
    local isDead = hero.isDead or not hero.isAlive
    
    local hpColor = GetHpColor(hpPercent)
    local teamColor = hero.isLeft and COLORS.BRIGHT_CYAN or COLORS.BRIGHT_MAGENTA
    local statusIcon = isDead and "☠" or "♥"
    local statusText = isDead and "已阵亡" or "存活"
    
    -- 获取英雄ID（instanceId 或 id）
    local heroId = hero.instanceId or hero.id
    
    -- 检查高亮状态（2秒内的高亮）
    local highlight = tempState.highlight[heroId]
    local highlightColor = teamColor
    if highlight and (os.clock() - highlight.time) < 2 then
        if highlight.type == "attack" then
            highlightColor = COLORS.BRIGHT_YELLOW -- 攻击方黄色边框
        elseif highlight.type == "defend" then
            highlightColor = COLORS.BRIGHT_RED -- 被攻击方红色边框
        elseif highlight.type == "heal" then
            highlightColor = COLORS.BRIGHT_GREEN -- 治疗方绿色边框
        end
    end
    
    -- 检查伤害数字（按回合记录，不自动消失）
    local damageText = ""
    local damageColor = ""
    local dmgInfo = tempState.damageNumbers[heroId]
    if dmgInfo then
        damageText = tostring(dmgInfo.value)
        if dmgInfo.type == "crit" then
            damageColor = COLORS.BRIGHT_RED .. COLORS.BOLD
        elseif dmgInfo.type == "damage" then
            damageColor = COLORS.RED
        elseif dmgInfo.type == "heal" then
            damageColor = COLORS.BRIGHT_GREEN
        end
    end
    
    -- 获取Buff列表（直接从hero.buffs获取）
    local buffText = ""
    if hero.buffs and #hero.buffs > 0 then
        for i, buff in ipairs(hero.buffs) do
            if i <= 3 then
                buffText = buffText .. (buff.name or "Buff") .. " "
            end
        end
    end
    
    -- 构建卡片行
    local card = {}
    
    -- 1. 顶部边框
    table.insert(card, highlightColor .. "╔" .. string.rep("═", CARD_WIDTH - 2) .. "╗" .. COLORS.RESET)
    
    -- 2. 伤害数字行（独立一行，居中显示）
    if damageText ~= "" then
        local dmgDisplayWidth = GetDisplayWidth(damageText)
        local dmgPadding = CONTENT_WIDTH - dmgDisplayWidth
        local dmgLeftPad = math.floor(dmgPadding / 2)
        local dmgRightPad = dmgPadding - dmgLeftPad
        local dmgLine = string.rep(" ", dmgLeftPad) .. damageColor .. damageText .. COLORS.RESET .. string.rep(" ", dmgRightPad)
        table.insert(card, highlightColor .. "║" .. COLORS.RESET .. dmgLine .. highlightColor .. "║" .. COLORS.RESET)
    else
        -- 无伤害时显示空行
        table.insert(card, highlightColor .. "║" .. string.rep(" ", CONTENT_WIDTH) .. highlightColor .. "║" .. COLORS.RESET)
    end
    
    -- 2. 英雄名称行
    local nameWithPrefix = jobIcon .. " " .. heroName
    if positionIcon ~= "" then
        nameWithPrefix = nameWithPrefix .. " " .. positionIcon
    end
    
    local nameDisplayWidth = GetDisplayWidth(nameWithPrefix)
    while nameDisplayWidth > CONTENT_WIDTH - 2 and #nameWithPrefix > 0 do
        nameWithPrefix = nameWithPrefix:sub(1, -2)
        nameDisplayWidth = GetDisplayWidth(nameWithPrefix)
    end
    
    local namePadding = CONTENT_WIDTH - 2 - nameDisplayWidth
    local nameLeftPad = math.floor(namePadding / 2)
    local nameRightPad = namePadding - nameLeftPad
    
    local nameText = string.rep(" ", nameLeftPad) .. nameWithPrefix .. string.rep(" ", nameRightPad)
    local nameColor = isDead and COLORS.BRIGHT_BLACK or highlightColor
    
    -- 构建名称行：边框 + 空格 + 着色名称 + 空格 + 边框
    -- CONTENT_WIDTH = CARD_WIDTH - 2，去掉左右边框后剩余宽度
    -- 名称行内容宽度 = CONTENT_WIDTH - 2（左右各1个空格）
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. " " .. nameColor .. nameText .. COLORS.RESET .. " " .. highlightColor .. "║" .. COLORS.RESET)
    
    -- 分隔线
    table.insert(card, highlightColor .. "╠" .. string.rep("═", CARD_WIDTH - 2) .. "╣" .. COLORS.RESET)
    
    -- HP条（HP条长度 = CONTENT_WIDTH，包含[]）
    local hpBar = ShowHpBar(curHp, maxHp, CONTENT_WIDTH - 2)
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. hpBar .. highlightColor .. "║" .. COLORS.RESET)
    
    -- HP数值（右对齐，带颜色）
    local hpTextPlain = string.format("%d/%d", curHp, maxHp)
    local hpTextColored = ColorText(hpTextPlain, hpColor)
    local hpPadding = CONTENT_WIDTH - 1 - #hpTextPlain
    if hpPadding < 0 then hpPadding = 0 end
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. string.rep(" ", hpPadding) .. hpTextColored .. " " .. highlightColor .. "║" .. COLORS.RESET)
    
    -- 能量条（根据能量类型选择显示方式）
    local curEnergy = hero.curEnergy or hero.energy or 0
    local maxEnergy = hero.maxEnergy or 100
    local energyLine = ""
    local energyTextPlain = ""
    local energyTextColored = ""
    
    if hero.energyType == E_ENERGY_TYPE.Point then
        -- Point类型：显示点数
        local maxPoints = maxEnergy
        energyLine = ShowEnergyBarPoints(curEnergy, maxPoints)
        energyTextPlain = tostring(curEnergy) .. "/" .. maxPoints
        energyTextColored = ShowEnergyText(curEnergy, maxPoints)
    else
        -- Bar类型：显示百分比条
        energyLine = ShowEnergyBar(curEnergy, maxEnergy, CONTENT_WIDTH - 2)
        local percent = math.floor((curEnergy / maxEnergy) * 100)
        energyTextPlain = percent .. "%"
        energyTextColored = ShowEnergyPercent(curEnergy, maxEnergy)
    end
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. energyLine .. highlightColor .. "║" .. COLORS.RESET)
    
    -- 能量数值（右对齐，带颜色）
    local energyPadding = CONTENT_WIDTH - 1 - #energyTextPlain
    if energyPadding < 0 then energyPadding = 0 end
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. string.rep(" ", energyPadding) .. energyTextColored .. " " .. highlightColor .. "║" .. COLORS.RESET)
    
    -- Buff列表（使用ShowBuffList显示图标和层数）
    local buffResult = ShowBuffList(hero.buffs)
    local buffPadding = CONTENT_WIDTH - 5 - #buffResult.plain
    if buffPadding < 0 then buffPadding = 0 end
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. "Buff:" .. buffResult.colored .. string.rep(" ", buffPadding) .. highlightColor .. "║" .. COLORS.RESET)
    
    -- 技能冷却（显示实际技能状态）
    local cooldownResult = ShowSkillCooldowns(hero)
    local cdPadding = CONTENT_WIDTH - cooldownResult.displayWidth
    if cdPadding < 0 then cdPadding = 0 end
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. cooldownResult.colored .. string.rep(" ", cdPadding) .. highlightColor .. "║" .. COLORS.RESET)
    
    -- 状态行（考虑中文字符宽度）
    local statusTextPlain = ""
    local statusTextColored = ""
    local statusDisplayWidth = 0
    if isDead then
        statusTextPlain = "☠ 已阵亡"
        statusTextColored = ColorText(statusTextPlain, COLORS.BRIGHT_RED)
        -- ☠(1) + 空格(1) + 已(2) + 阵(2) + 亡(2) = 8
        statusDisplayWidth = 8
    else
        statusTextPlain = "♥ 存活"
        statusTextColored = ColorText(statusTextPlain, COLORS.BRIGHT_GREEN)
        -- ♥(1) + 空格(1) + 存(2) + 活(2) = 6
        statusDisplayWidth = 6
    end
    local statusPadding = CONTENT_WIDTH - statusDisplayWidth
    if statusPadding < 0 then statusPadding = 0 end
    table.insert(card, highlightColor .. "║" .. COLORS.RESET .. statusTextColored .. string.rep(" ", statusPadding) .. highlightColor .. "║" .. COLORS.RESET)
    
    -- 底部边框
    table.insert(card, highlightColor .. "╚" .. string.rep("═", CARD_WIDTH - 2) .. "╝" .. COLORS.RESET)
    
    return card
end

--- 显示战场（完整版）
function ConsoleRenderer.ShowBattleFieldFull()
    local BattleFormation = require("modules.battle_formation")
    local BattleMain = require("modules.battle_main")
    
    local teamLeft = BattleFormation.teamLeft
    local teamRight = BattleFormation.teamRight
    local currentRound = BattleMain.GetCurrentRound and BattleMain.GetCurrentRound() or 0
    
    print("")
    local titleText = string.format("              BATTLE FIELD - ROUND %3d", currentRound)
    local borderText = string.rep("═", #titleText + 4)
    print(ColorText("╔" .. borderText .. "╗", COLORS.BRIGHT_WHITE))
    print(ColorText("║  " .. titleText .. "  ║", COLORS.BRIGHT_WHITE))
    print(ColorText("╚" .. borderText .. "╝", COLORS.BRIGHT_WHITE))
    print("")
    
    -- 显示左侧队伍
    print(ColorText("【上方队伍 - 左侧】", COLORS.BRIGHT_CYAN))
    print("")
    
    local cardsPerRow = 3
    for row = 1, math.ceil(#teamLeft / cardsPerRow) do
        local heroes = {}
        for i = 1, cardsPerRow do
            local idx = (row - 1) * cardsPerRow + i
            if idx <= #teamLeft then
                table.insert(heroes, teamLeft[idx])
            end
        end
        
        local cardLines = {}
        for _, hero in ipairs(heroes) do
            table.insert(cardLines, ConsoleRenderer.ShowHeroCardFull(hero))
        end
        
        local maxCardHeight = CONFIG.CARD_HEIGHT
        for lineIdx = 1, maxCardHeight do
            local line = ""
            for i, card in ipairs(cardLines) do
                if card[lineIdx] then
                    line = line .. card[lineIdx]
                    -- 只有不是最后一个卡片才加间距
                    if i < #cardLines then
                        line = line .. "  "
                    end
                else
                    line = line .. string.rep(" ", CONFIG.CARD_WIDTH)
                    if i < #cardLines then
                        line = line .. "  "
                    end
                end
            end
            print(line)
        end
        print("")
    end
    
    print(ColorText(string.rep("─", 70), COLORS.BRIGHT_BLACK))
    print("")
    
    -- 显示右侧队伍
    print(ColorText("【下方队伍 - 右侧】", COLORS.BRIGHT_MAGENTA))
    print("")
    
    local cardsPerRow = 3
    for row = 1, math.ceil(#teamRight / cardsPerRow) do
        local heroes = {}
        for i = 1, cardsPerRow do
            local idx = (row - 1) * cardsPerRow + i
            if idx <= #teamRight then
                table.insert(heroes, teamRight[idx])
            end
        end
        
        local cardLines = {}
        for _, hero in ipairs(heroes) do
            table.insert(cardLines, ConsoleRenderer.ShowHeroCardFull(hero))
        end
        
        local maxCardHeight = CONFIG.CARD_HEIGHT
        for lineIdx = 1, maxCardHeight do
            local line = ""
            for i, card in ipairs(cardLines) do
                if card[lineIdx] then
                    line = line .. card[lineIdx]
                    if i < #cardLines then
                        line = line .. "  "
                    end
                else
                    line = line .. string.rep(" ", CONFIG.CARD_WIDTH)
                    if i < #cardLines then
                        line = line .. "  "
                    end
                end
            end
            print(line)
        end
        print("")
    end
end

--- 显示行动顺序
function ConsoleRenderer.ShowActionOrder()
    local BattleFormation = require("modules.battle_formation")
    local allHeroes = BattleFormation.GetAllAliveHeroes()
    
    -- 按行动力排序
    table.sort(allHeroes, function(a, b)
        return (a.actionForce or 0) > (b.actionForce or 0)
    end)
    
    print("")
    print(ColorText("【行动顺序】", COLORS.BRIGHT_WHITE))
    
    local orderStr = ""
    for i, hero in ipairs(allHeroes) do
        if i > 1 then
            orderStr = orderStr .. " → "
        end
        local shortName = hero.name and hero.name:sub(1, 3) or "???"
        orderStr = orderStr .. shortName
    end
    print(" " .. orderStr)
end

--- 刷新显示（合并 BattleDisplay.Refresh）
function ConsoleRenderer.Refresh()
    -- 显示战场
    ConsoleRenderer.ShowBattleFieldFull()
    
    -- 显示行动顺序
    ConsoleRenderer.ShowActionOrder()
end

return ConsoleRenderer
