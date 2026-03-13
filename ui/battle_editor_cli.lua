---
--- Battle Editor CLI Module
--- 战斗编辑器命令行界面模块
--- 提供交互式战斗编辑和调试功能
---

local Logger = require("utils.logger")
local BattleDisplay = require("ui.battle_display")
local BattleMenu = require("ui.battle_menu")
local BattleMain = require("modules.battle_main")
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleAttribute = require("modules.battle_attribute")
local BattleBuff = require("modules.battle_buff")
local BattleActionOrder = require("modules.battle_action_order")
local SkillLoader = require("core.skill_loader")

---@class BattleEditorCLI
local BattleEditorCLI = {}

-- ==================== 状态变量 ====================

-- 是否处于自动模式
local isAutoMode = true

-- 战斗循环是否运行中
local isBattleLoopRunning = false

-- 战斗循环协程/线程
local battleLoopThread = nil

-- 当前选中的英雄 (用于技能释放)
local selectedHero = nil

-- 更新间隔（秒）
local UPDATE_INTERVAL = 0.5

-- ==================== 核心功能 ====================

--- 启动编辑器并开始新战斗
---@param config table 战斗配置，包含 teamLeft, teamRight, seedArray 等
function BattleEditorCLI.StartEditor(config)
    config = config or {}

    print("")
    BattleDisplay.ShowTitle("⚔ Battle Editor - 战斗编辑器 ⚔")
    print("")

    -- 停止之前的战斗（如果有）
    if BattleMain.IsRunning() then
        BattleMain.Quit()
    end

    -- 重置状态
    isAutoMode = true
    isBattleLoopRunning = false
    selectedHero = nil

    -- 启动战斗
    BattleMain.Start(config, function(result)
        BattleEditorCLI.OnBattleEnd(result)
    end)

    -- 清屏并显示初始状态
    BattleDisplay.ClearScreen()
    BattleDisplay.Refresh()

    Logger.Log("[BattleEditorCLI] 编辑器已启动，战斗开始")
    BattleDisplay.ShowMessage("战斗编辑器已启动！当前模式: 自动", "success")

    return true
end

--- 手动释放技能
---@param camp number 阵营 (E_CAMP_TYPE.A 或 E_CAMP_TYPE.B)
---@param wpType number 位置类型
---@param skillId number 技能ID
---@param targetIds table 目标实例ID列表 (可选)
---@return boolean 是否释放成功
function BattleEditorCLI.DoSkill(camp, wpType, skillId, targetIds)
    if not BattleMain.IsRunning() then
        BattleDisplay.ShowMessage("战斗未运行！", "error")
        return false
    end

    local isLeft = (camp == E_CAMP_TYPE.A)
    local hero = BattleFormation.FindHeroByCampAndPos(isLeft, wpType)

    if not hero then
        BattleDisplay.ShowMessage(string.format("未找到英雄: camp=%d, wpType=%d", camp, wpType), "error")
        return false
    end

    if not hero.isAlive or hero.isDead then
        BattleDisplay.ShowMessage(string.format("英雄 %s 已阵亡，无法释放技能", hero.name), "warning")
        return false
    end

    -- 检查技能是否存在
    local skill = hero.skillData and hero.skillData.skillInstances and hero.skillData.skillInstances[skillId]
    if not skill then
        BattleDisplay.ShowMessage(string.format("英雄 %s 没有技能 %d", hero.name, skillId), "error")
        return false
    end

    -- 检查冷却
    if BattleSkill.IsSkillInCoolDown(hero, skillId) then
        local cd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
        BattleDisplay.ShowMessage(string.format("技能 %s 冷却中，剩余 %d 回合", skill.name, cd), "warning")
        return false
    end

    -- 如果没有指定目标，自动选择
    if not targetIds or #targetIds == 0 then
        local targetId = BattleFormation.GetRandomEnemyInstanceId(hero)
        if targetId then
            targetIds = {targetId}
        end
    end

    -- 释放技能
    local success = BattleSkill.CastSkill(hero, skillId, targetIds)

    if success then
        local targetNames = ""
        if targetIds then
            for i, targetId in ipairs(targetIds) do
                local target = BattleFormation.FindHeroByInstanceId(targetId)
                if target then
                    targetNames = targetNames .. (i > 1 and ", " or "") .. target.name
                end
            end
        end

        BattleDisplay.AddBattleLog(string.format("%s 对 %s 使用技能 %s", hero.name, targetNames ~= "" and targetNames or "无目标", skill.name))
        BattleDisplay.ShowMessage(string.format("技能释放成功: %s -> %s", skill.name, targetNames ~= "" and targetNames or "无目标"), "success")

        -- 刷新显示
        BattleDisplay.Refresh()
    else
        BattleDisplay.ShowMessage("技能释放失败！", "error")
    end

    return success
end

--- 切换自动/手动模式
---@param isAuto boolean 是否自动模式 (nil则切换)
---@return boolean 当前是否为自动模式
function BattleEditorCLI.DoAuto(isAuto)
    if isAuto == nil then
        isAutoMode = not isAutoMode
    else
        isAutoMode = isAuto
    end

    local modeText = isAutoMode and "自动" or "手动"
    BattleDisplay.ShowMessage(string.format("已切换到%s模式", modeText), "info")
    Logger.Log(string.format("[BattleEditorCLI] 模式切换为: %s", modeText))

    return isAutoMode
end

-- ==================== 查询功能 ====================

--- 获取英雄属性表格
---@param camp number 阵营 (E_CAMP_TYPE.A 或 E_CAMP_TYPE.B)
---@param wpType number 位置类型
---@return table 格式化的属性表格
function BattleEditorCLI.GetHeroAttrTable(camp, wpType)
    local isLeft = (camp == E_CAMP_TYPE.A)
    local hero = BattleFormation.FindHeroByCampAndPos(isLeft, wpType)

    if not hero then
        return nil, string.format("未找到英雄: camp=%d, wpType=%d", camp, wpType)
    end

    local attrTable = {
        title = string.format("【%s】属性详情", hero.name),
        headers = {"属性", "数值", "说明"},
        rows = {},
    }

    -- 基础属性
    table.insert(attrTable.rows, {"名称", hero.name, "英雄名称"})
    table.insert(attrTable.rows, {"等级", hero.level or 1, "当前等级"})
    table.insert(attrTable.rows, {"阵营", isLeft and "左侧(A)" or "右侧(B)", "所属阵营"})
    table.insert(attrTable.rows, {"位置", hero.wpType or 0, "战场位置"})
    table.insert(attrTable.rows, {"状态", hero.isAlive and "存活" or "阵亡", "生存状态"})

    -- 生命属性
    table.insert(attrTable.rows, {"---", "---", "---"})
    table.insert(attrTable.rows, {"当前HP", hero.hp or 0, "当前生命值"})
    table.insert(attrTable.rows, {"最大HP", hero.maxHp or 0, "最大生命值"})
    table.insert(attrTable.rows, {"HP百分比", string.format("%.1f%%", (hero.hp or 0) / (hero.maxHp or 1) * 100), "生命百分比"})

    -- 战斗属性
    table.insert(attrTable.rows, {"---", "---", "---"})
    table.insert(attrTable.rows, {"攻击力", hero.atk or 0, "基础攻击力"})
    table.insert(attrTable.rows, {"防御力", hero.def or 0, "基础防御力"})
    table.insert(attrTable.rows, {"速度", hero.speed or 0, "行动速度"})

    -- 高级属性
    table.insert(attrTable.rows, {"---", "---", "---"})
    table.insert(attrTable.rows, {"暴击率", string.format("%.1f%%", (hero.critRate or 0)), "暴击概率"})
    table.insert(attrTable.rows, {"暴击伤害", string.format("%.1f%%", (hero.critDamage or 150)), "暴击伤害倍率"})
    table.insert(attrTable.rows, {"命中率", string.format("%.1f%%", (hero.hitRate or 100)), "命中概率"})
    table.insert(attrTable.rows, {"闪避率", string.format("%.1f%%", (hero.dodgeRate or 0)), "闪避概率"})
    table.insert(attrTable.rows, {"伤害减免", string.format("%.1f%%", (hero.damageReduce or 0)), "受到伤害减免"})
    table.insert(attrTable.rows, {"伤害增加", string.format("%.1f%%", (hero.damageIncrease or 0)), "造成伤害增加"})

    -- 能量属性
    table.insert(attrTable.rows, {"---", "---", "---"})
    table.insert(attrTable.rows, {"能量类型", hero.energyType == E_ENERGY_TYPE.Point and "点数" or "能量条", "能量计算方式"})
    table.insert(attrTable.rows, {"当前能量", hero.energy or 0, "当前能量值"})
    table.insert(attrTable.rows, {"最大能量", hero.maxEnergy or 100, "最大能量值"})

    -- 战斗状态
    table.insert(attrTable.rows, {"---", "---", "---"})
    table.insert(attrTable.rows, {"行动力", string.format("%.1f", hero.actionForce or 0), "当前行动力"})
    table.insert(attrTable.rows, {"实例ID", hero.instanceId or 0, "唯一实例标识"})
    table.insert(attrTable.rows, {"配置ID", hero.configId or 0, "英雄配置ID"})

    return attrTable
end

--- 获取英雄技能列表
---@param camp number 阵营 (E_CAMP_TYPE.A 或 E_CAMP_TYPE.B)
---@param wpType number 位置类型
---@return table 技能列表
function BattleEditorCLI.GetHeroSkillList(camp, wpType)
    local isLeft = (camp == E_CAMP_TYPE.A)
    local hero = BattleFormation.FindHeroByCampAndPos(isLeft, wpType)

    if not hero then
        return nil, string.format("未找到英雄: camp=%d, wpType=%d", camp, wpType)
    end

    local skillList = {
        title = string.format("【%s】技能列表", hero.name),
        hero = hero,
        skills = {},
    }

    if not hero.skills or #hero.skills == 0 then
        return skillList
    end

    for _, skill in ipairs(hero.skills) do
        local skillInfo = {
            skillId = skill.skillId,
            name = skill.name or "未知技能",
            skillType = skill.skillType,
            typeName = BattleEditorCLI.GetSkillTypeName(skill.skillType),
            level = skill.level or 1,
            coolDown = skill.coolDown or 0,
            maxCoolDown = skill.maxCoolDown or 0,
            isReady = (skill.coolDown or 0) == 0,
            castTarget = skill.castTarget,
            targetName = BattleEditorCLI.GetCastTargetName(skill.castTarget),
            description = skill.config and skill.config.description or "暂无描述",
        }
        table.insert(skillList.skills, skillInfo)
    end

    return skillList
end

--- 热重载技能
---@param camp number 阵营 (E_CAMP_TYPE.A 或 E_CAMP_TYPE.B)
---@param wpType number 位置类型
---@param skillId number 技能ID (可选，nil则重载所有技能)
---@return boolean 是否重载成功
function BattleEditorCLI.DoSkillReload(camp, wpType, skillId)
    local isLeft = (camp == E_CAMP_TYPE.A)
    local hero = BattleFormation.FindHeroByCampAndPos(isLeft, wpType)

    if not hero then
        BattleDisplay.ShowMessage(string.format("未找到英雄: camp=%d, wpType=%d", camp, wpType), "error")
        return false
    end

    -- 清除技能Lua缓存
    if skillId then
        BattleSkill.skillLuaCache[skillId] = nil
        BattleDisplay.ShowMessage(string.format("技能 %d 缓存已清除，下次释放时将重新加载", skillId), "success")
    else
        -- 清除所有技能缓存
        for id, _ in pairs(BattleSkill.skillLuaCache) do
            BattleSkill.skillLuaCache[id] = nil
        end
        BattleDisplay.ShowMessage("所有技能缓存已清除", "success")
    end

    Logger.Log(string.format("[BattleEditorCLI] 技能重载: hero=%s, skillId=%s", hero.name, tostring(skillId)))
    return true
end

-- ==================== 战斗循环控制 ====================

--- 运行战斗主循环（带实时显示）
function BattleEditorCLI.RunBattleLoop()
    if isBattleLoopRunning then
        BattleDisplay.ShowMessage("战斗循环已在运行中", "warning")
        return
    end

    if not BattleMain.IsRunning() then
        BattleDisplay.ShowMessage("战斗未启动！请先调用 StartEditor()", "error")
        return
    end

    isBattleLoopRunning = true
    Logger.Log("[BattleEditorCLI] 战斗循环启动")

    -- 使用协程模拟战斗循环
    battleLoopThread = coroutine.create(function()
        while isBattleLoopRunning and BattleMain.IsRunning() do
            -- 更新战斗逻辑
            BattleMain.Update()

            -- 刷新显示
            BattleDisplay.Refresh()

            -- 检查战斗是否结束
            local result = BattleMain.GetBattleResult()
            if result and result.isFinished then
                BattleDisplay.ShowVictoryScreen(result.winner)
                isBattleLoopRunning = false
                break
            end

            -- 等待更新间隔
            -- 在Lua中模拟延迟
            local startTime = os.clock()
            while os.clock() - startTime < UPDATE_INTERVAL do
                -- 忙等待，实际项目中可以使用更优雅的定时器
            end
        end

        isBattleLoopRunning = false
        battleLoopThread = nil
    end)

    -- 启动协程
    coroutine.resume(battleLoopThread)
end

--- 暂停战斗
function BattleEditorCLI.PauseBattle()
    if not BattleMain.IsRunning() then
        BattleDisplay.ShowMessage("战斗未运行！", "error")
        return
    end

    BattleMain.Pause()
    BattleDisplay.ShowMessage("战斗已暂停", "warning")
    BattleDisplay.Refresh()
end

--- 恢复战斗
function BattleEditorCLI.ResumeBattle()
    if not BattleMain.IsRunning() then
        BattleDisplay.ShowMessage("战斗未运行！", "error")
        return
    end

    BattleMain.Resume()
    BattleDisplay.ShowMessage("战斗已恢复", "success")
end

--- 停止战斗循环
function BattleEditorCLI.StopBattleLoop()
    isBattleLoopRunning = false
    if battleLoopThread then
        battleLoopThread = nil
    end
    BattleDisplay.ShowMessage("战斗循环已停止", "info")
end

-- ==================== 状态显示 ====================

--- 显示当前战斗状态
function BattleEditorCLI.ShowBattleStatus()
    if not BattleMain.IsRunning() then
        print("")
        BattleDisplay.ShowMessage("战斗未运行", "warning")
        print("")
        return
    end

    BattleDisplay.ClearScreen()

    -- 显示回合信息
    BattleDisplay.ShowRoundInfo()

    -- 显示战场
    BattleDisplay.ShowBattleField()

    -- 显示行动顺序
    local allHeroes = BattleFormation.GetAllAliveHeroes()
    table.sort(allHeroes, function(a, b)
        return (a.actionForce or 0) > (b.actionForce or 0)
    end)
    BattleDisplay.ShowActionOrder(allHeroes)

    -- 显示战斗日志
    BattleDisplay.ShowBattleLog()

    -- 显示模式信息
    print("")
    local modeText = isAutoMode and "自动模式" or "手动模式"
    local modeColor = isAutoMode and "success" or "info"
    BattleDisplay.ShowMessage(string.format("当前模式: %s | 回合: %d | 状态: %s",
        modeText,
        BattleMain.GetCurrentRound(),
        BattleMain.IsPaused() and "暂停" or "进行中"), modeColor)
end

--- 交互式模式（带菜单）
function BattleEditorCLI.InteractiveMode()
    if not BattleMain.IsRunning() then
        print("")
        print("战斗未启动，请先调用 BattleEditorCLI.StartEditor(config)")
        print("")
        return
    end

    local running = true

    while running and BattleMain.IsRunning() do
        BattleDisplay.ClearScreen()
        BattleDisplay.Refresh()

        print("")
        BattleDisplay.ShowSeparator("战斗编辑器菜单")
        print("")

        local options = {
            "释放技能",
            "查看英雄属性",
            "查看英雄技能",
            "切换自动/手动模式",
            "暂停/继续战斗",
            "热重载技能",
            "显示战斗状态",
            "退出交互模式"
        }

        for i, option in ipairs(options) do
            print(string.format("  [%d] %s", i, option))
        end

        print("")
        io.write("请选择操作 (1-8): ")
        local choice = io.read()
        local num = tonumber(choice)

        if num == 1 then
            BattleEditorCLI.InteractiveCastSkill()
        elseif num == 2 then
            BattleEditorCLI.InteractiveShowHeroAttr()
        elseif num == 3 then
            BattleEditorCLI.InteractiveShowHeroSkills()
        elseif num == 4 then
            BattleEditorCLI.DoAuto()
            BattleMenu.WaitForKey()
        elseif num == 5 then
            if BattleMain.IsPaused() then
                BattleEditorCLI.ResumeBattle()
            else
                BattleEditorCLI.PauseBattle()
            end
            BattleMenu.WaitForKey()
        elseif num == 6 then
            BattleEditorCLI.InteractiveReloadSkill()
        elseif num == 7 then
            BattleEditorCLI.ShowBattleStatus()
            BattleMenu.WaitForKey()
        elseif num == 8 then
            running = false
            BattleDisplay.ShowMessage("退出交互模式", "info")
        else
            BattleDisplay.ShowMessage("无效选择", "error")
            BattleMenu.WaitForKey()
        end
    end
end

-- ==================== 交互式子菜单 ====================

--- 交互式释放技能
function BattleEditorCLI.InteractiveCastSkill()
    BattleDisplay.ClearScreen()
    BattleDisplay.ShowTitle("释放技能")

    -- 选择阵营
    print("")
    print("选择阵营:")
    print("  [1] 左侧队伍 (A)")
    print("  [2] 右侧队伍 (B)")
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local campChoice = tonumber(io.read())

    if campChoice ~= 1 and campChoice ~= 2 then
        return
    end

    local camp = campChoice == 1 and E_CAMP_TYPE.A or E_CAMP_TYPE.B
    local isLeft = (camp == E_CAMP_TYPE.A)
    local team = isLeft and BattleFormation.teamLeft or BattleFormation.teamRight

    -- 选择英雄
    local heroes = {}
    for _, hero in ipairs(team) do
        if hero.isAlive and not hero.isDead then
            table.insert(heroes, hero)
        end
    end

    if #heroes == 0 then
        BattleDisplay.ShowMessage("该阵营没有存活的英雄", "error")
        BattleMenu.WaitForKey()
        return
    end

    print("")
    print("选择英雄:")
    for i, hero in ipairs(heroes) do
        print(string.format("  [%d] %s (位置: %d)", i, hero.name, hero.wpType))
    end
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local heroChoice = tonumber(io.read())

    if heroChoice < 1 or heroChoice > #heroes then
        return
    end

    local hero = heroes[heroChoice]

    -- 选择技能
    local skillList = BattleEditorCLI.GetHeroSkillList(camp, hero.wpType)
    if not skillList or #skillList.skills == 0 then
        BattleDisplay.ShowMessage("该英雄没有可用技能", "error")
        BattleMenu.WaitForKey()
        return
    end

    print("")
    print("选择技能:")
    for i, skillInfo in ipairs(skillList.skills) do
        local status = skillInfo.isReady and "✓" or string.format("CD:%d", skillInfo.coolDown)
        print(string.format("  [%d] %s [%s] - %s (%s)",
            i, skillInfo.name, skillInfo.typeName, status, skillInfo.targetName))
    end
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local skillChoice = tonumber(io.read())

    if skillChoice < 1 or skillChoice > #skillList.skills then
        return
    end

    local selectedSkill = skillList.skills[skillChoice]

    -- 释放技能
    BattleEditorCLI.DoSkill(camp, hero.wpType, selectedSkill.skillId)
    BattleMenu.WaitForKey()
end

--- 交互式查看英雄属性
function BattleEditorCLI.InteractiveShowHeroAttr()
    BattleDisplay.ClearScreen()
    BattleDisplay.ShowTitle("查看英雄属性")

    -- 选择阵营
    print("")
    print("选择阵营:")
    print("  [1] 左侧队伍 (A)")
    print("  [2] 右侧队伍 (B)")
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local campChoice = tonumber(io.read())

    if campChoice ~= 1 and campChoice ~= 2 then
        return
    end

    local camp = campChoice == 1 and E_CAMP_TYPE.A or E_CAMP_TYPE.B
    local isLeft = (camp == E_CAMP_TYPE.A)
    local team = isLeft and BattleFormation.teamLeft or BattleFormation.teamRight

    -- 选择英雄
    print("")
    print("选择英雄:")
    for i, hero in ipairs(team) do
        local status = hero.isAlive and "存活" or "阵亡"
        print(string.format("  [%d] %s (位置: %d) - %s", i, hero.name, hero.wpType, status))
    end
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local heroChoice = tonumber(io.read())

    if heroChoice < 1 or heroChoice > #team then
        return
    end

    local hero = team[heroChoice]
    local attrTable = BattleEditorCLI.GetHeroAttrTable(camp, hero.wpType)

    -- 显示属性表格
    BattleDisplay.ClearScreen()
    BattleDisplay.ShowTitle(attrTable.title)
    print("")

    -- 打印表头
    local headerStr = string.format("| %-12s | %-12s | %-20s |", attrTable.headers[1], attrTable.headers[2], attrTable.headers[3])
    print(headerStr)
    print(string.rep("-", #headerStr))

    -- 打印行
    for _, row in ipairs(attrTable.rows) do
        if row[1] == "---" then
            print(string.rep("-", #headerStr))
        else
            print(string.format("| %-12s | %-12s | %-20s |", row[1], row[2], row[3]))
        end
    end

    print("")
    BattleMenu.WaitForKey()
end

--- 交互式查看英雄技能
function BattleEditorCLI.InteractiveShowHeroSkills()
    BattleDisplay.ClearScreen()
    BattleDisplay.ShowTitle("查看英雄技能")

    -- 选择阵营
    print("")
    print("选择阵营:")
    print("  [1] 左侧队伍 (A)")
    print("  [2] 右侧队伍 (B)")
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local campChoice = tonumber(io.read())

    if campChoice ~= 1 and campChoice ~= 2 then
        return
    end

    local camp = campChoice == 1 and E_CAMP_TYPE.A or E_CAMP_TYPE.B
    local isLeft = (camp == E_CAMP_TYPE.A)
    local team = isLeft and BattleFormation.teamLeft or BattleFormation.teamRight

    -- 选择英雄
    print("")
    print("选择英雄:")
    for i, hero in ipairs(team) do
        local status = hero.isAlive and "存活" or "阵亡"
        print(string.format("  [%d] %s (位置: %d) - %s", i, hero.name, hero.wpType, status))
    end
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local heroChoice = tonumber(io.read())

    if heroChoice < 1 or heroChoice > #team then
        return
    end

    local hero = team[heroChoice]
    local skillList = BattleEditorCLI.GetHeroSkillList(camp, hero.wpType)

    -- 显示技能列表
    BattleDisplay.ClearScreen()
    BattleDisplay.ShowTitle(skillList.title)
    print("")

    if #skillList.skills == 0 then
        print("  该英雄没有技能")
    else
        for i, skillInfo in ipairs(skillList.skills) do
            print(string.format("  [%d] %s", i, skillInfo.name))
            print(string.format("      类型: %s", skillInfo.typeName))
            print(string.format("      等级: %d", skillInfo.level))
            print(string.format("      冷却: %d/%d", skillInfo.coolDown, skillInfo.maxCoolDown))
            print(string.format("      状态: %s", skillInfo.isReady and "就绪" or "冷却中"))
            print(string.format("      目标: %s", skillInfo.targetName))
            print(string.format("      描述: %s", skillInfo.description))
            print("")
        end
    end

    BattleMenu.WaitForKey()
end

--- 交互式热重载技能
function BattleEditorCLI.InteractiveReloadSkill()
    BattleDisplay.ClearScreen()
    BattleDisplay.ShowTitle("热重载技能")

    print("")
    print("选择操作:")
    print("  [1] 重载指定英雄的技能")
    print("  [2] 重载所有技能")
    print("  [0] 取消")
    print("")
    io.write("请选择: ")
    local choice = tonumber(io.read())

    if choice == 2 then
        BattleEditorCLI.DoSkillReload(E_CAMP_TYPE.A, 0, nil)
        BattleMenu.WaitForKey()
    elseif choice == 1 then
        -- 选择阵营
        print("")
        print("选择阵营:")
        print("  [1] 左侧队伍 (A)")
        print("  [2] 右侧队伍 (B)")
        print("  [0] 取消")
        print("")
        io.write("请选择: ")
        local campChoice = tonumber(io.read())

        if campChoice ~= 1 and campChoice ~= 2 then
            return
        end

        local camp = campChoice == 1 and E_CAMP_TYPE.A or E_CAMP_TYPE.B
        local isLeft = (camp == E_CAMP_TYPE.A)
        local team = isLeft and BattleFormation.teamLeft or BattleFormation.teamRight

        -- 选择英雄
        print("")
        print("选择英雄:")
        for i, hero in ipairs(team) do
            print(string.format("  [%d] %s (位置: %d)", i, hero.name, hero.wpType))
        end
        print("  [0] 取消")
        print("")
        io.write("请选择: ")
        local heroChoice = tonumber(io.read())

        if heroChoice < 1 or heroChoice > #team then
            return
        end

        local hero = team[heroChoice]

        -- 选择技能
        local skillList = BattleEditorCLI.GetHeroSkillList(camp, hero.wpType)
        if #skillList.skills == 0 then
            BattleDisplay.ShowMessage("该英雄没有技能", "error")
            BattleMenu.WaitForKey()
            return
        end

        print("")
        print("选择技能 (0 重载所有):")
        for i, skillInfo in ipairs(skillList.skills) do
            print(string.format("  [%d] %s (ID: %d)", i, skillInfo.name, skillInfo.skillId))
        end
        print("  [0] 重载该英雄所有技能")
        print("")
        io.write("请选择: ")
        local skillChoice = tonumber(io.read())

        if skillChoice == 0 then
            BattleEditorCLI.DoSkillReload(camp, hero.wpType, nil)
        elseif skillChoice >= 1 and skillChoice <= #skillList.skills then
            local skillId = skillList.skills[skillChoice].skillId
            BattleEditorCLI.DoSkillReload(camp, hero.wpType, skillId)
        end

        BattleMenu.WaitForKey()
    end
end

-- ==================== 辅助函数 ====================

--- 获取技能类型名称
---@param skillType number 技能类型
---@return string 类型名称
function BattleEditorCLI.GetSkillTypeName(skillType)
    local typeNames = {
        [E_SKILL_TYPE_NORMAL] = "普通攻击",
        [E_SKILL_TYPE_ULTIMATE] = "终极技能",
        [E_SKILL_TYPE_PASSIVE] = "被动技能",
        [E_SKILL_TYPE_COLLECT] = "收集技能",
        [E_SKILL_TYPE_HIDE] = "隐藏技能",
    }
    return typeNames[skillType] or "未知类型(" .. tostring(skillType) .. ")"
end

--- 获取施法目标类型名称
---@param castTarget number 目标类型
---@return string 类型名称
function BattleEditorCLI.GetCastTargetName(castTarget)
    local targetNames = {
        [E_CAST_TARGET.Enemy] = "敌方",
        [E_CAST_TARGET.Self] = "自己",
        [E_CAST_TARGET.Alias] = "友方",
        [E_CAST_TARGET.AlliesExcludeSelf] = "友方(不含自己)",
        [E_CAST_TARGET.EveryOne] = "所有人",
        [E_CAST_TARGET.EveryOneExcludeSelf] = "所有人(不含自己)",
    }
    return targetNames[castTarget] or "未知目标(" .. tostring(castTarget) .. ")"
end

--- 战斗结束回调
---@param result table 战斗结果
function BattleEditorCLI.OnBattleEnd(result)
    isBattleLoopRunning = false
    battleLoopThread = nil

    print("")
    BattleDisplay.ShowVictoryScreen(result.winner)

    if result.reason then
        BattleDisplay.ShowMessage("战斗结束原因: " .. result.reason, "info")
    end

    Logger.Log(string.format("[BattleEditorCLI] 战斗结束，获胜方: %s", tostring(result.winner)))
end

--- 获取当前模式
---@return boolean 是否为自动模式
function BattleEditorCLI.IsAutoMode()
    return isAutoMode
end

--- 获取战斗循环状态
---@return boolean 是否正在运行
function BattleEditorCLI.IsBattleLoopRunning()
    return isBattleLoopRunning
end

--- 打印帮助信息
function BattleEditorCLI.ShowHelp()
    print("")
    BattleDisplay.ShowTitle("BattleEditorCLI 帮助")
    print("")
    print("核心功能:")
    print("  StartEditor(config)     - 启动编辑器并开始战斗")
    print("  DoSkill(camp, wpType, skillId) - 手动释放技能")
    print("  DoAuto(isAuto)          - 切换自动/手动模式")
    print("")
    print("查询功能:")
    print("  GetHeroAttrTable(camp, wpType)   - 获取英雄属性表格")
    print("  GetHeroSkillList(camp, wpType)   - 获取英雄技能列表")
    print("  DoSkillReload(camp, wpType, skillId) - 热重载技能")
    print("")
    print("战斗控制:")
    print("  RunBattleLoop()         - 运行战斗主循环")
    print("  PauseBattle()           - 暂停战斗")
    print("  ResumeBattle()          - 恢复战斗")
    print("  StopBattleLoop()        - 停止战斗循环")
    print("")
    print("状态显示:")
    print("  ShowBattleStatus()      - 显示当前战斗状态")
    print("  InteractiveMode()       - 进入交互式菜单模式")
    print("")
    print("辅助功能:")
    print("  ShowHelp()              - 显示此帮助信息")
    print("  IsAutoMode()            - 获取当前模式")
    print("  IsBattleLoopRunning()   - 获取循环状态")
    print("")
end

return BattleEditorCLI
