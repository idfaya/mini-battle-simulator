--!/usr/bin/env lua

--============================================================================
-- 所有技能批量测试
--============================================================================

-- 获取脚本所在目录并设置包路径
local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
script_dir = script_dir:gsub("test/", "")  -- 回到上级目录

-- 设置 Lua 包路径
package.path = package.path
    .. ";" .. script_dir .. "?.lua"
    .. ";" .. script_dir .. "core/?.lua"
    .. ";" .. script_dir .. "modules/?.lua"
    .. ";" .. script_dir .. "config/?.lua"
    .. ";" .. script_dir .. "utils/?.lua"
    .. ";" .. script_dir .. "Assets/Lua/Modules/Battle/SkillNewLua/?.lua"
    .. ";" .. script_dir .. "Assets/Lua/Modules/?.lua"
    .. ";" .. script_dir .. "Assets/Lua/?.lua"

-- 颜色代码
local COLORS = {
    RESET = "\27[0m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
    CYAN = "\27[36m",
}

local function printColor(color, msg)
    print(color .. msg .. COLORS.RESET)
end

print("========================================")
print("  所有技能批量测试")
print("========================================\n")

-- 加载必要模块
require("core.battle_enum")
require("config.skill_config")

-- 技能ID列表（从res_skill.json中的ClassID生成）
local commonSkillIds = {
    1310101, 1310102, 1310103,  -- 超人系列
    1310201, 1310202, 1310203,  -- 蝙蝠侠系列
    1310301, 1310302, 1310303,  -- 神奇女侠系列
    1310401, 1310402, 1310403,  -- 闪电侠系列
    1310501, 1310502, 1310503,  -- 海王系列
    1310601, 1310602, 1310603,  -- 钢骨系列
    1310701, 1310702, 1310703,  -- 绿灯侠系列
    1310801, 1310802, 1310803,  -- 沙赞系列
    1310901, 1310902, 1310903,  -- 鹰女系列
    1311001, 1311002, 1311003,  -- 火星猎人系列
    1311101, 1311102, 1311103,  -- 绿箭侠系列
    1311201, 1311202, 1311203,  -- 原子侠系列
    1311301, 1311302, 1311303,  -- 火风暴系列
    1311401, 1311402, 1311403,  -- 蓝甲虫系列
    1311501, 1311502, 1311503,  -- 罗宾系列
    1311601, 1311602, 1311603,  -- 夜翼系列
    1311701, 1311702, 1311703,  -- 红头罩系列
    1311801, 1311802, 1311803,  -- 蝙蝠女系列
    1311901, 1311902, 1311903,  -- 猫女系列
    1312001, 1312002, 1312003,  -- 哈莉奎茵系列
    1312101, 1312102, 1312103,  -- 毒藤女系列
    1312201, 1312202, 1312203,  -- 冷冻人系列
    1312301, 1312302, 1312303,  -- 企鹅人系列
    1312401, 1312402, 1312403,  -- 谜语人系列
    1312501, 1312502, 1312503,  -- 双面人系列
    1312601, 1312602, 1312603,  -- 稻草人系列
    1312701, 1312702, 1312703,  -- 贝恩系列
    1312801, 1312802, 1312803,  -- 丧钟系列
    1312901, 1312902, 1312903,  -- 死亡射手系列
    1313001, 1313002, 1313003,  -- 小丑系列
    1313101, 1313102, 1313103,  -- 黑面具系列
    1313201, 1313202, 1313203,  -- 泥脸系列
    1313301, 1313302, 1313303,  -- 杀手鳄系列
    1313401, 1313402, 1313403,  -- 人蝠系列
    1313501, 1313502, 1313503,  -- 腹语者系列
    1313601, 1313602, 1313603,  -- 疯帽匠系列
    1313701, 1313702, 1313703,  -- 猪面教授系列
    1313801, 1313802, 1313803,  -- 萤火虫系列
    1313901, 1313902, 1313903,  -- 电刑者系列
    1314001, 1314002, 1314003,  -- 铜头蛇系列
    1314101, 1314102, 1314103,  -- 西瓦女士系列
    1314201, 1314202, 1314203,  -- 塔利亚系列
    1314301, 1314302, 1314303,  -- 拉斯阿尔古尔系列
    1314401, 1314402, 1314403,  -- 忍者大师系列
    1314501, 1314502, 1314503,  -- 刺客联盟系列
    1314601, 1314602, 1314603,  -- 影武者联盟系列
    1314701, 1314702, 1314703,  -- 利维坦系列
    1314801, 1314802, 1314803,  -- 猫头鹰法庭系列
    1314901, 1314902, 1314903,  -- 猫头鹰利爪系列
    1315001, 1315002, 1315003,  -- 哥谭黑帮系列
    1315101, 1315102, 1315103,  -- 法尔科内家族系列
    1315201, 1315202, 1315203,  -- 马罗尼家族系列
    1315301, 1315302, 1315303,  -- 俄罗斯黑帮系列
    1315401, 1315402, 1315403,  -- 中国黑帮系列
    1315501, 1315502, 1315503,  -- 日本黑帮系列
    1315601, 1315602, 1315603,  -- 墨西哥黑帮系列
    1315701, 1315702, 1315703,  -- 意大利黑帮系列
    1315801, 1315802, 1315803,  -- 爱尔兰黑帮系列
    1315901, 1315902, 1315903,  -- 犹太黑帮系列
    1316001, 1316002, 1316003,  -- 亚美尼亚黑帮系列
    1316101, 1316102, 1316103,  -- 乌克兰黑帮系列
    1316201, 1316202, 1316203,  -- 波兰黑帮系列
    1316301, 1316302, 1316303,  -- 德国黑帮系列
    1316401, 1316402, 1316403,  -- 法国黑帮系列
    1316501, 1316502, 1316503,  -- 英国黑帮系列
    1316601, 1316602, 1316603,  -- 西班牙黑帮系列
    1316701, 1316702, 1316703,  -- 葡萄牙黑帮系列
    1316801, 1316802, 1316803,  -- 荷兰黑帮系列
    1316901, 1316902, 1316903,  -- 比利时黑帮系列
    1317001, 1317002, 1317003,  -- 瑞士黑帮系列
    1317101, 1317102, 1317103,  -- 瑞典黑帮系列
    1317201, 1317202, 1317203,  -- 挪威黑帮系列
    1317301, 1317302, 1317303,  -- 丹麦黑帮系列
    1317401, 1317402, 1317403,  -- 芬兰黑帮系列
    1317501, 1317502, 1317503,  -- 冰岛黑帮系列
    1317601, 1317602, 1317603,  -- 爱尔兰黑帮系列
    1317701, 1317702, 1317703,  -- 苏格兰黑帮系列
    1317801, 1317802, 1317803,  -- 威尔士黑帮系列
    1317901, 1317902, 1317903,  -- 英格兰黑帮系列
    1318001, 1318002, 1318003,  -- 北爱尔兰黑帮系列
    1318101, 1318102, 1318103,  -- 马恩岛黑帮系列
    1318201, 1318202, 1318203,  -- 泽西岛黑帮系列
    1318301, 1318302, 1318303,  -- 根西岛黑帮系列
    1318401, 1318402, 1318403,  -- 奥尔德尼岛黑帮系列
    1318501, 1318502, 1318503,  -- 萨克岛黑帮系列
    1318601, 1318602, 1318603,  -- 赫姆岛黑帮系列
    1318701, 1318702, 1318703,  -- 布雷库岛黑帮系列
    1318801, 1318802, 1318803,  -- 利胡岛黑帮系列
    1318901, 1318902, 1318903,  -- 埃克塞特岛黑帮系列
    1319001, 1319002, 1319003,  -- 怀特岛黑帮系列
    1319101, 1319102, 1319103,  -- 波特兰岛黑帮系列
    1319201, 1319202, 1319203,  -- 锡利群岛黑帮系列
    1319301, 1319302, 1319303,  -- 兰迪岛黑帮系列
    1319401, 1319402, 1319403,  -- 斯科默岛黑帮系列
    1319501, 1319502, 1319503,  -- 斯科克霍尔姆岛黑帮系列
    1319601, 1319602, 1319603,  -- 格拉斯霍尔姆岛黑帮系列
    1319701, 1319702, 1319703,  -- 卡尔迪岛黑帮系列
    1319801, 1319802, 1319803,  -- 拉姆齐岛黑帮系列
    1319901, 1319902, 1319903,  -- 斯科克岛黑帮系列
    1320001, 1320002, 1320003,  -- 巴德西岛黑帮系列
}

-- 加载技能
local function LoadSkill(skillId)
    -- 构建完整的技能ID (ClassID * 100 + SkillLevel)
    -- 例如: 1310101 -> 131010101
    local fullSkillId = skillId * 100 + 1
    local luaFileName = string.format("skill_%d", fullSkillId)
    -- 从本地config目录加载
    local luaPath = string.format("config.skill.%s", luaFileName)
    
    local success, result = pcall(require, luaPath)
    if not success then
        return nil, result
    end
    
    -- 从全局变量获取技能数据
    local globalVarName = luaFileName
    return _G[globalVarName], nil
end

-- 分析技能数据结构
local function AnalyzeSkill(skillData, skillId)
    local analysis = {
        hasDamage = false,
        hasHeal = false,
        hasBuff = false,
        hasSpell = false,
        damageCount = 0,
        healCount = 0,
        buffCount = 0,
        spellCount = 0,
        targetNum = 0,
    }
    
    if not skillData then
        return analysis
    end
    
    -- 检查 actData
    if skillData.actData then
        for _, act in ipairs(skillData.actData) do
            if act.keyFrameDatas then
                for _, kf in ipairs(act.keyFrameDatas) do
                    if kf.datatype == "DWCommon.DamageData" then
                        analysis.hasDamage = true
                        analysis.damageCount = analysis.damageCount + 1
                    elseif kf.datatype == "DWCommon.HealData" then
                        analysis.hasHeal = true
                        analysis.healCount = analysis.healCount + 1
                    elseif kf.datatype == "DWCommon.LaunchBuff" then
                        analysis.hasBuff = true
                        analysis.buffCount = analysis.buffCount + 1
                    elseif kf.datatype == "DWCommon.LaunchSpell" then
                        analysis.hasSpell = true
                        analysis.spellCount = analysis.spellCount + 1
                    end
                end
            end
        end
    end
    
    -- 检查目标数量
    if skillData.targetsSelections and skillData.targetsSelections.tSConditions then
        analysis.targetNum = skillData.targetsSelections.tSConditions.Num or 0
    end
    
    return analysis
end

-- 主测试
local stats = {
    total = #commonSkillIds,
    loaded = 0,
    failed = 0,
    withDamage = 0,
    withHeal = 0,
    withBuff = 0,
    withSpell = 0,
    singleTarget = 0,
    aoeTarget = 0,
}

local failedSkills = {}
local damageSkills = {}
local aoeSkills = {}

print(string.format("准备测试 %d 个技能...\n", stats.total))

-- 测试每个技能
for i, skillId in ipairs(commonSkillIds) do
    local skillData, err = LoadSkill(skillId)
    
    if skillData then
        stats.loaded = stats.loaded + 1
        
        local analysis = AnalyzeSkill(skillData, skillId)
        
        if analysis.hasDamage then
            stats.withDamage = stats.withDamage + 1
            table.insert(damageSkills, {id = skillId, name = skillData.Name or "Unknown"})
        end
        
        if analysis.hasHeal then
            stats.withHeal = stats.withHeal + 1
        end
        
        if analysis.hasBuff then
            stats.withBuff = stats.withBuff + 1
        end
        
        if analysis.hasSpell then
            stats.withSpell = stats.withSpell + 1
        end
        
        if analysis.targetNum > 1 then
            stats.aoeTarget = stats.aoeTarget + 1
            table.insert(aoeSkills, {id = skillId, num = analysis.targetNum})
        else
            stats.singleTarget = stats.singleTarget + 1
        end
        
        -- 每20个显示一次进度
        if i % 20 == 0 then
            print(string.format("已测试 %d/%d 个技能...", i, stats.total))
        end
    else
        -- 静默处理失败（很多技能可能不存在）
        stats.failed = stats.failed + 1
    end
end

-- 输出统计
print("\n========================================")
print("  测试结果统计")
print("========================================")

print(string.format("\n总计测试: %d 个技能ID", stats.total))
printColor(COLORS.GREEN, string.format("✓ 成功加载: %d", stats.loaded))
print(string.format("- 未找到: %d", stats.failed))

print("\n--- 技能类型统计 ---")
print(string.format("伤害技能: %d", stats.withDamage))
print(string.format("治疗技能: %d", stats.withHeal))
print(string.format("Buff技能: %d", stats.withBuff))
print(string.format("法术技能: %d", stats.withSpell))

print("\n--- 目标类型统计 ---")
print(string.format("单体攻击: %d", stats.singleTarget))
print(string.format("范围攻击: %d", stats.aoeTarget))

-- 显示部分伤害技能
if #damageSkills > 0 then
    print("\n--- 部分伤害技能示例 ---")
    for i = 1, math.min(10, #damageSkills) do
        local skill = damageSkills[i]
        print(string.format("  [%d] %s (ID: %d)", i, skill.name, skill.id))
    end
    if #damageSkills > 10 then
        print(string.format("  ... 还有 %d 个", #damageSkills - 10))
    end
end

-- 显示范围攻击技能
if #aoeSkills > 0 then
    print("\n--- 范围攻击技能 ---")
    for i = 1, math.min(10, #aoeSkills) do
        local skill = aoeSkills[i]
        print(string.format("  [%d] ID: %d, 目标数: %d", i, skill.id, skill.num))
    end
    if #aoeSkills > 10 then
        print(string.format("  ... 还有 %d 个", #aoeSkills - 10))
    end
end

-- 详细测试一个技能
print("\n========================================")
print("  详细技能示例")
print("========================================")

if #damageSkills > 0 then
    local testSkill = damageSkills[1]
    print(string.format("\n技能: %s (ID: %d)", testSkill.name, testSkill.id))
    
    local skillData = LoadSkill(testSkill.id)
    if skillData then
        print(string.format("  名称: %s", skillData.Name or "N/A"))
        print(string.format("  优先级: %d", skillData.Priorities or 0))
        print(string.format("  冷却时间: %.2f秒", skillData.CoolDownR or 0))
        
        if skillData.targetsSelections then
            local ts = skillData.targetsSelections
            print(string.format("  目标选择:"))
            print(string.format("    - castTarget: %d", ts.castTarget or 0))
            if ts.tSConditions then
                print(string.format("    - 目标数量: %d", ts.tSConditions.Num or 0))
            end
        end
        
        local analysis = AnalyzeSkill(skillData, testSkill.id)
        print(string.format("  效果统计:"))
        print(string.format("    - 伤害效果: %d", analysis.damageCount))
        print(string.format("    - 治疗效果: %d", analysis.healCount))
        print(string.format("    - Buff效果: %d", analysis.buffCount))
        print(string.format("    - 法术效果: %d", analysis.spellCount))
    end
end

print("\n========================================")
print("  测试完成")
print("========================================")
