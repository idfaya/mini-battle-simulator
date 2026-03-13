local BattleMenu = {}

-- 键盘按键码
local KEY_UP = 72
local KEY_DOWN = 80
local KEY_ENTER = 13
local KEY_ESC = 27
local KEY_1 = 49
local KEY_9 = 57

-- 清屏函数
local function ClearScreen()
    os.execute("cls")
end

-- 打印分隔线
local function PrintSeparator(char, length)
    char = char or "-"
    length = length or 50
    print(string.rep(char, length))
end

-- 打印标题
local function PrintTitle(title)
    PrintSeparator("=", 50)
    print(string.format("  %s", title))
    PrintSeparator("=", 50)
end

-- 读取键盘输入
local function ReadKey()
    if package.loaded["lua_windows"] then
        return lua_windows.getch()
    else
        io.write("请输入选项: ")
        local input = io.read()
        if input == "" then return KEY_ENTER end
        local num = tonumber(input)
        if num and num >= 1 and num <= 9 then
            return KEY_1 + num - 1
        end
        return input:byte(1) or KEY_ENTER
    end
end

-- 显示菜单通用函数
local function ShowMenu(title, options, allowCancel)
    local selectedIndex = 1
    local totalOptions = #options
    
    while true do
        ClearScreen()
        PrintTitle(title)
        print()
        
        for i, option in ipairs(options) do
            if i == selectedIndex then
                print(string.format("  > [%d] %s", i, option))
            else
                print(string.format("    [%d] %s", i, option))
            end
        end
        
        print()
        PrintSeparator("-", 50)
        if allowCancel ~= false then
            print("  使用 ↑↓ 或数字键选择, Enter 确认, ESC 取消")
        else
            print("  使用 ↑↓ 或数字键选择, Enter 确认")
        end
        
        local key = ReadKey()
        
        if key == KEY_UP then
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then selectedIndex = totalOptions end
        elseif key == KEY_DOWN then
            selectedIndex = selectedIndex + 1
            if selectedIndex > totalOptions then selectedIndex = 1 end
        elseif key == KEY_ENTER then
            return selectedIndex, options[selectedIndex]
        elseif key == KEY_ESC and allowCancel ~= false then
            return nil, nil
        elseif key >= KEY_1 and key <= KEY_9 then
            local num = key - KEY_1 + 1
            if num <= totalOptions then
                return num, options[num]
            end
        end
    end
end

-- 显示主菜单
function BattleMenu.ShowMainMenu()
    local options = {
        "开始新战斗",
        "加载配置",
        "查看英雄",
        "设置",
        "退出"
    }
    
    return ShowMenu("战斗模拟器 - 主菜单", options, false)
end

-- 显示战斗中菜单
function BattleMenu.ShowBattleMenu()
    local options = {
        "释放技能",
        "切换自动/手动模式",
        "暂停/继续",
        "查看统计",
        "退出战斗"
    }
    
    return ShowMenu("战斗菜单", options)
end

-- 显示英雄选择列表
function BattleMenu.ShowHeroSelection(heroes)
    if not heroes or #heroes == 0 then
        print("没有可用的英雄")
        BattleMenu.WaitForKey()
        return nil
    end
    
    local options = {}
    for i, hero in ipairs(heroes) do
        local heroInfo = string.format("%s (Lv.%d) - %s", 
            hero.name or "未知", 
            hero.level or 1, 
            hero.class or "未知职业")
        table.insert(options, heroInfo)
    end
    
    local index, value = ShowMenu("选择英雄", options)
    if index then
        return heroes[index]
    end
    return nil
end

-- 显示技能选择列表
function BattleMenu.ShowSkillSelection(skills)
    if not skills or #skills == 0 then
        print("没有可用的技能")
        BattleMenu.WaitForKey()
        return nil
    end
    
    local options = {}
    for i, skill in ipairs(skills) do
        local skillInfo = string.format("%s - %s (消耗: %d)", 
            skill.name or "未知技能",
            skill.description or "无描述",
            skill.cost or 0)
        table.insert(options, skillInfo)
    end
    
    local index, value = ShowMenu("选择技能", options)
    if index then
        return skills[index]
    end
    return nil
end

-- 显示目标选择
function BattleMenu.ShowTargetSelection(targets)
    if not targets or #targets == 0 then
        print("没有可选目标")
        BattleMenu.WaitForKey()
        return nil
    end
    
    local options = {}
    for i, target in ipairs(targets) do
        local targetInfo = string.format("[%d] %s - HP: %d/%d %s",
            i,
            target.name or "未知",
            target.hp or 0,
            target.maxHp or 0,
            target.isDead and "[已阵亡]" or "")
        table.insert(options, targetInfo)
    end
    
    local index, value = ShowMenu("选择目标", options)
    if index then
        return targets[index]
    end
    return nil
end

-- 显示确认对话框
function BattleMenu.ShowConfirmation(message)
    ClearScreen()
    PrintTitle("确认")
    print()
    print("  " .. (message or "确定要执行此操作吗？"))
    print()
    PrintSeparator("-", 50)
    print("  [Y] 是    [N] 否")
    
    while true do
        local key = ReadKey()
        if key == 89 or key == 121 then -- 'Y' or 'y'
            return true
        elseif key == 78 or key == 110 then -- 'N' or 'n'
            return false
        elseif key == KEY_ENTER then
            return true
        elseif key == KEY_ESC then
            return false
        end
    end
end

-- 显示输入提示
function BattleMenu.ShowInputPrompt(prompt, defaultValue)
    ClearScreen()
    PrintTitle("输入")
    print()
    print("  " .. (prompt or "请输入:"))
    if defaultValue then
        print(string.format("  (默认: %s)", tostring(defaultValue)))
    end
    print()
    io.write("  > ")
    
    local input = io.read()
    if input == "" and defaultValue ~= nil then
        return defaultValue
    end
    return input
end

-- 等待任意按键
function BattleMenu.WaitForKey(message)
    print()
    print(message or "按任意键继续...")
    ReadKey()
end

-- 显示消息框
function BattleMenu.ShowMessage(message, title)
    ClearScreen()
    PrintTitle(title or "消息")
    print()
    if type(message) == "table" then
        for _, line in ipairs(message) do
            print("  " .. tostring(line))
        end
    else
        print("  " .. tostring(message))
    end
    print()
    BattleMenu.WaitForKey()
end

-- 显示进度条
function BattleMenu.ShowProgress(current, total, prefix)
    prefix = prefix or "进度"
    local percentage = math.floor((current / total) * 100)
    local filled = math.floor((current / total) * 30)
    local empty = 30 - filled
    local bar = string.rep("█", filled) .. string.rep("░", empty)
    io.write(string.format("\r  %s: [%s] %d%% (%d/%d)", prefix, bar, percentage, current, total))
    if current >= total then
        print()
    end
end

return BattleMenu
