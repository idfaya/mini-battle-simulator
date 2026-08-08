local RoguelikeMap = require("roguelike.roguelike_map")
local DungeonGenerator = require("roguelike.dungeon_generator")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local RoguelikeTrinket = require("roguelike.trinket")
local Ability5e = require("modules.ability_5e")
local RoguelikeBattleBridge = require("roguelike.roguelike_battle_bridge")
local CardBattle = require("roguelike.card_battle")

local RoguelikeSnapshot = {}
-- 注：等级曲线统一来自 config.roguelike.level_curve；本文件不再维护本地阈值表。

local function getNextLevelExp(hero)
    -- 个人下一级 EXP 已不再有意义（队伍共享 partyExp），保留 0 占位以兼容旧客户端字段。
    return 0
end

local function shallowCopyArray(input)
    local result = {}
    for i, v in ipairs(input or {}) do
        result[i] = v
    end
    return result
end

local function addUnique(list, value)
    if not value or value == "" then
        return
    end
    for _, existing in ipairs(list) do
        if existing == value then
            return
        end
    end
    list[#list + 1] = value
end

local function buildFeatSummary(hero)
    local result = {}
    local classId = tonumber(hero and hero.classId) or 0
    local level = tonumber(hero and hero.level) or 1
    -- §5 单轨：Lv1 自动 feat 来自 lv1FeatIds。
    for _, featId in ipairs(ClassBuildProgression.GetLv1FeatIds(classId)) do
        local feat = FeatBuildConfig.GetFeat(featId)
        addUnique(result, feat and feat.name or nil)
    end
    for _, featId in ipairs(hero and hero.feats or {}) do
        local feat = FeatBuildConfig.GetFeat(featId)
        addUnique(result, feat and feat.name or nil)
    end
    return result
end

local function serializeTeam(roster, modifiers)
    local result = {}
    for _, hero in ipairs(roster or {}) do
        local str = tonumber(hero.str)
        local dex = tonumber(hero.dex)
        local con = tonumber(hero.con)
        local intl = tonumber(hero.int)
        local wis = tonumber(hero.wis)
        local cha = tonumber(hero.cha)
        local weaponDice = ClassBuildProgression.GetWeaponDice(hero.classId)

        -- 把 Run 内装备 / 祝福 / Trinket 的属性 delta 叠加到面板展示字段，
        -- 让队伍信息面板看到的命中 / AC / 法术 DC / 豁免与战斗实际生效一致。
        local classKey = tonumber(hero.classId) or 0
        local hitDelta = 0
        local acDelta = 0
        local spellDCDelta = 0
        local saveDelta = 0
        if modifiers then
            hitDelta = tonumber(modifiers.hitDeltaByClass and modifiers.hitDeltaByClass[classKey]) or 0
            acDelta = tonumber(modifiers.acDeltaByClass and modifiers.acDeltaByClass[classKey]) or 0
            spellDCDelta = tonumber(modifiers.spellDCDeltaByClass and modifiers.spellDCDeltaByClass[classKey]) or 0
            saveDelta = tonumber(modifiers.saveDeltaByClass and modifiers.saveDeltaByClass[classKey]) or 0
        end
        local baseHit = tonumber(hero.hit)
        local baseAc = tonumber(hero.ac)
        local baseSpellAttack = tonumber(hero.spellAttack)
        local baseSpellDC = tonumber(hero.spellDC)
        local baseSaveFort = tonumber(hero.saveCon)
        local baseSaveRef = tonumber(hero.saveDex)
        local baseSaveWill = tonumber(hero.saveWis)

        local function addDelta(base, delta)
            if base == nil then
                return nil
            end
            return math.max(0, math.floor(base + delta))
        end

        result[#result + 1] = {
            rosterId = hero.rosterId,
            unitId = hero.unitId,
            heroId = hero.heroId,
            name = hero.name,
            classId = hero.classId,
            className = hero.className,
            characterGroup = hero.characterGroup,
            level = hero.level,
            nextLevelExp = getNextLevelExp(hero),
            star = hero.star,
            hp = hero.currentHp,
            maxHp = hero.maxHp,
            isDead = hero.isDead == true,
            teamState = hero.teamState,
            promotionStage = hero.promotionStage,
            skillPackageId = hero.skillPackageId,
            ultimateCharges = tonumber(hero.ultimateCharges) or tonumber(hero.ultimateChargesMax) or 1,
            ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1,
            buildSummary = buildFeatSummary(hero),
            str = str,
            dex = dex,
            con = con,
            int = intl,
            wis = wis,
            cha = cha,
            strMod = str and Ability5e.GetAbilityMod(str) or nil,
            dexMod = dex and Ability5e.GetAbilityMod(dex) or nil,
            conMod = con and Ability5e.GetAbilityMod(con) or nil,
            intMod = intl and Ability5e.GetAbilityMod(intl) or nil,
            wisMod = wis and Ability5e.GetAbilityMod(wis) or nil,
            chaMod = cha and Ability5e.GetAbilityMod(cha) or nil,
            -- 含装备/祝福加成的最终面板值（与战斗内实际生效保持一致）。
            ac = addDelta(baseAc, acDelta),
            hit = addDelta(baseHit, hitDelta),
            spellAttack = addDelta(baseSpellAttack, hitDelta),
            spellDC = addDelta(baseSpellDC, spellDCDelta),
            saveCon = addDelta(baseSaveFort, saveDelta),
            saveDex = addDelta(baseSaveRef, saveDelta),
            saveWis = addDelta(baseSaveWill, saveDelta),
            -- 拆分原始值与加成，前端可显示「14 (+1)」之类的明细。
            acBase = baseAc,
            hitBase = baseHit,
            spellAttackBase = baseSpellAttack,
            spellDCBase = baseSpellDC,
            saveConBase = baseSaveFort,
            saveDexBase = baseSaveRef,
            saveWisBase = baseSaveWill,
            acBonus = acDelta,
            hitBonus = hitDelta,
            spellAttackBonus = hitDelta,
            spellDCBonus = spellDCDelta,
            saveConBonus = saveDelta,
            saveDexBonus = saveDelta,
            saveWisBonus = saveDelta,
            weaponDice = weaponDice,
        }
    end
    return result
end

local SLOT_LABELS = {
    weapon = "武器",
    armor = "护甲",
    shield = "盾牌",
    focus = "法器",
    accessory = "饰品",
}

local CLASS_LABELS = {
    [1] = "盗贼",
    [2] = "战士",
    [3] = "武僧",
    [4] = "圣武士",
    [5] = "游侠",
    [6] = "牧师",
    [7] = "法师",
    [8] = "术士",
    [9] = "契术士",
    [10] = "蛮族",
}

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

local function serializeEquipments(equipmentIds)
    local result = {}
    for _, equipmentId in ipairs(equipmentIds or {}) do
        local equipment = RunEquipmentConfig.GetEquipment(equipmentId)
        result[#result + 1] = {
            equipmentId = equipmentId,
            name = equipment and equipment.name or ("装备 " .. tostring(equipmentId)),
            rarity = equipment and equipment.rarity or "common",
            code = equipment and equipment.code or "",
            slot = equipment and equipment.slot or nil,
            slotLabel = equipment and SLOT_LABELS[equipment.slot] or nil,
            effectType = equipment and equipment.effectType or nil,
            effectDescription = describeEquipmentEffect(equipment),
            classScope = describeEquipmentClasses(equipment),
        }
    end
    return result
end

local function serializeBlessings(blessingIds)
    local result = {}
    for _, blessingId in ipairs(blessingIds or {}) do
        local blessing = RunBlessingConfig.GetBlessing(blessingId)
        result[#result + 1] = {
            blessingId = blessingId,
            name = blessing and blessing.name or ("祝福 " .. tostring(blessingId)),
            rarity = blessing and blessing.rarity or "common",
            code = blessing and blessing.code or "",
            description = blessing and blessing.description or "",
        }
    end
    return result
end

local function serializeMap(runState)
    local chapterMap = RoguelikeMap.BuildChapterMap(runState.chapterId, runState.dungeonState)
    if not chapterMap then
        return nil
    end

    local visited = runState.visitedNodeIds or {}
    local available = {}
    for _, nodeId in ipairs(runState.availableNextNodeIds or {}) do
        available[nodeId] = true
    end
    local edges = {}

    local nodes = {}
    for _, node in ipairs(chapterMap.nodes or {}) do
        -- revealed 仅基于"已踏足"——当前房 + 已访问。可选邻居只是 selectable，
        -- 仍处于迷雾中（前端按 selectable 高亮虚线框，但不展示房间类型/标题）。
        local visible = visited[node.id] == true or runState.currentNodeId == node.id
        local titleVisible = visible
        local isHiddenFloor = (tonumber(node.floor) or 0) == DungeonGenerator.HIDDEN_FLOOR_DEPTH
        nodes[#nodes + 1] = {
            id = node.id,
            floor = node.floor,
            lane = node.lane,
            gridX = node.gridX,
            gridY = node.gridY,
            floorGridW = node.floorGridW,
            floorGridH = node.floorGridH,
            nodeType = node.nodeType,
            isHiddenFloor = isHiddenFloor,
            title = titleVisible and node.title or "",
            visited = visited[node.id] == true,
            current = runState.currentNodeId == node.id,
            selectable = available[node.id] == true,
            revealed = visible,
            titleVisible = titleVisible,
            nextNodeIds = shallowCopyArray(node.nextNodeIds),
        }
        for _, nextNodeId in ipairs(node.nextNodeIds or {}) do
            edges[#edges + 1] = {
                fromNodeId = node.id,
                toNodeId = nextNodeId,
            }
        end
    end

    return {
        chapterId = chapterMap.chapterId,
        floorCount = chapterMap.floorCount,
        nodes = nodes,
        edges = edges,
        startNodeId = chapterMap.startNodeId,
        bossNodeId = chapterMap.bossNodeId,
    }
end

local function serializeEventState(eventState)
    if type(eventState) ~= "table" then
        return nil
    end
    local resultState = nil
    if type(eventState.result) == "table" then
        local details = {}
        for i, text in ipairs(eventState.result.details or {}) do
            details[i] = text
        end
        resultState = {
            title = eventState.result.title or "",
            optionLabel = eventState.result.optionLabel or "",
            summary = eventState.result.summary or "",
            details = details,
            actionLabel = eventState.result.actionLabel or "继续前进",
        }
    end
    return {
        id = eventState.id,
        chapterId = eventState.chapterId,
        code = eventState.code,
        title = eventState.title,
        kind = eventState.kind,
        options = shallowCopyArray(eventState.options),
        lastSkillCheck = eventState.lastSkillCheck,
        result = resultState,
    }
end

function RoguelikeSnapshot.Build(runState, battleSnapshot, opts)
    -- Lite 模式：用于战斗段每帧的 tick 回包，跳过 map / roster / 装备 / 事件等
    -- 与战斗无关的元数据序列化，前端在战斗中直接复用上一帧的 full snapshot 字段。
    if opts and opts.lite then
        return {
            phase = runState.phase,
            currentNodeId = runState.currentNodeId,
            lastActionMessage = runState.lastActionMessage or "",
            battleSnapshot = battleSnapshot,
            cardLibrary = CardBattle.SerializeLibrary(runState.cardLibrary),
            cardBattle = CardBattle.Serialize(runState.cardBattle),
            lite = true,
        }
    end

    local previewModifiers = RoguelikeBattleBridge.BuildBattleModifiers(runState, nil)
    local ownedUnits = serializeTeam(RoguelikeRoster.GetOwnedUnits(runState), previewModifiers)
    local teamRoster = serializeTeam(RoguelikeRoster.GetTeamUnits(runState), previewModifiers)
    local benchRoster = serializeTeam(RoguelikeRoster.GetBenchUnits(runState), previewModifiers)
    return {
        phase = runState.phase,
        chapterId = runState.chapterId,
        currentFloorDepth = runState.dungeonState and runState.dungeonState.currentFloorDepth or nil,
        hiddenFloorInjected = runState.hiddenFloorInjected == true,
        hiddenFloorActive = runState.hiddenFloorActive == true,
        hiddenFloorCleared = runState.hiddenFloorCleared == true,
        hiddenFloorStairRoomId = runState.hiddenFloorStairRoomId,
        currentNodeId = runState.currentNodeId,
        maxHeroCount = runState.maxHeroCount or 5,
        partyLevel = runState.partyLevel or 1,
        partyExp = runState.partyExp or 0,
        levelProgressExp = runState.levelProgressExp or 0,
        nextLevelExp = runState.nextLevelExp or 0,
        gold = runState.gold or 0,
        food = runState.food or 0,
        lastActionMessage = runState.lastActionMessage or "",
        map = serializeMap(runState),
        ownedUnits = ownedUnits,
        team = teamRoster,
        bench = benchRoster,
        equipments = serializeEquipments(runState.equipmentIds),
        blessings = serializeBlessings(runState.blessingIds),
        trinkets = RoguelikeTrinket.Serialize(runState),
        eventState = serializeEventState(runState.eventState),
        shopState = runState.shopState,
        campState = runState.campState,
        stairState = runState.stairState,
        rewardState = runState.rewardState,
        lastBattleSummary = runState.lastBattleSummary,
        currentBattleId = runState.currentBattleId,
        battleSnapshot = battleSnapshot,
        cardLibrary = CardBattle.SerializeLibrary(runState.cardLibrary),
        cardBattle = CardBattle.Serialize(runState.cardBattle),
        currentBattleBudget = runState.currentBattleBudget,
        chapterResult = runState.chapterResult,
        debug = {
            availableNextNodeIds = shallowCopyArray(runState.availableNextNodeIds),
            currentBattleEnemyIds = shallowCopyArray(runState.currentBattleEnemyIds),
            currentBattleWaveGroupIds = shallowCopyArray(runState.currentBattleConfig and runState.currentBattleConfig.waveGroupIds),
        },
    }
end

return RoguelikeSnapshot
