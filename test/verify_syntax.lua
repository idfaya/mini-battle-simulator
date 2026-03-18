---
--- 验证新功能代码语法
---

print("========================================")
print("验证新功能代码语法")
print("========================================")

-- 测试1: 验证BattleFormation新函数
print("\n[测试1] 验证BattleFormation新函数定义...")
local bfContent = io.open("modules/battle_formation.lua", "r")
if bfContent then
    local content = bfContent:read("*all")
    bfContent:close()
    
    local checks = {
        ["GetFriendDiedCount"] = content:find("function BattleFormation.GetFriendDiedCount") ~= nil,
        ["GetEnemyRowCount"] = content:find("function BattleFormation.GetEnemyRowCount") ~= nil,
        ["GetRowLeftUnitNum"] = content:find("function BattleFormation.GetRowLeftUnitNum") ~= nil,
        ["CreateToken"] = content:find("function BattleFormation.CreateToken") ~= nil,
        ["DestroyToken"] = content:find("function BattleFormation.DestroyToken") ~= nil,
        ["IsToken"] = content:find("function BattleFormation.IsToken") ~= nil,
        ["ReduceTokenLife"] = content:find("function BattleFormation.ReduceTokenLife") ~= nil,
    }
    
    for name, found in pairs(checks) do
        print(string.format("  %s: %s", name, found and "✓" or "✗"))
    end
else
    print("  无法读取文件")
end

-- 测试2: 验证BattleSkillSeq新函数
print("\n[测试2] 验证BattleSkillSeq新函数定义...")
local bsContent = io.open("modules/battle_skill_seq.lua", "r")
if bsContent then
    local content = bsContent:read("*all")
    bsContent:close()
    
    local checks = {
        ["AddHideSkill"] = content:find("function BattleSkillSeq.AddHideSkill") ~= nil,
        ["GetHideSkillInSeq"] = content:find("function BattleSkillSeq.GetHideSkillInSeq") ~= nil,
        ["HasHideSkillInSeq"] = content:find("function BattleSkillSeq.HasHideSkillInSeq") ~= nil,
        ["AddUltimateSkillNoCost"] = content:find("function BattleSkillSeq.AddUltimateSkillNoCost") ~= nil,
        ["GetNoCostUltimateInSeq"] = content:find("function BattleSkillSeq.GetNoCostUltimateInSeq") ~= nil,
        ["HasNoCostUltimateInSeq"] = content:find("function BattleSkillSeq.HasNoCostUltimateInSeq") ~= nil,
    }
    
    for name, found in pairs(checks) do
        print(string.format("  %s: %s", name, found and "✓" or "✗"))
    end
else
    print("  无法读取文件")
end

-- 测试3: 验证BattleScriptExp新函数
print("\n[测试3] 验证BattleScriptExp函数实现...")
local bseContent = io.open("core/battle_script_exp.lua", "r")
if bseContent then
    local content = bseContent:read("*all")
    bseContent:close()
    
    local checks = {
        ["CastHideSkill (无TODO)"] = content:find("TODO.*隐藏") == nil and content:find("function BattleScriptExp.CastHideSkill") ~= nil,
        ["AddUltimateSkillNoCost (无TODO)"] = content:find("TODO.*无消耗") == nil and content:find("function BattleScriptExp.AddUltimateSkillNoCost") ~= nil,
        ["CreateToken (无TODO)"] = content:find("TODO.*召唤") == nil and content:find("function BattleScriptExp.CreateToken") ~= nil,
        ["DestroyToken (无TODO)"] = content:find("TODO.*销毁") == nil and content:find("function BattleScriptExp.DestroyToken") ~= nil,
    }
    
    for name, found in pairs(checks) do
        print(string.format("  %s: %s", name, found and "✓" or "✗"))
    end
else
    print("  无法读取文件")
end

-- 测试4: 验证BattleSkill条件判断
print("\n[测试4] 验证BattleSkill条件判断实现...")
local bsContent2 = io.open("modules/battle_skill.lua", "r")
if bsContent2 then
    local content = bsContent2:read("*all")
    bsContent2:close()
    
    local checks = {
        ["Round条件"] = content:find("BattleMain.GetCurrentRound") ~= nil,
        ["EnemyRowCount条件"] = content:find("GetEnemyRowCount") ~= nil,
        ["FriendDiedNum条件"] = content:find("GetFriendDiedCount") ~= nil,
        ["无TODO"] = content:find("TODO.*回合") == nil and content:find("TODO.*行数") == nil and content:find("TODO.*死亡") == nil,
    }
    
    for name, found in pairs(checks) do
        print(string.format("  %s: %s", name, found and "✓" or "✗"))
    end
else
    print("  无法读取文件")
end

print("\n========================================")
print("语法验证完成!")
print("========================================")
