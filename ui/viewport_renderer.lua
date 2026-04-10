---
--- Viewport Renderer Module
--- 固定视口渲染器，模拟 2D 游戏画面
--- 采用双缓冲和 ANSI 游标控制，实现无闪烁的固定画面刷新
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")
local BattleFormation = require("modules.battle_formation")
local BattleAttribute = require("modules.battle_attribute")
local BattleBuff = require("modules.battle_buff")

---@class ViewportRenderer
local ViewportRenderer = {}

-- ==================== 配置常量 ====================

local CONFIG = {
    SCREEN_WIDTH = 80,     -- 适配 80 列的标准/IDE终端
    SCREEN_HEIGHT = 26,   
    
    SCENE_HEIGHT = 16,     -- 场景高度
    HUD_HEIGHT = 10,       
    
    -- 阵型坐标基准点 (x, y)
    -- 按照 wpType 映射：1-3前排, 4-6后排
    -- 每行间隔 4 个单位（3行内容 + 1行空行）
    POS_LEFT_FRONT  = { [1] = {x = 28, y = 4}, [2] = {x = 28, y = 8}, [3] = {x = 28, y = 12} },
    POS_LEFT_BACK   = { [4] = {x = 12, y = 4}, [5] = {x = 12, y = 8}, [6] = {x = 12, y = 12} },
    
    POS_RIGHT_FRONT = { [1] = {x = 52, y = 4}, [2] = {x = 52, y = 8}, [3] = {x = 52, y = 12} },
    POS_RIGHT_BACK  = { [4] = {x = 68, y = 4}, [5] = {x = 68, y = 8}, [6] = {x = 68, y = 12} },
}

-- ANSI 颜色代码
local COLORS = {
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
    BRIGHT_CYAN = "\27[96m",
    BRIGHT_WHITE = "\27[97m",
    BRIGHT_BLACK = "\27[90m",
}

-- 职业图标映射 (Class 字段)
local JOB_ICONS = {
    [1] = "🛡", -- 职业1 (通常是坦克/战士)
    [2] = "⚔", -- 职业2 (通常是输出/刺客)
    [3] = "🏹", -- 职业3 (通常是射手/法师/辅助)
}

-- ==================== 状态缓存 ====================

local isInitialized = false
local frameBuffer = {}
local colorBuffer = {}
local fastMode = false

-- 战斗状态数据
local battleState = {
    round = 0,
    currentHero = nil,
    logs = {},
    maxLogs = 5,
    
    -- 视觉特效缓存
    effects = {
        -- heroId => { text, color, timer }
        floatingTexts = {},
        -- heroId => { color, timer }
        highlights = {}
    }
}

-- ==================== 工具函数 ====================

-- 计算字符串实际显示宽度（过滤ANSI和变体选择器）
local function GetDisplayWidth(str)
    if not str then return 0 end
    local cleanStr = str:gsub("\27%[[%d;]*%a", "")
    local width = 0
    local i = 1
    while i <= #cleanStr do
        local byte = cleanStr:byte(i)
        if byte == 0xEF and cleanStr:byte(i+1) == 0xB8 and (cleanStr:byte(i+2) == 0x8E or cleanStr:byte(i+2) == 0x8F) then
            i = i + 3
        elseif byte < 128 then
            width = width + 1; i = i + 1
        elseif byte >= 192 and byte < 224 then
            -- 2 字节 UTF-8：例如 ¦ (C2 A6) 等拉丁扩展符号，通常在终端占 1 宽度
            width = width + 1; i = i + 2
        elseif byte >= 224 and byte < 240 then
            -- 3 字节 UTF-8：
            -- 绝大多数中文字符占用 2 个单位。
            -- 特殊边框字符 (E2 95 ...) 、血条方块 (E2 96 ...) 以及一些符号 (E2 9A ..., E2 9B ...) 在终端中通常只占 1 个单位。
            if byte == 0xE2 and (cleanStr:byte(i+1) == 0x95 or cleanStr:byte(i+1) == 0x96 or cleanStr:byte(i+1) == 0x9A or cleanStr:byte(i+1) == 0x9B) then
                width = width + 1
            else
                width = width + 2
            end
            i = i + 3
        elseif byte >= 240 then
            -- Emoji 通常占 2 个宽度
            width = width + 2; i = i + 4
        else
            i = i + 1
        end
    end
    return width
end

-- ==================== Buffer 渲染 API ====================

--- 清空缓冲区
local function ClearBuffer()
    for y = 1, CONFIG.SCREEN_HEIGHT do
        frameBuffer[y] = {}
        colorBuffer[y] = {}
        for x = 1, CONFIG.SCREEN_WIDTH do
            frameBuffer[y][x] = " "
            colorBuffer[y][x] = COLORS.RESET
        end
    end
end

--- 在指定位置写入字符串（处理宽字符和0宽字符）
local function DrawString(x, y, str, color)
    if not str or str == "" then return end
    x = math.floor(x)
    y = math.floor(y)
    
    if y < 1 or y > CONFIG.SCREEN_HEIGHT or x < 1 or x > CONFIG.SCREEN_WIDTH then return end
    
    color = color or COLORS.RESET
    
    local currentX = x
    local i = 1
    while i <= #str do
        local byte = str:byte(i)
        local charLen = 1
        if byte >= 240 then charLen = 4
        elseif byte >= 224 then charLen = 3
        elseif byte >= 192 then charLen = 2
        end
        
        local char = str:sub(i, i + charLen - 1)
        
        -- 特殊处理：UTF-8 变体选择器 (U+FE0E, U+FE0F) 是 0 宽度的
        local isZeroWidth = false
        if byte == 0xEF and str:byte(i+1) == 0xB8 and (str:byte(i+2) == 0x8E or str:byte(i+2) == 0x8F) then
            isZeroWidth = true
        end
        
        if isZeroWidth then
            -- 如果是 0 宽度字符，尝试将其追加到前一个字符位置（如果前一个位置有东西的话）
            -- 但在 buffer 模式下，最简单的做法是直接忽略它，因为它是用来控制 emoji 样式的
            i = i + charLen
        else
            local w = GetDisplayWidth(char)
            if currentX <= CONFIG.SCREEN_WIDTH then
                frameBuffer[y][currentX] = char
                colorBuffer[y][currentX] = color
                
                if w > 1 then
                    for j = 1, w - 1 do
                        if currentX + j <= CONFIG.SCREEN_WIDTH then
                            frameBuffer[y][currentX + j] = false
                            colorBuffer[y][currentX + j] = ""
                        end
                    end
                end
                currentX = currentX + w
            end
            i = i + charLen
        end
    end
end

--- 绘制方框
local function DrawBox(x, y, w, h, color)
    color = color or COLORS.RESET
    -- 顶边和底边
    local horizontalLine = string.rep("═", math.floor((w - 2) / 2))
    DrawString(x, y, "╔" .. horizontalLine .. string.rep("═", (w-2) % 2) .. horizontalLine .. "╗", color)
    DrawString(x, y + h - 1, "╚" .. horizontalLine .. string.rep("═", (w-2) % 2) .. horizontalLine .. "╝", color)
    
    -- 左边和右边
    for i = 1, h - 2 do
        DrawString(x, y + i, "║", color)
        DrawString(x + w - 1, y + i, "║", color) -- 修正：右边框应该在 x + w - 1 位置
    end
end

--- 绘制迷你血条 [██░░]
local function DrawMiniBar(x, y, cur, max, width, color)
    local percent = max > 0 and (cur / max) or 0
    local fillCount = math.floor(percent * width)
    
    local bar = "["
    for i = 1, width do
        if i <= fillCount then
            bar = bar .. "█"
        else
            bar = bar .. "░"
        end
    end
    bar = bar .. "]"
    
    DrawString(x, y, bar, color)
end

--- 将 Buffer 输出到终端
local function RenderToTerminal()
    -- 1. 清屏并移动游标到左上角
    -- 在 Windows 下用 cls, Unix 下用 clear，这是最彻底的清屏方式
    if package.config:sub(1,1) == "\\" then
        os.execute("cls")
    else
        os.execute("clear")
    end
    
    local output = {}
    for y = 1, CONFIG.SCREEN_HEIGHT do
        local line = ""
        local lastColor = ""
        for x = 1, CONFIG.SCREEN_WIDTH do
            local char = frameBuffer[y][x]
            local color = colorBuffer[y][x]
            
            if char ~= false then -- 不是占位符
                if color ~= lastColor and color ~= "" then
                    line = line .. color
                    lastColor = color
                end
                line = line .. (char or " ")
            end
        end
        line = line .. COLORS.RESET .. "\n"
        table.insert(output, line)
    end
    
    io.write(table.concat(output))
    io.flush()
end

-- ==================== 场景绘制逻辑 ====================

--- 绘制单个角色的场景实体
local function DrawHeroEntity(hero, baseX, baseY)
    if not hero then return end
    
    local isDead = hero.isDead or not hero.isAlive
    local teamColor = hero.isLeft and COLORS.BRIGHT_CYAN or COLORS.BRIGHT_MAGENTA
    if isDead then teamColor = COLORS.BRIGHT_BLACK end
    
    local heroId = hero.instanceId or hero.id
    
    -- 1. 检查是否为当前行动者 (变黄)
    if not isDead and battleState.currentHero and (battleState.currentHero.instanceId or battleState.currentHero.id) == heroId then
        teamColor = COLORS.BRIGHT_YELLOW
    end
    
    -- 检查高亮特效 (比如受到伤害时的闪烁)
    local hl = battleState.effects.highlights[heroId]
    if hl and hl.timer > 0 then
        teamColor = hl.color
        hl.timer = hl.timer - 1
    end
    
    -- 绘制名字
    local jobIcon = JOB_ICONS[hero.class] or JOB_ICONS[hero.job] or "⚔️"
    local nameStr = jobIcon .. " " .. (hero.name or "Unknown")
    local nameWidth = GetDisplayWidth(nameStr)
    DrawString(baseX - math.floor(nameWidth / 2), baseY, nameStr, teamColor)
    
    -- 绘制血条 (宽 10)
    local curHp = BattleAttribute.GetHeroCurHp(hero) or 0
    local maxHp = BattleAttribute.GetHeroMaxHp(hero) or 1
    DrawMiniBar(baseX - 6, baseY + 1, curHp, maxHp, 10, isDead and COLORS.BRIGHT_BLACK or COLORS.GREEN)
    
    -- 绘制能量条 (宽 10)
    local curEnergy = hero.curEnergy or 0
    local maxEnergy = hero.maxEnergy or 100
    DrawMiniBar(baseX - 6, baseY + 2, curEnergy, maxEnergy, 10, isDead and COLORS.BRIGHT_BLACK or COLORS.YELLOW)
    
    -- 绘制伤害数字 (覆盖在血条所在行，居中显示)
    local ft = battleState.effects.floatingTexts[heroId]
    if ft and ft.timer > 0 then
        local textWidth = GetDisplayWidth(ft.text)
        -- 直接在血条那一行 (baseY + 1) 绘制，不进行 Y 轴偏移
        DrawString(baseX - math.floor(textWidth / 2), baseY + 1, ft.text, ft.color)
        ft.timer = ft.timer - 1
    end
end

--- 绘制战斗场景（上半部分）
local function DrawScene()
    -- 获取队伍数据
    local teamLeft = BattleFormation.teamLeft or {}
    local teamRight = BattleFormation.teamRight or {}
    
    -- 场景外框
    DrawBox(1, 1, CONFIG.SCREEN_WIDTH, CONFIG.SCENE_HEIGHT, COLORS.BRIGHT_WHITE)
    
    -- 标题
    local title = string.format(" BATTLE ROUND %d ", battleState.round)
    DrawString(math.floor(CONFIG.SCREEN_WIDTH / 2 - GetDisplayWidth(title) / 2), 1, title, COLORS.BRIGHT_YELLOW)
    
    -- 阵营提示
    DrawString(10, 2, string.format("【我方阵营】(%d)", #teamLeft), COLORS.BRIGHT_CYAN)
    DrawString(CONFIG.SCREEN_WIDTH - 30, 2, string.format("【敌方阵营】(%d)", #teamRight), COLORS.BRIGHT_MAGENTA)
    
    -- 绘制中场分割线
    for y = 2, CONFIG.SCENE_HEIGHT - 1 do
        DrawString(math.floor(CONFIG.SCREEN_WIDTH / 2), y, "¦", COLORS.BRIGHT_BLACK)
    end
    
    -- 绘制左方队伍
    for i, hero in ipairs(teamLeft) do
        local wpType = hero.wpType or i
        if wpType == 0 then wpType = i end
        
        local coord
        if wpType <= 3 then
            coord = CONFIG.POS_LEFT_FRONT[wpType]
        else
            coord = CONFIG.POS_LEFT_BACK[wpType]
        end
        
        if coord then
            DrawHeroEntity(hero, coord.x, coord.y)
        end
    end
    
    -- 绘制右方队伍
    for i, hero in ipairs(teamRight) do
        local wpType = hero.wpType or i
        if wpType == 0 then wpType = i end
        
        local coord
        if wpType <= 3 then
            coord = CONFIG.POS_RIGHT_FRONT[wpType]
        else
            coord = CONFIG.POS_RIGHT_BACK[wpType]
        end
        
        if coord then
            DrawHeroEntity(hero, coord.x, coord.y)
        end
    end
end

-- ==================== HUD 绘制逻辑 ====================

--- 添加日志
local function AddLog(msg, color)
    table.insert(battleState.logs, 1, {text = msg, color = color or COLORS.WHITE})
    if #battleState.logs > battleState.maxLogs then
        table.remove(battleState.logs)
    end
end

--- 绘制当前行动角色详情面板
local function DrawCurrentHeroPanel(hero, x, y, w, h)
    DrawBox(x, y, w, h, COLORS.BRIGHT_WHITE)
    DrawString(x + 2, y, " 当前行动 ", COLORS.BRIGHT_YELLOW)
    
    if not hero then
        DrawString(x + 2, y + 2, "等待中...", COLORS.BRIGHT_BLACK)
        return
    end
    
    local teamColor = hero.isLeft and COLORS.BRIGHT_CYAN or COLORS.BRIGHT_MAGENTA
    local jobIcon = JOB_ICONS[hero.job] or JOB_ICONS[hero.profession] or "⚔️"
    
    DrawString(x + 2, y + 2, string.format("角色: %s %s", jobIcon, hero.name), teamColor)
    
    local curHp = BattleAttribute.GetHeroCurHp(hero) or 0
    local maxHp = BattleAttribute.GetHeroMaxHp(hero) or 1
    DrawString(x + 2, y + 3, string.format("HP:   %d / %d", curHp, maxHp), COLORS.GREEN)
    
    local curEnergy = hero.curEnergy or 0
    local maxEnergy = hero.maxEnergy or 100
    DrawString(x + 2, y + 4, string.format("ENG:  %d / %d", curEnergy, maxEnergy), COLORS.YELLOW)
    
    -- 绘制 Buff
    local buffStr = "Buff: "
    local buffs = BattleBuff.GetAllBuffs and BattleBuff.GetAllBuffs(hero) or nil
    if buffs and #buffs > 0 then
        local show = {}
        local maxShow = 4
        for i = 1, math.min(#buffs, maxShow) do
            local b = buffs[i]
            local name = b and b.name or "未知"
            local stack = (b and b.stackCount) and (b.stackCount > 1 and ("x" .. b.stackCount) or "") or ""
            table.insert(show, string.format("[%s%s]", name, stack))
        end
        buffStr = buffStr .. table.concat(show, " ")
    else
        buffStr = buffStr .. "无"
    end
    DrawString(x + 2, y + 5, buffStr, COLORS.BRIGHT_BLUE)
end

--- 绘制战斗日志面板
local function DrawLogPanel(x, y, w, h)
    DrawBox(x, y, w, h, COLORS.BRIGHT_WHITE)
    DrawString(x + 2, y, " 战斗记录 ", COLORS.BRIGHT_YELLOW)
    
    for i = 1, #battleState.logs do
        local log = battleState.logs[i]
        -- 从下往上画
        DrawString(x + 2, y + h - 1 - i, "> " .. log.text, log.color)
    end
end

--- 绘制 HUD（下半部分）
local function DrawHUD()
    local hudY = CONFIG.SCENE_HEIGHT + 1
    
    -- 左侧：当前角色详情 (占 1/3 宽度)
    local panelW = math.floor(CONFIG.SCREEN_WIDTH / 3)
    DrawCurrentHeroPanel(battleState.currentHero, 1, hudY, panelW, CONFIG.HUD_HEIGHT)
    
    -- 右侧：战斗日志 (占 2/3 宽度)
    DrawLogPanel(panelW + 1, hudY, CONFIG.SCREEN_WIDTH - panelW, CONFIG.HUD_HEIGHT)
end

-- ==================== 核心刷新逻辑 ====================

--- 触发一帧渲染
function ViewportRenderer.RenderFrame()
    if fastMode then
        return
    end
    ClearBuffer()
    DrawScene()
    DrawHUD()
    RenderToTerminal()
end

--- 播放动画等待（阻塞主逻辑的替代方案：实际在协程或Update中运行）
--- 纯Lua环境下，我们通过简单的空循环或os.execute来实现停顿
local function Wait(seconds)
    if fastMode then
        return
    end
    if not seconds or seconds <= 0 then
        return
    end
    local ms = math.floor(seconds * 1000)
    if ms <= 0 then
        return
    end
    if package.config:sub(1, 1) == "\\" then
        os.execute(string.format("powershell -NoProfile -Command \"Start-Sleep -Milliseconds %d\" >nul 2>&1", ms))
    else
        os.execute(string.format("sleep %.3f", seconds))
    end
end

--- 播放一个视觉特效帧序列
local function PlayVisualEffect(frames)
    if fastMode then
        return
    end
    for i = 1, frames do
        ViewportRenderer.RenderFrame()
        Wait(0.1) -- 约 10fps 的动画速度
    end
end

-- ==================== 事件处理器 ====================

function ViewportRenderer.OnBattleStarted(data)
    if fastMode then
        return
    end
    battleState.round = 0
    battleState.logs = {}
    battleState.effects.floatingTexts = {}
    battleState.effects.highlights = {}
    
    -- 清空屏幕，为固定视口做准备
    if package.config:sub(1,1) == "\\" then
        os.execute("cls")
    else
        os.execute("clear")
    end
    
    AddLog("战斗开始！", COLORS.BRIGHT_YELLOW)
    ViewportRenderer.RenderFrame()
end

function ViewportRenderer.OnTurnStarted(data)
    battleState.round = data.round
    battleState.currentHero = data.hero
    
    -- 清理过期的特效
    battleState.effects.floatingTexts = {}
    battleState.effects.highlights = {}
    
    AddLog(string.format("【回合 %d】 %s 的回合", data.round, data.heroName), COLORS.BRIGHT_WHITE)
    
    -- 高亮当前行动角色 (变黄)
    local heroId = data.hero and (data.hero.instanceId or data.hero.id)
    if heroId then
        battleState.effects.highlights[heroId] = { color = COLORS.BRIGHT_YELLOW, timer = 10 }
    end
    
    PlayVisualEffect(3) -- 播几帧动画让人看清是谁的回合
end

function ViewportRenderer.OnSkillCastStarted(data)
    local msg = string.format("%s 使用了 【%s】", data.heroName, data.skillName)
    AddLog(msg, COLORS.BRIGHT_CYAN)
    
    local heroId = data.heroId
    if heroId then
        battleState.effects.highlights[heroId] = { color = COLORS.BRIGHT_YELLOW, timer = 5 }
    end
    
    PlayVisualEffect(3)
end

function ViewportRenderer.OnDamageDealt(data)
    local heroId = data.targetId
    if not heroId then return end
    
    local isCrit = data.isCrit
    local dmgVal = data.damage
    
    local msg = string.format("%s 对 %s 造成 %d 伤害%s", 
        data.attackerName or "未知", data.targetName, dmgVal, isCrit and " (暴击!)" or "")
    AddLog(msg, isCrit and COLORS.BRIGHT_RED or COLORS.RED)
    
    -- 设置受击高亮
    battleState.effects.highlights[heroId] = { color = COLORS.BRIGHT_RED, timer = 5 }
    
    -- 设置伤害飘字
    local floatColor = isCrit and (COLORS.BRIGHT_RED .. COLORS.BOLD) or COLORS.RED
    battleState.effects.floatingTexts[heroId] = { 
        text = "-" .. dmgVal, 
        color = floatColor, 
        timer = 5 -- 持续5帧
    }
    
    PlayVisualEffect(5) -- 播放受伤动画
end

function ViewportRenderer.OnHealReceived(data)
    local heroId = data.targetId
    if not heroId then return end
    
    local msg = string.format("%s 恢复了 %d 点生命", data.targetName, data.healAmount)
    AddLog(msg, COLORS.BRIGHT_GREEN)
    
    -- 设置治疗高亮和飘字
    battleState.effects.highlights[heroId] = { color = COLORS.BRIGHT_GREEN, timer = 5 }
    battleState.effects.floatingTexts[heroId] = { 
        text = "+" .. data.healAmount, 
        color = COLORS.BRIGHT_GREEN, 
        timer = 5 
    }
    
    PlayVisualEffect(5)
end

function ViewportRenderer.OnHeroDied(data)
    AddLog(string.format("%s 阵亡了！", data.heroName), COLORS.BRIGHT_BLACK)
    ViewportRenderer.RenderFrame()
end

function ViewportRenderer.OnBattleEnded(data)
    AddLog("战斗结束！获胜方: " .. tostring(data.winner), COLORS.BRIGHT_YELLOW)
    ViewportRenderer.RenderFrame()
end

--- 被动技能触发
function ViewportRenderer.OnPassiveSkillTriggered(data)
    local msg = string.format("【被动】%s 触发 %s (%s)", 
        data.heroName or "未知", 
        data.skillName or "未知技能",
        data.triggerType or "")
    if data.extraInfo and data.extraInfo ~= "" then
        msg = msg .. " " .. data.extraInfo
    end
    AddLog(msg, COLORS.BRIGHT_MAGENTA)
    ViewportRenderer.RenderFrame()
end

-- ==================== 生命周期 ====================

function ViewportRenderer.Init()
    if isInitialized then return end
    
    BattleEvent.AddListener(BattleVisualEvents.BATTLE_STARTED, ViewportRenderer.OnBattleStarted)
    BattleEvent.AddListener(BattleVisualEvents.TURN_STARTED, ViewportRenderer.OnTurnStarted)
    BattleEvent.AddListener(BattleVisualEvents.SKILL_CAST_STARTED, ViewportRenderer.OnSkillCastStarted)
    BattleEvent.AddListener(BattleVisualEvents.DAMAGE_DEALT, ViewportRenderer.OnDamageDealt)
    BattleEvent.AddListener(BattleVisualEvents.HEAL_RECEIVED, ViewportRenderer.OnHealReceived)
    BattleEvent.AddListener(BattleVisualEvents.HERO_DIED, ViewportRenderer.OnHeroDied)
    BattleEvent.AddListener(BattleVisualEvents.BATTLE_ENDED, ViewportRenderer.OnBattleEnded)
    -- 监听被动技能触发事件
    BattleEvent.AddListener("PassiveSkillTriggered", ViewportRenderer.OnPassiveSkillTriggered)
    
    isInitialized = true
    Logger.Log("[ViewportRenderer] 初始化完成")
end

function ViewportRenderer.SetFastMode(enabled)
    fastMode = enabled == true
end

return ViewportRenderer
