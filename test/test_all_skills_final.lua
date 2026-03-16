--!/usr/bin/env lua
-- 测试所有技能文件

local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
script_dir = script_dir:gsub("test/", "")

package.path = package.path
    .. ";" .. script_dir .. "?.lua"
    .. ";" .. script_dir .. "core/?.lua"
    .. ";" .. script_dir .. "modules/?.lua"
    .. ";" .. script_dir .. "config/?.lua"
    .. ";" .. script_dir .. "utils/?.lua"

print("========================================")
print("  测试所有技能文件")
print("========================================\n")

require("core.battle_enum")

-- 预定义技能ID列表（从实际文件名提取）
local skillIds = {
    1310101, 1310102, 1310103, 1310201, 1310202, 1310203,
    1310301, 1310302, 1310303, 1310401, 1310402, 1310403,
    1310601, 1310602, 1310603, 1310801, 1310802, 1310803,
    1311401, 1311402, 1311403, 1311901, 1311902, 1311903,
    1312201, 1312202, 1312203, 1312301, 1312302, 1312303,
    1312401, 1312402, 1312403, 1312501, 1312502, 1312503,
    1312601, 1312602, 1312603, 1312701, 1312702, 1312703,
    1312801, 1312802, 1312803, 1312901, 1312902, 1312903,
    1313001, 1313002, 1313003, 1313101, 1313102, 1313103,
    1313201, 1313202, 1313203, 1313301, 1313302, 1313303,
    1313401, 1313402, 1313403, 1313501, 1313502, 1313503,
    1313601, 1313602, 1313603, 1313701, 1313702, 1313703,
    1313801, 1313802, 1313803, 1313901, 1313902, 1313903,
    1314001, 1314002, 1314003, 1314101, 1314102, 1314103,
    1314201, 1314202, 1314203, 1314301, 1314302, 1314303,
    1314401, 1314402, 1314403, 1314501, 1314502, 1314503,
    1314601, 1314602, 1314603, 1314701, 1314702, 1314703,
    1314801, 1314802, 1314803, 1314901, 1314902, 1314903,
    1315001, 1315002, 1315003, 1315101, 1315102, 1315103,
    1315201, 1315202, 1315203, 1315301, 1315302, 1315303,
    1315401, 1315402, 1315403, 1315501, 1315502, 1315503,
    1315601, 1315602, 1315603, 1315701, 1315702, 1315703,
    1315801, 1315802, 1315803, 1315901, 1315902, 1315903,
    1316001, 1316002, 1316003, 1316101, 1316102, 1316103,
    1316201, 1316202, 1316203, 1316301, 1316302, 1316303,
    1316401, 1316402, 1316403, 1316501, 1316502, 1316503,
    1316601, 1316602, 1316603, 1316701, 1316702, 1316703,
    1316801, 1316802, 1316803, 1316901, 1316902, 1316903,
    1317001, 1317002, 1317003, 1317101, 1317102, 1317103,
    1317201, 1317202, 1317203, 1317301, 1317302, 1317303,
    1317401, 1317402, 1317403, 1317501, 1317502, 1317503,
    1317601, 1317602, 1317603, 1317701, 1317702, 1317703,
    1317801, 1317802, 1317803, 1317901, 1317902, 1317903,
    1318001, 1318002, 1318003, 1318101, 1318102, 1318103,
    1318201, 1318202, 1318203, 1318301, 1318302, 1318303,
    1318401, 1318402, 1318403, 1318501, 1318502, 1318503,
    1318601, 1318602, 1318603, 1318701, 1318702, 1318703,
    1318801, 1318802, 1318803, 1318901, 1318902, 1318903,
    1319001, 1319002, 1319003, 1319101, 1319102, 1319103,
    1319201, 1319202, 1319203, 1319301, 1319302, 1319303,
    1319401, 1319402, 1319403, 1319501, 1319502, 1319503,
    1319601, 1319602, 1319603, 1319701, 1319702, 1319703,
    1319801, 1319802, 1319803, 1319901, 1319902, 1319903,
    1320001, 1320002, 1320003,
}

local function LoadSkill(skillId)
    local fullSkillId = skillId * 100 + 1
    local luaFileName = string.format("skill_%d", fullSkillId)
    local luaPath = string.format("config.skill.%s", luaFileName)
    
    local success, result = pcall(require, luaPath)
    if not success then
        return nil
    end
    
    return _G[luaFileName]
end

local function AnalyzeSkill(skillData)
    local analysis = {hasDamage = false, hasHeal = false, hasBuff = false, hasSpell = false, targetNum = 0}
    
    if not skillData or not skillData.actData then return analysis end
    
    for _, act in ipairs(skillData.actData) do
        if act.keyFrameDatas then
            for _, kf in ipairs(act.keyFrameDatas) do
                if kf.datatype == "DWCommon.DamageData" then analysis.hasDamage = true
                elseif kf.datatype == "DWCommon.HealData" then analysis.hasHeal = true
                elseif kf.datatype == "DWCommon.LaunchBuff" then analysis.hasBuff = true
                elseif kf.datatype == "DWCommon.LaunchSpell" then analysis.hasSpell = true
                end
            end
        end
    end
    
    if skillData.targetsSelections and skillData.targetsSelections.tSConditions then
        analysis.targetNum = skillData.targetsSelections.tSConditions.Num or 0
    end
    
    return analysis
end

print(string.format("准备测试 %d 个技能...\n", #skillIds))

local stats = {total = #skillIds, loaded = 0, failed = 0, withDamage = 0, withHeal = 0, withBuff = 0, withSpell = 0, singleTarget = 0, aoeTarget = 0}
local samples = {}

for i, skillId in ipairs(skillIds) do
    local skillData = LoadSkill(skillId)
    
    if skillData then
        stats.loaded = stats.loaded + 1
        local analysis = AnalyzeSkill(skillData)
        
        if analysis.hasDamage then stats.withDamage = stats.withDamage + 1 end
        if analysis.hasHeal then stats.withHeal = stats.withHeal + 1 end
        if analysis.hasBuff then stats.withBuff = stats.withBuff + 1 end
        if analysis.hasSpell then stats.withSpell = stats.withSpell + 1 end
        
        if analysis.targetNum > 1 then stats.aoeTarget = stats.aoeTarget + 1
        else stats.singleTarget = stats.singleTarget + 1 end
        
        if #samples < 10 then
            table.insert(samples, {id = skillId, name = skillData.Name or "Unknown", analysis = analysis})
        end
        
        if i % 50 == 0 then print(string.format("已测试 %d/%d 个技能...", i, stats.total)) end
    else
        stats.failed = stats.failed + 1
    end
end

print("\n========================================")
print("  测试结果统计")
print("========================================")
print(string.format("\n总计: %d 个技能", stats.total))
print(string.format("成功加载: %d", stats.loaded))
print(string.format("加载失败: %d", stats.failed))
print("\n--- 技能类型 ---")
print(string.format("伤害技能: %d", stats.withDamage))
print(string.format("治疗技能: %d", stats.withHeal))
print(string.format("Buff技能: %d", stats.withBuff))
print(string.format("法术技能: %d", stats.withSpell))
print("\n--- 目标类型 ---")
print(string.format("单体攻击: %d", stats.singleTarget))
print(string.format("范围攻击: %d", stats.aoeTarget))

print("\n--- 技能示例 ---")
for i, skill in ipairs(samples) do
    local types = {}
    if skill.analysis.hasDamage then table.insert(types, "伤害") end
    if skill.analysis.hasHeal then table.insert(types, "治疗") end
    if skill.analysis.hasBuff then table.insert(types, "Buff") end
    if skill.analysis.hasSpell then table.insert(types, "法术") end
    print(string.format("[%d] %s (ID:%d) - %s - %s", i, skill.name, skill.id, table.concat(types, ","), skill.analysis.targetNum > 1 and "范围" or "单体"))
end

print("\n========================================")
print("  测试完成")
print("========================================")
