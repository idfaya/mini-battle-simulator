local RunRewardPool = require("config.roguelike.run_reward_pool")
local RunCardRewardPool = require("config.roguelike.run_card_reward_pool")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local BuildConstraints = require("roguelike.build_constraints")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local HeroData = require("config.hero_data")
local CardBattle = require("roguelike.card_battle")

local RoguelikeReward = {}

local function allocateRosterId(runState)
    local nextId = tonumber(runState.nextRosterId) or 1
    runState.nextRosterId = nextId + 1
    return nextId
end

local function recruitHero(runState, classId)
    local resolvedClassId = tonumber(classId) or 0
    if resolvedClassId <= 0 then
        return false, "invalid_recruit_class"
    end
    local teamState = RoguelikeRoster.GetTeamUnitCount(runState) < (tonumber(runState.maxHeroCount) or 0)
        and "active"
        or "bench"

    local rosterId = allocateRosterId(runState)
    local unit = HeroData.CreateClassUnit(resolvedClassId, {
        rosterId = rosterId,
        unitId = string.format("class_unit_%d_%d", resolvedClassId, rosterId),
        level = tonumber(runState.partyLevel) or 1,
        teamState = teamState,
        source = "recruit",
        ultimateCharges = 1,
        ultimateChargesMax = 1,
        skillCooldowns = {},
    })
    if not unit then
        return false, "recruit_create_failed"
    end
    RoguelikeRoster.AddOwnedUnit(runState, unit, teamState)
    return true, unit
end

local SLOT_LABELS = {
    weapon = "武器",
    armor = "护甲",
    shield = "盾牌",
    focus = "法器",
    accessory = "饰品",
}

local CLASS_LABELS = {
    [1] = "法师",
    [2] = "战士",
    [3] = "盗贼",
    [4] = "圣武士",
    [5] = "游侠",
    [6] = "牧师",
    [7] = "野蛮人",
    [8] = "术士",
    [9] = "魔契师",
    [10] = "武僧",
}
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

-- 设计 §2.2：精英房不再掉祝福；Boss 仍必掉 boss tier 祝福。
local function rollBattleBlessingId(nodeType, battleProfile)
    local resolvedNodeType = tostring(nodeType or "")
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

local function describeEquipmentEffect(equipment)
    local effect = equipment and equipment.effectType
    local params = equipment and equipment.params or {}
    local parts = {}
    local function push(text)
        if text and text ~= "" then
            parts[#parts + 1] = text
        end
    end
    if effect == "martial_weapon" or effect == "ranged_weapon" then
        if params.hitDelta then
            push(string.format("命中 +%d", tonumber(params.hitDelta) or 0))
        end
        if params.weaponDamageBonus then
            push(string.format("武器伤害 +%d", tonumber(params.weaponDamageBonus) or 0))
        end
    elseif effect == "armor_ac" or effect == "shield_ac" then
        if params.acDelta then
            push(string.format("AC +%d", tonumber(params.acDelta) or 0))
        end
    elseif effect == "spell_focus" or effect == "holy_symbol" then
        if params.spellDCDelta then
            push(string.format("法术 DC +%d", tonumber(params.spellDCDelta) or 0))
        end
    elseif effect == "saving_throw_charm" then
        if params.acDelta then
            push(string.format("AC +%d", tonumber(params.acDelta) or 0))
        end
        if params.saveDelta then
            push(string.format("豁免 +%d", tonumber(params.saveDelta) or 0))
        end
    end
    return table.concat(parts, " · ")
end

local function describeEquipmentClasses(equipment)
    local params = equipment and equipment.params or {}
    local classIds = params.classIds or {}
    if #classIds == 0 then
        return ""
    end
    local names = {}
    for _, classId in ipairs(classIds) do
        names[#names + 1] = CLASS_LABELS[tonumber(classId) or 0] or ("职业" .. tostring(classId))
    end
    return table.concat(names, "/")
end

local function buildEquipmentPreview(equipmentId)
    local equipment = RunEquipmentConfig.GetEquipment(tonumber(equipmentId))
    if not equipment then
        return nil
    end
    return {
        equipmentId = tonumber(equipmentId),
        name = equipment.name or ("装备 " .. tostring(equipmentId)),
        rarity = equipment.rarity or "common",
        code = equipment.code or "",
        slot = equipment.slot,
        slotLabel = equipment.slot and SLOT_LABELS[equipment.slot] or nil,
        effectType = equipment.effectType,
        effectDescription = describeEquipmentEffect(equipment),
        classScope = describeEquipmentClasses(equipment),
    }
end

local function buildDescription(entry)
    if entry.rewardType == "equipment" then
        local preview = buildEquipmentPreview(entry.refId)
        if preview and preview.effectDescription ~= "" then
            return preview.effectDescription
        end
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
    local option = {
        rewardType = entry.rewardType,
        refId = entry.refId,
        value = entry.value,
        label = buildLabel(entry),
        description = buildDescription(entry),
        rarity = buildRarity(entry),
    }
    if entry.rewardType == "equipment" then
        option.equipmentPreview = buildEquipmentPreview(entry.refId)
    end
    return option
end

local function buildCardRewardOption(entry)
    return {
        rewardType = entry.rewardType,
        cardUid = entry.cardUid,
        rewardCardId = entry.rewardCardId,
        skillId = entry.skillId,
        ownerName = entry.ownerName,
        label = entry.label,
        description = entry.description or "",
        rarity = entry.rarity or "common",
    }
end

local function collectAvailableRewardCardEntries(runState)
    local result = {}
    for _, entry in ipairs(RunCardRewardPool.GetAllCards()) do
        local ok, ownerOrReason = CardBattle.CanAddRewardSkillCard(runState, entry)
        if ok then
            local copy = {
                id = entry.id,
                skillId = entry.skillId,
                classId = entry.classId,
                ownerPolicy = entry.ownerPolicy,
                rarity = entry.rarity or "common",
                weight = math.max(0, tonumber(entry.weight) or 0),
                cost = entry.cost,
                name = entry.name,
                description = entry.description,
                ownerName = ownerOrReason and ownerOrReason.name or nil,
            }
            if copy.weight > 0 then
                result[#result + 1] = copy
            end
        end
    end
    table.sort(result, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)
    return result
end

local function collectCardRewardCandidates(runState)
    local library = CardBattle.SyncLibrary(runState)
    local result = {}
    for _, card in ipairs(library and library.cards or {}) do
        if card.removed ~= true
            and card.type ~= "status"
            and card.type ~= "curse"
            and card.disabled ~= true then
            result[#result + 1] = card
        end
    end
    table.sort(result, function(a, b)
        return tostring(a.uid or "") < tostring(b.uid or "")
    end)
    return result
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

-- 战斗祝福掉落 API（Boss 必掉 boss tier；精英房不掉祝福）
function RoguelikeReward.RollBattleBlessingDrop(nodeType, battleProfile)
    return rollBattleBlessingId(nodeType, battleProfile)
end

--- 精英战 / 宝箱共用：单件装备 rewardState（kind=chest，Web 走开箱 UI）。
---@param equipmentId integer
---@param opts table|nil { source: string|nil }
function RoguelikeReward.GenerateEquipmentRewardState(equipmentId, opts)
    opts = opts or {}
    local id = tonumber(equipmentId)
    if not id then
        return nil
    end
    return {
        groupId = 0,
        kind = "chest",
        source = tostring(opts.source or "chest"),
        options = { buildRewardOption({ rewardType = "equipment", refId = id }) },
    }
end

--- 精英战胜利后延迟展示：roll 装备并生成 rewardState（不入库，等 ChooseReward）。
---@param runState table|nil
---@param nodeType string|nil
---@param battleProfile table|nil
function RoguelikeReward.PrepareEliteEquipmentReward(runState, nodeType, battleProfile)
    if tostring(nodeType or "") ~= "battle_elite" then
        return nil
    end
    local equipmentId = rollBattleEquipmentId(nodeType, battleProfile)
    if not equipmentId then
        return nil
    end
    if runState and not BuildConstraints.CanAddEquipment(runState, equipmentId) then
        return nil
    end
    return RoguelikeReward.GenerateEquipmentRewardState(equipmentId, { source = "elite_victory" })
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

function RoguelikeReward.GenerateCardRewardState(runState, opts)
    opts = opts or {}
    local candidates = collectCardRewardCandidates(runState)
    local rewardCardEntries = collectAvailableRewardCardEntries(runState)
    if #candidates <= 0 and #rewardCardEntries <= 0 then
        return nil
    end

    local options = {}
    local takenRewardCards = {}
    local maxGainCards = math.min(2, #rewardCardEntries)
    for _ = 1, maxGainCards do
        local pickedIndex, entry = weightedPick(rewardCardEntries, takenRewardCards)
        if not pickedIndex or not entry then
            break
        end
        takenRewardCards[pickedIndex] = true
        options[#options + 1] = buildCardRewardOption({
            rewardType = "gain_card",
            rewardCardId = entry.id,
            skillId = entry.skillId,
            ownerName = entry.ownerName,
            label = "获得：" .. tostring(entry.name or "Card"),
            description = entry.description or string.format("将 1 张 %s 加入永久牌库。", tostring(entry.name or "Card")),
            rarity = entry.rarity or "common",
        })
    end

    if #options <= 0 then
        local maxCopies = math.min(2, #candidates)
        for index = 1, maxCopies do
            local card = candidates[index]
            options[#options + 1] = buildCardRewardOption({
                rewardType = "copy_card",
                cardUid = card.uid,
                label = "复制：" .. tostring(card.name or "Card"),
                description = string.format("将 1 张 %s 的副本加入永久牌库。", tostring(card.name or "Card")),
                rarity = card.upgraded == true and "rare" or "common",
            })
        end
    end

    if #candidates > 0 then
        local greedCard = candidates[math.min(#candidates, #options + 1)] or candidates[1]
        options[#options + 1] = buildCardRewardOption({
            rewardType = "copy_card_curse",
            cardUid = greedCard.uid,
            label = "贪婪复制：" .. tostring(greedCard.name or "Card"),
            description = "复制 1 张 Card，但加入 1 张永久诅咒：疑惧。",
            rarity = "rare",
        })
    end

    options[#options + 1] = buildCardRewardOption({
        rewardType = "skip_card",
        label = "跳过",
        description = "不改变永久牌库。",
        rarity = "common",
    })

    return {
        groupId = 0,
        kind = "card_reward",
        source = tostring(opts.source or "battle_victory"),
        options = options,
    }
end

function RoguelikeReward.ApplyReward(runState, rewardState, index)
    local option = rewardState and rewardState.options and rewardState.options[index] or nil
    if not option then
        return false, "invalid_reward"
    end

    local prefix = ""
    if rewardState and rewardState.kind == "chest" then
        if rewardState.source == "elite_victory" then
            prefix = "精英战利品："
        else
            prefix = "开启宝箱："
        end
    end

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
    elseif option.rewardType == "recruit" then
        local ok, result = recruitHero(runState, option.classId or option.refId)
        if not ok then
            return false, result
        end
        runState.lastActionMessage = "招募队员：" .. tostring(option.label or result.name or "新队员")
    elseif option.rewardType == "copy_card" then
        local ok, result = CardBattle.CloneLibraryCard(runState, option.cardUid)
        if not ok then
            return false, result
        end
        runState.lastActionMessage = "卡牌奖励：" .. tostring(result.cardName or option.label or "复制 Card")
    elseif option.rewardType == "gain_card" then
        local entry = RunCardRewardPool.GetCard(option.rewardCardId)
        local ok, result = CardBattle.AddRewardSkillCard(runState, entry)
        if not ok then
            return false, result
        end
        runState.lastActionMessage = "卡牌奖励：" .. tostring(result.cardName or option.label or "获得 Card")
    elseif option.rewardType == "copy_card_curse" then
        local ok, result = CardBattle.CloneLibraryCard(runState, option.cardUid)
        if not ok then
            return false, result
        end
        local curseOk, curseResult = CardBattle.AddCurseCard(runState, "doubt")
        if not curseOk then
            return false, curseResult
        end
        runState.lastActionMessage = string.format("贪婪奖励：复制 %s，并加入疑惧", tostring(result.cardName or "Card"))
    elseif option.rewardType == "skip_card" then
        runState.lastActionMessage = "跳过卡牌奖励"
    else
        return false, "unsupported_reward"
    end

    return true
end

return RoguelikeReward
