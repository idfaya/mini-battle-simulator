-- 战斗节点掉落分布测试
-- 设计文档：design/character_progression_design.md §2 / dungeon_design.md §5
-- 验证：
--   1) battle_normal: 装备 0 / 祝福 0（统计 200 次必须全 0）。
--   2) battle_elite: 装备必掉（>=95% 命中率）；祝福约 50% 命中率（±15% 容忍）。
--   3) boss: 装备 + 祝福均必掉 boss tier（统计 50 次必须全部命中且 tier == 3）。
--   4) BuildConstraints: 同 mutuallyExclusiveGroup 第二件被拒；祝福总数封顶 6。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local RoguelikeReward = require("roguelike.roguelike_reward")
local BuildConstraints = require("roguelike.build_constraints")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local function profileForBattle()
    return { eliteBonus = { rewardRarityBonus = 1, equipmentRoll = 1 } }
end

-- 用例 1：普通战完全不掉装备/祝福
math.randomseed(20260520)
local TRIALS = 200
do
    local equipmentHits = 0
    local blessingHits = 0
    for _ = 1, TRIALS do
        if RoguelikeReward.RollBattleEquipmentDrop("battle_normal", profileForBattle()) then
            equipmentHits = equipmentHits + 1
        end
        if RoguelikeReward.RollBattleBlessingDrop("battle_normal", profileForBattle()) then
            blessingHits = blessingHits + 1
        end
    end
    assert_true(equipmentHits == 0, string.format("普通战不应掉装备，实际命中 %d/%d", equipmentHits, TRIALS))
    assert_true(blessingHits == 0, string.format("普通战不应掉祝福，实际命中 %d/%d", blessingHits, TRIALS))
end

-- 用例 2：精英战装备必掉、祝福约 50%
do
    local equipmentHits = 0
    local blessingHits = 0
    for _ = 1, TRIALS do
        if RoguelikeReward.RollBattleEquipmentDrop("battle_elite", profileForBattle()) then
            equipmentHits = equipmentHits + 1
        end
        if RoguelikeReward.RollBattleBlessingDrop("battle_elite", profileForBattle()) then
            blessingHits = blessingHits + 1
        end
    end
    -- 装备：必掉
    assert_true(equipmentHits >= TRIALS * 0.95,
        string.format("精英战装备命中率应 >= 95%%，实际 %d/%d", equipmentHits, TRIALS))
    -- 祝福：50% ±15%
    local blessingRate = blessingHits / TRIALS
    assert_true(blessingRate >= 0.35 and blessingRate <= 0.65,
        string.format("精英战祝福命中率应在 35%%~65%% 之间，实际 %.2f%%", blessingRate * 100))
end

-- 用例 3：boss 节点装备 + 祝福均必掉，且优先 boss tier
do
    local BOSS_TRIALS = 50
    local equipmentHits = 0
    local blessingHits = 0
    local equipmentBossTier = 0
    local blessingBossTier = 0
    for _ = 1, BOSS_TRIALS do
        local equipmentId = RoguelikeReward.RollBattleEquipmentDrop("boss", profileForBattle())
        if equipmentId then
            equipmentHits = equipmentHits + 1
            local entry = RunEquipmentConfig.GetEquipment(equipmentId)
            if entry and entry.rarity == "boss" then
                equipmentBossTier = equipmentBossTier + 1
            end
        end
        local blessingId = RoguelikeReward.RollBattleBlessingDrop("boss", profileForBattle())
        if blessingId then
            blessingHits = blessingHits + 1
            local entry = RunBlessingConfig.GetBlessing(blessingId)
            if entry and entry.rarity == "boss" then
                blessingBossTier = blessingBossTier + 1
            end
        end
    end
    assert_true(equipmentHits == BOSS_TRIALS,
        string.format("boss 装备应必掉，实际 %d/%d", equipmentHits, BOSS_TRIALS))
    assert_true(blessingHits == BOSS_TRIALS,
        string.format("boss 祝福应必掉，实际 %d/%d", blessingHits, BOSS_TRIALS))
    assert_true(equipmentBossTier == BOSS_TRIALS,
        string.format("boss 装备 tier 应全部为 boss，实际 %d/%d", equipmentBossTier, BOSS_TRIALS))
    assert_true(blessingBossTier == BOSS_TRIALS,
        string.format("boss 祝福 tier 应全部为 boss，实际 %d/%d", blessingBossTier, BOSS_TRIALS))
end

-- 用例 4：BuildConstraints 互斥组与上限
do
    local runState = { equipmentIds = {}, blessingIds = {} }
    -- 装备 +1 长剑（101002，group=weapon）成功
    local ok = BuildConstraints.AddEquipment(runState, 101002)
    assert_true(ok, "应允许加入第一件装备 101002")
    -- 同 weapon group 的 101005（+1 短弓）应被拒
    local ok2, reason = BuildConstraints.AddEquipment(runState, 101005)
    assert_true(not ok2, "应拒绝同 weapon 组的第二件装备")
    assert_true(reason == "exclusive_group_occupied", string.format("拒绝原因应为 exclusive_group_occupied，实际 %s", tostring(reason)))
    -- 同 ID 重复入库应被拒
    local ok3, reason3 = BuildConstraints.AddEquipment(runState, 101002)
    assert_true(not ok3, "应拒绝重复同 ID 装备")
    assert_true(reason3 == "duplicate_equipment", string.format("拒绝原因应为 duplicate_equipment，实际 %s", tostring(reason3)))
end

-- 用例 5：祝福总数上限 6
do
    local runState = { equipmentIds = {}, blessingIds = {} }
    -- 把 6 件 mutex 互不冲突的祝福直接塞进去（绕过 AddBlessing 的 tag/group 累加，仅锁定 total_limit）
    runState.blessingIds = { 101001, 101002, 101003, 101004, 101005, 101006 }
    -- 第 7 件传入真实存在且尚未入库的 ID（101007），保证不会先命中 blessing_not_found / duplicate
    local ok, reason = BuildConstraints.AddBlessing(runState, 101007)
    assert_true(not ok, "祝福总数 6 上限：第 7 件应被拒")
    -- 严格锁定 blessing_total_limit；blessing_not_found 不再视为可接受结果
    assert_true(reason == "blessing_total_limit",
        string.format("拒绝原因应为 blessing_total_limit，实际 %s", tostring(reason)))
end

print("[OK] test_battle_loot_distribution")
