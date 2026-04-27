#!/usr/bin/env lua

-- Mini Battle Simulator - Main Entry Point

-- 设置 Windows 控制台为 UTF-8 编码（支持中文显示）
if os.getenv("OS") == "Windows_NT" then
    os.execute("chcp 65001 >nul 2>&1")
end

-- 获取脚本所在目录
local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"

local LuaBootstrap = dofile(script_dir .. "core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(debug.getinfo(1, "S").source, {
    extraPatterns = {
        script_dir .. "test/?.lua",
    },
    includeLegacyAssets = true,
})

-- 加载所需工具库
local Logger = require("utils.logger")
local Inspect = require("utils.inspect")
local JSON = require("utils.json")

-- 设置日志级别
Logger.SetLogLevel(Logger.LOG_LEVELS.DEBUG)

-- 打印欢迎信息
local function PrintWelcome()
    print("========================================")
    print("    Mini Battle Simulator v1.0")
    print("========================================")
    print("")
end

-- 打印菜单
local function PrintMenu()
    print("请选择操作:")
    print("  1. 运行简单战斗测试")
    print("  2. 运行完整战斗模拟")
    print("  3. 运行单场战斗测试")
    print("  4. 退出")
    print("")
    io.write("请输入选项 (1-4): ")
end

-- 运行简单战斗测试
function RunSimpleTest()
    print("")
    print("========================================")
    print("        运行简单战斗测试")
    print("========================================")
    print("")

    -- 加载测试模块
    local SingleBattleTest = require("runtime.single_battle_test")

    -- 运行测试
    local success, result = pcall(function()
        return SingleBattleTest.Run({ autoUltimate = false, initialEnergy = 40 })
    end)

    if success then
        print("")
        print("测试完成!")
        if result then
            print("测试结果: " .. tostring(result))
        end
    else
        print("")
        print("测试执行失败:")
        print(result)
    end

    print("")
    print("按回车键继续...")
    io.read()
end

-- 运行完整战斗模拟
function RunBattleSimulation()
    print("")
    print("========================================")
    print("        运行完整战斗模拟")
    print("========================================")
    print("")

    -- 加载 BattleEditor CLI
    local BattleEditorCLI = require("ui.battle_editor_cli")
    local HeroData = require("config.hero_data")

    -- 创建测试配置
    local config = HeroData.CreateTestBattleConfig()

    -- 启动编辑器
    BattleEditorCLI.StartEditor(config)

    -- 进入交互模式
    BattleEditorCLI.InteractiveMode()

    print("")
    print("按回车键继续...")
    io.read()
end

-- 运行单场战斗测试
function RunSingleBattleTest()
    print("")
    print("========================================")
    print("        运行单场战斗测试")
    print("========================================")
    print("")

    local SingleBattleTest = require("runtime.single_battle_test")
    local success, result = pcall(function()
        return SingleBattleTest.Run()
    end)

    if not success then
        print("")
        print("单场战斗测试执行失败:")
        print(result)
    end

    print("")
    print("按回车键继续...")
    io.read()
end

-- 主函数
local function Main()
    PrintWelcome()

    local running = true
    while running do
        PrintMenu()

        local choice = io.read()
        if not choice then
            -- 如果输入为nil（如管道输入结束），退出程序
            running = false
            print("")
            print("输入结束，程序退出")
            break
        end
        choice = choice:match("^%s*(.-)%s*$") -- 去除首尾空白

        if choice == "1" then
            RunSimpleTest()
        elseif choice == "2" then
            RunBattleSimulation()
        elseif choice == "3" then
            RunSingleBattleTest()
        elseif choice == "4" then
            running = false
            print("")
            print("感谢使用 Mini Battle Simulator，再见!")
        else
            print("")
            print("无效的选项，请重新输入")
            print("")
        end
    end
end

-- 程序入口
Main()
