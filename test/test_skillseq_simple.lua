#!/usr/bin/env lua

---============================================================================
--- BattleSkillSeq 独立测试
--- 不依赖其他模块，直接测试 BattleSkillSeq 的生命周期
---============================================================================

print("========================================")
print("BattleSkillSeq 生命周期测试")
print("========================================")

-- 设置包路径
local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local base_dir = script_dir:gsub("test/", ""):gsub("test\\", "")

package.path = package.path
    .. ";" .. base_dir .. "?.lua"
    .. ";" .. base_dir .. "modules/?.lua"
    .. ";" .. base_dir .. "utils/?.lua"
    .. ";" .. base_dir .. "core/?.lua"

-- 加载所需模块
local Logger = require("utils.logger")

-- 加载枚举定义（定义 E_SKILL_TYPE_ULTIMATE 等常量）
require("core.battle_enum")

local BattleSkillSeq = require("modules.battle_skill_seq")

-- 设置日志级别
Logger.SetLogLevel(Logger.LOG_LEVELS.DEBUG)

-- ==================== 测试1: 初始状态验证 ====================
print("\n[测试1] 验证初始状态...")

-- 直接调用 Init 确保状态干净
BattleSkillSeq.Init()

local ultimateCount = BattleSkillSeq.GetUltimateSkillCount()
local hideCount = BattleSkillSeq.GetHideSkillCount()
local noCostCount = BattleSkillSeq.GetNoCostUltimateCount()

print(string.format("  终极技能队列: %d", ultimateCount))
print(string.format("  隐藏技能队列: %d", hideCount))
print(string.format("  无消耗大招队列: %d", noCostCount))

if ultimateCount == 0 and hideCount == 0 and noCostCount == 0 then
    print("  ✓ 初始状态正确（所有队列为空）")
else
    print("  ✗ 初始状态异常！")
    os.exit(1)
end

-- ==================== 测试2: 模拟添加技能后状态 ====================
print("\n[测试2] 模拟添加技能到队列...")

-- 创建一个模拟英雄（带终极技能）
local mockHero = {
    id = 9999,
    name = "测试英雄",
    isAlive = true,
    isDead = false,
    skills = {
        { skillId = 1001, skillType = 2, name = "测试大招", skillCost = 50 },  -- 2 = E_SKILL_TYPE_ULTIMATE
        { skillId = 1002, skillType = 1, name = "普通攻击" }  -- 1 = E_SKILL_TYPE_NORMAL
    }
}

-- 创建一个没有终极技能的英雄（用于测试边界情况）
local mockHeroNoUltimate = {
    id = 9998,
    name = "无大招英雄",
    isAlive = true,
    isDead = false,
    skills = {
        { skillId = 1003, skillType = 1, name = "普通攻击" }  -- 只有普通攻击
    }
}

-- 添加隐藏技能
BattleSkillSeq.AddHideSkill(mockHero, nil, 12345)
hideCount = BattleSkillSeq.GetHideSkillCount()
print(string.format("  添加隐藏技能后队列: %d", hideCount))

-- 添加无消耗大招
BattleSkillSeq.AddUltimateSkillNoCost(mockHero, nil)
noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
print(string.format("  添加无消耗大招后队列: %d", noCostCount))

if hideCount == 1 and noCostCount == 1 then
    print("  ✓ 技能添加成功")
else
    print("  ✗ 技能添加失败！")
    os.exit(1)
end

-- ==================== 测试3: 模拟战斗退出后状态 ====================
print("\n[测试3] 模拟战斗退出后状态...")

-- 调用 OnFinal 清理
BattleSkillSeq.OnFinal()

ultimateCount = BattleSkillSeq.GetUltimateSkillCount()
hideCount = BattleSkillSeq.GetHideSkillCount()
noCostCount = BattleSkillSeq.GetNoCostUltimateCount()

print(string.format("  终极技能队列: %d", ultimateCount))
print(string.format("  隐藏技能队列: %d", hideCount))
print(string.format("  无消耗大招队列: %d", noCostCount))

if ultimateCount == 0 and hideCount == 0 and noCostCount == 0 then
    print("  ✓ 清理后状态正确（所有队列为空）")
else
    print("  ✗ 清理后状态异常！")
    os.exit(1)
end

-- ==================== 测试4: 连续战斗测试 ====================
print("\n[测试4] 连续战斗测试...")

for round = 1, 3 do
    -- 启动战斗（调用 Init）
    BattleSkillSeq.Init()
    
    -- 检查初始状态
    hideCount = BattleSkillSeq.GetHideSkillCount()
    noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
    
    if hideCount ~= 0 or noCostCount ~= 0 then
        print(string.format("  ✗ 第 %d 场战斗启动时状态异常！", round))
        os.exit(1)
    end
    
    -- 添加一些技能
    BattleSkillSeq.AddHideSkill(mockHero, nil, 12345)
    BattleSkillSeq.AddUltimateSkillNoCost(mockHero, nil)
    
    -- 验证添加成功
    if BattleSkillSeq.GetHideSkillCount() ~= 1 or BattleSkillSeq.GetNoCostUltimateCount() ~= 1 then
        print(string.format("  ✗ 第 %d 场战斗添加技能失败！", round))
        os.exit(1)
    end
    
    -- 退出战斗（调用 OnFinal）
    BattleSkillSeq.OnFinal()
    
    -- 验证清理
    hideCount = BattleSkillSeq.GetHideSkillCount()
    noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
    
    if hideCount ~= 0 or noCostCount ~= 0 then
        print(string.format("  ✗ 第 %d 场战斗退出后状态未清理！", round))
        os.exit(1)
    end
    
    print(string.format("  第 %d 场战斗: 启动干净 ✓, 添加技能 ✓, 退出清理 ✓", round))
end

print("  ✓ 连续战斗测试通过")

-- ==================== 测试5: 验证 GetStats 和 Dump ====================
print("\n[测试5] 验证统计和调试功能...")

BattleSkillSeq.Init()
BattleSkillSeq.AddHideSkill(mockHero, nil, 12345)

local stats = BattleSkillSeq.GetStats()
print(string.format("  终极技能数量: %d", stats.ultimateSkillCount))
print(string.format("  被动技能英雄数: %d", stats.passiveSkillHeroCount))
print(string.format("  总被动技能数: %d", stats.totalPassiveSkillCount))

-- 测试 Dump 功能（仅验证不报错）
local success, err = pcall(function()
    BattleSkillSeq.Dump()
end)

if success then
    print("  ✓ Dump 功能正常")
else
    print(string.format("  ✗ Dump 功能异常: %s", err))
    os.exit(1)
end

BattleSkillSeq.OnFinal()
print("  ✓ 统计功能测试通过")

-- ==================== 测试总结 ====================
print("\n========================================")
print("测试总结")
print("========================================")
print("所有测试通过！")
print("  ✓ BattleSkillSeq.Init 正确初始化队列")
print("  ✓ BattleSkillSeq.OnFinal 正确清理队列")
print("  ✓ 技能添加和获取功能正常")
print("  ✓ 连续战斗不会出现状态串扰")
print("  ✓ 统计和调试功能正常")
print("========================================")

return true
