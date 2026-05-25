local RunRewardPool = require("config.roguelike.run_reward_pool")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local BuildConstraints = require("roguelike.build_constraints")

local RoguelikeReward = {}
local EQUIPMENT_RARITY_TIER = {
    common = 1,
    rare = 2,
    boss = 3,
}

local function collectEquipmentPoolByTier(targetTier)
    local pool = {}
    for equipmentId, equipment in pairs(RunEquipmentConfig.EQUIPMENTS or {}) do
        local rarityTier = EQUIPMENT_RARITY_TIER[tostring(equipment and equipment.rarity or "common")] or 1
        if rarityTier == targetTier then
            pool[#pool + 1] = tonumber(equipmentId)
        end
    end
    table.sort(pool)
    return pool
end

local function chooseEquipmentIdByTier(targetTier)
    local pool = collectEquipmentPoolByTier(targetTier)
    if #pool <= 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

local function collectAvailableEquipmentPoolByTier(runState, targetTier)
    local pool = {}
    for equipmentId, equipment in pairs(RunEquipmentConfig.EQUIPMENTS or {}) do
        local rarityTier = EQUIPMENT_RARITY_TIER[tostring(equipment and equipment.rarity or "common")] or 1
        local canAdd = true
        if runState then
            canAdd = BuildConstraints.CanAddEquipment(runState, tonumber(equipmentId))
        end
        if rarityTier == targetTier and canAdd then
            pool[#pool + 1] = tonumber(equipmentId)
        end
    end
    table.sort(pool)
    return pool
end

local function chooseAvailableEquipmentIdByTier(runState, targetTier)
    local pool = collectAvailableEquipmentPoolByTier(runState, targetTier)
    if #pool <= 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

local function rollBattleEquipmentId(nodeType, battleProfile)
    local resolvedNodeType = tostring(nodeType or "")
    -- 设计 §2.2 新规则：
    --   battle_normal: 不再掉装备（一律 nil）。普通战只产 gold + EXP。
    --   battle_elite : 必掉 1 件装备（rare/boss tier 加权）。
    --   boss         : 必掉 boss tier 装备。
    if resolvedNodeType == "battle_normal" then
        return nil
    end
    if resolvedNodeType == "battle_elite" then
        local rarityBonus = math.max(0, tonumber(battleProfile and battleProfile.eliteBonus and battleProfile.eliteBonus.rewardRarityBonus) or 0)
        local roll = math.random()
        local rareThreshold = math.min(0.75, 0.30 + rarityBonus * 0.10)
        local bossThreshold = math.min(0.35, math.max(0, (rarityBonus - 1) * 0.10))
        if roll <= bossThreshold then
            return chooseEquipmentIdByTier(3) or chooseEquipmentIdByTier(2) or chooseEquipmentIdByTier(1)
        end
        if roll <= (bossThreshold + rareThreshold) then
            return chooseEquipmentIdByTier(2) or chooseEquipmentIdByTier(1)
        end
        return chooseEquipmentIdByTier(1)
    end
    if resolvedNodeType == "boss" then
        return chooseEquipmentIdByTier(3) or chooseEquipmentIdByTier(2) or chooseEquipmentIdByTier(1)
    end
    return nil
end

local BLESSING_RARITY_TIER = { common = 1, rare = 2, boss = 3 }

local function collectBlessingPoolByTier(targetTier)
    local pool = {}
    for blessingId, blessing in pairs(RunBlessingConfig.BLESSINGS or {}) do
        local rarityTier = BLESSING_RARITY_TIER[tostring(blessing and blessing.rarity or "common")] or 1
        if rarityTier == targetTier then
            pool[#pool + 1] = tonumber(blessingId)
        end
    end
    table.sort(pool)
    return pool
end

local function chooseBlessingIdByTier(targetTier)
    local pool = collectBlessingPoolByTier(targetTier)
    if #pool <= 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

local function collectAvailableBlessingPoolByTier(runState, targetTier)
    local pool = {}
    for blessingId, blessing in pairs(RunBlessingConfig.BLESSINGS or {}) do
        local rarityTier = BLESSING_RARITY_TIER[tostring(blessing and blessing.rarity or "common")] or 1
        local canAdd = true
        if runState then
            canAdd = BuildConstraints.CanAddBlessing(runState, tonumber(blessingId))
        end
        if rarityTier == targetTier and canAdd then
            pool[#pool + 1] = tonumber(blessingId)
        end
    end
    table.sort(pool)
    return pool
end

local function chooseAvailableBlessingIdByTier(runState, targetTier)
    local pool = collectAvailableBlessingPoolByTier(runState, targetTier)
    if #pool <= 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

-- 设计 §2.2 新规则：
--   battle_normal: 不掉祝福。
--   battle_elite : 50% 概率掉祝福（rare 或 common）。
--   boss         : 必掉 1 个 boss tier 祝福（fallback rare）。
local function rollBattleBlessingId(nodeType, battleProfile)
    local resolvedNodeType = tostring(nodeType or "")
    if resolvedNodeType == "battle_elite" then
        if math.random() > 0.5 then
            return nil
        end
        local rareChance = 0.40
        if math.random() <= rareChance then
            return chooseBlessingIdByTier(2) or chooseBlessingIdByTier(1)
        end
        return chooseBlessingIdByTier(1)
    end
    if resolvedNodeType == "boss" then
        return chooseBlessingIdByTier(3) or chooseBlessingIdByTier(2) or chooseBlessingIdByTier(1)
    end
    return nil
end

local function weightedPick(entries, taken)
    local total = 0
    for index, entry in ipairs(entries or {}) do
        if not taken[index] then
            total = total + math.max(0, tonumber(entry.weight) or 0)
        end
    end
    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    local cursor = 0
    for index, entry in ipairs(entries or {}) do
        if not taken[index] then
            cursor = cursor + math.max(0, tonumber(entry.weight) or 0)
            if roll <= cursor then
                return index, entry
            end
        end
    end

    return nil
end

local function buildLabel(entry)
    if entry.rewardType == "gold" then
        return string.format("金币 +%d", entry.value or 0)
    end
    if entry.rewardType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(entry.refId)
        return equipment and equipment.name or ("装备 " .. tostring(entry.refId))
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.name or ("祝福 " .. tostring(entry.refId))
    end
    return tostring(entry.rewardType or "reward")
end

local function buildDescription(entry)
    if entry.rewardType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(entry.refId)
        return equipment and equipment.code or ""
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.description or ""
    end
    return ""
end

local function buildRarity(entry)
    if entry.rewardType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(entry.refId)
        return equipment and equipment.rarity or "common"
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.rarity or "common"
    end
    return "common"
end

local function buildRewardOption(entry)
    return {
        rewardType = entry.rewardType,
        refId = entry.refId,
        value = entry.value,
        label = buildLabel(entry),
        description = buildDescription(entry),
        rarity = buildRarity(entry),
    }
end

local function buildChestGoldValue(floorDepth)
    local depth = math.max(1, math.floor(tonumber(floorDepth) or 1))
    return 35 + (depth - 1) * 12
end

local function chooseChestEquipmentId(runState, floorDepth)
    local depth = math.max(1, math.floor(tonumber(floorDepth) or 1))
    local rareChance = math.min(0.60, 0.18 + (depth - 1) * 0.08)
    if math.random() <= rareChance then
        return chooseAvailableEquipmentIdByTier(runState, 2)
            or chooseAvailableEquipmentIdByTier(runState, 1)
    end
    return chooseAvailableEquipmentIdByTier(runState, 1)
        or chooseAvailableEquipmentIdByTier(runState, 2)
end

local function pickChestRewardEntry(runState, floorDepth)
    local depth = math.max(1, math.floor(tonumber(floorDepth) or 1))
    local entries = {
        {
            rewardType = "gold",
            value = buildChestGoldValue(depth),
            weight = math.max(18, 36 - depth * 2),
        },
    }

    local equipmentId = chooseChestEquipmentId(runState, depth)
    if equipmentId then
        entries[#entries + 1] = {
            rewardType = "equipment",
            refId = equipmentId,
            weight = 42,
        }
    end

    local _, entry = weightedPick(entries, {})
    return entry
end

-- ==========================================================================
-- 阶段 3.1：职业卡 / 进阶 / promotion_pending_target 全部废弃。
-- 战斗胜利的升级三选一改由 roguelike/feat_picker.lua 驱动。
-- ==========================================================================

function RoguelikeReward.RollBattleEquipmentDrop(nodeType, battleProfile)
    return rollBattleEquipmentId(nodeType, battleProfile)
end

-- 战斗祝福掉落 API（精英战 50% 概率，boss 必掉 boss tier）
function RoguelikeReward.RollBattleBlessingDrop(nodeType, battleProfile)
    return rollBattleBlessingId(nodeType, battleProfile)
end

function RoguelikeReward.GenerateRewardState(groupId)
    local group = RunRewardPool.GetGroup(groupId)
    if not group then
        return nil
    end

    local options = {}
    local taken = {}
    local required = ((group.constraints or {}).requireAtLeastOne) or {}

    for _, rewardType in ipairs(required) do
        for index, entry in ipairs(group.options or {}) do
            if entry.rewardType == rewardType and not taken[index] then
                taken[index] = true
                options[#options + 1] = buildRewardOption(entry)
                break
            end
        end
    end

    while #options < (group.optionCount or 1) do
        local pickedIndex, entry = weightedPick(group.options, taken)
        if not pickedIndex or not entry then
            break
        end
        taken[pickedIndex] = true
        options[#options + 1] = buildRewardOption(entry)
    end

    return {
        groupId = groupId,
        kind = group.kind,
        options = options,
    }
end

function RoguelikeReward.GenerateChestRewardState(runState, chestContext)
    local floorDepth = tonumber(chestContext and chestContext.floorDepth)
        or tonumber(runState and runState.dungeonState and runState.dungeonState.currentFloorDepth)
        or 1
    local entry = pickChestRewardEntry(runState, floorDepth) or {
        rewardType = "gold",
        value = buildChestGoldValue(floorDepth),
    }
    return {
        groupId = 0,
        kind = "chest",
        options = { buildRewardOption(entry) },
    }
end

function RoguelikeReward.ApplyReward(runState, rewardState, index)
    local option = rewardState and rewardState.options and rewardState.options[index] or nil
    if not option then
        return false, "invalid_reward"
    end

    local prefix = rewardState and rewardState.kind == "chest" and "开启宝箱：" or ""

    if option.rewardType == "gold" then
        runState.gold = (runState.gold or 0) + (option.value or 0)
        runState.lastActionMessage = prefix .. option.label
    elseif option.rewardType == "equipment" then
        local ok, reason = BuildConstraints.AddEquipment(runState, option.refId)
        if not ok then
            return false, reason
        end
        runState.lastActionMessage = prefix .. option.label
    elseif option.rewardType == "blessing" then
        local ok, reason = BuildConstraints.AddBlessing(runState, option.refId)
        if not ok then
            return false, reason
        end
        runState.lastActionMessage = prefix .. option.label
    else
        return false, "unsupported_reward"
    end

    return true
end

return RoguelikeReward
