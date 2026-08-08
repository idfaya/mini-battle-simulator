local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local SkillsTable = require("config.tables.skills")
local BattleDmgHeal = require("modules.battle_dmg_heal")

local CardBattle = {}

local DEFAULTS = {
    drawCount = 5,
    baseEnergy = 3,
    maxEnergy = 3,
    energyHardCap = 6,
    handLimit = 10,
    guardCardValue = 4,
    woundPerDamagingIntent = 1,
}

local function hasTag(skill, expected)
    for _, tag in ipairs(skill and skill.tags or {}) do
        if tag == expected then
            return true
        end
    end
    return false
end

local function cloneArray(input)
    local result = {}
    for i, value in ipairs(input or {}) do
        result[i] = value
    end
    return result
end

local function shallowCopyTable(input)
    local result = {}
    for key, value in pairs(input or {}) do
        result[key] = value
    end
    return result
end

local function addUniqueFeatIds(result, seen, classId, featIds)
    for _, featId in ipairs(featIds or {}) do
        local id = tonumber(featId) or 0
        if id > 0 and not seen[id] then
            local feat = FeatBuildConfig.GetFeat(id)
            if feat and (tonumber(feat.classId) or 0) == (tonumber(classId) or 0) then
                result[#result + 1] = id
                seen[id] = true
            end
        end
    end
end

local function collectHeroFeatIds(hero)
    local result = {}
    local seen = {}
    local classId = tonumber(hero and hero.classId) or 0
    addUniqueFeatIds(result, seen, classId, ClassBuildProgression.GetLv1FeatIds(classId))
    addUniqueFeatIds(result, seen, classId, hero and hero.feats or nil)
    return result
end

local function inferCardType(skill)
    if not skill then
        return "skill"
    end
    if skill.designKind == "ultimate" then
        return "attack"
    end
    if skill.designKind == "feature" or skill.designKind == "passive" then
        return "power"
    end
    local tags = skill.tags or {}
    for _, tag in ipairs(tags) do
        if tag == "damage" or tag == "attack" then
            return "attack"
        end
        if tag == "buff" or tag == "heal" or tag == "guard" then
            return "skill"
        end
    end
    return "skill"
end

local function shouldCreatePlayableCard(skill)
    if not skill then
        return false
    end
    if skill.runtimeKind == "passive" or skill.designKind == "passive" or skill.designKind == "feature" then
        return false
    end
    return true
end

local function findRosterHero(runState, rosterId)
    for _, hero in ipairs(runState and runState.teamRoster or {}) do
        if tonumber(hero.rosterId) == tonumber(rosterId) then
            return hero
        end
    end
    return nil
end

local function createStatusCard(state, subtype)
    subtype = subtype or "wound"
    state.nextStatusSequence = (tonumber(state.nextStatusSequence) or 1)
    local sequence = state.nextStatusSequence
    state.nextStatusSequence = sequence + 1

    if subtype == "wound" then
        return {
            uid = string.format("status_wound_%03d_%03d", tonumber(state.turn) or 1, sequence),
            cardId = "status_wound",
            name = "伤口",
            description = "不可打出。占据手牌，回合结束进入弃牌堆；本场战斗结束后清除。",
            ownerScope = "team",
            cost = 0,
            type = "status",
            statusSubtype = "wound",
            guardValue = 0,
            targetSide = "none",
            targetMode = "",
            targetCount = 0,
            upgraded = false,
            exhaust = false,
            retain = false,
            ethereal = false,
            disabled = true,
            transient = true,
        }
    end

    return nil
end

local function addStatusCards(state, subtype, count)
    local added = {}
    local amount = math.max(0, math.floor(tonumber(count) or 0))
    for _ = 1, amount do
        local card = createStatusCard(state, subtype)
        if card then
            state.discardPile[#state.discardPile + 1] = card
            state.statusCreatedCount = (tonumber(state.statusCreatedCount) or 0) + 1
            added[#added + 1] = card
        end
    end
    return added
end

local function extractTotalDamage(ok, result)
    if ok ~= true or type(result) ~= "table" then
        return 0
    end
    return math.max(0, math.floor(tonumber(result.totalDamage or result.damage or result.totalDamageDone) or 0))
end

local function inferTargetSide(skill)
    local selections = skill and skill.runtimeData and skill.runtimeData.targetsSelections or {}
    local castTarget = tostring(selections.castTarget or "Enemy")
    if castTarget == "Self" then
        return "self"
    end
    if castTarget == "Alias" or castTarget == "AlliesExcludeSelf" or castTarget == "AliasPos" then
        return "ally"
    end
    return "enemy"
end

local function buildSkillCard(runState, hero, feat, skillId, opts)
    opts = opts or {}
    local skill = SkillsTable.GetSkillConfig(skillId)
    if not shouldCreatePlayableCard(skill) then
        return nil, "skill_not_playable"
    end
    local sequence = tonumber(opts.sequence) or 1
    local sourceKey = opts.sourceKey or string.format("%s:%s:%s",
        tostring(hero and (hero.rosterId or hero.heroId) or 0),
        tostring(feat and feat.id or 0),
        tostring(skillId or 0))
    local cost = tonumber(opts.cost)
    if cost == nil then
        cost = tonumber(skill.skillCost) or 0
    end
    if cost <= 0 then
        cost = tonumber(skill.runtimeData and skill.runtimeData.cardCost) or 1
    end
    local selections = skill.runtimeData and skill.runtimeData.targetsSelections or {}
    local guardValue = tonumber(skill.runtimeData and skill.runtimeData.cardGuard) or 0
    if guardValue <= 0 and hasTag(skill, "guard") then
        guardValue = DEFAULTS.guardCardValue
    end
    local targetMode = tostring(selections.measureType or "")
    if targetMode == "" and skill.rules and skill.rules.isAOE == true then
        targetMode = "Muti"
    end
    local targetCount = tonumber(selections.targetCount or selections.count) or 0
    if targetCount <= 0 and targetMode == "Muti" then
        targetCount = 99
    end
    return {
        uid = nil,
        cardId = opts.cardId or tonumber(feat and feat.id) or tonumber(skillId) or sequence,
        featId = feat and feat.id or nil,
        skillId = tonumber(skillId),
        sourceKey = sourceKey,
        name = opts.name or skill.name or (feat and feat.name) or ("Card " .. tostring(sequence)),
        description = opts.description or skill.description or (feat and feat.description) or "",
        ownerRosterId = hero and hero.rosterId or nil,
        ownerInstanceId = hero and hero.unitId or nil,
        ownerHeroId = hero and hero.heroId or nil,
        ownerName = hero and hero.name or nil,
        ownerClassId = hero and hero.classId or nil,
        cost = cost,
        type = opts.type or inferCardType(skill),
        guardValue = guardValue,
        targetSide = inferTargetSide(skill),
        targetMode = targetMode,
        targetCount = targetCount,
        ignoreFrontProtection = selections.ignoreFrontProtection == true,
        upgraded = false,
        exhaust = skill.designKind == "ultimate",
        retain = false,
        ethereal = false,
        disabled = hero and (hero.isDead == true or (tonumber(hero.currentHp) or 0) <= 0) or false,
        removed = false,
        upgradeLevel = 0,
    }
end

local function appendCard(cards, runState, hero, feat, skillId)
    local card = buildSkillCard(runState, hero, feat, skillId, { sequence = #cards + 1 })
    if card then
        cards[#cards + 1] = card
    end
end

local function buildProjectedCards(runState)
    local cards = {}
    for _, hero in ipairs(runState and runState.teamRoster or {}) do
        if hero.teamState ~= "bench" then
            for _, featId in ipairs(collectHeroFeatIds(hero)) do
                local feat = FeatBuildConfig.GetFeat(featId)
                for _, effect in ipairs(feat and feat.effects or {}) do
                    if effect.type == "grant_skill" and effect.skill then
                        appendCard(cards, runState, hero, feat, effect.skill)
                    elseif effect.type == "replace_skill" and effect.newSkill then
                        appendCard(cards, runState, hero, feat, effect.newSkill)
                    end
                end
            end
        end
    end
    return cards
end

local function ensureCardLibrary(runState)
    if type(runState) ~= "table" then
        return nil
    end
    if type(runState.cardLibrary) ~= "table" then
        runState.cardLibrary = {
            version = 1,
            nextSequence = 1,
            cards = {},
        }
    end
    runState.cardLibrary.version = runState.cardLibrary.version or 1
    runState.cardLibrary.nextSequence = tonumber(runState.cardLibrary.nextSequence) or 1
    runState.cardLibrary.cards = runState.cardLibrary.cards or {}
    return runState.cardLibrary
end

local function allocateLibraryCardUid(library, prefix)
    prefix = prefix or "runlib_card"
    local sequence = tonumber(library.nextSequence) or 1
    library.nextSequence = sequence + 1
    return string.format("%s_%04d", prefix, sequence)
end

function CardBattle.SyncLibrary(runState)
    local library = ensureCardLibrary(runState)
    if not library then
        return nil
    end

    local bySourceKey = {}
    for _, card in ipairs(library.cards or {}) do
        if card and card.sourceKey then
            bySourceKey[tostring(card.sourceKey)] = card
        end
    end

    for _, projected in ipairs(buildProjectedCards(runState)) do
        local sourceKey = tostring(projected.sourceKey or "")
        if sourceKey ~= "" and not bySourceKey[sourceKey] then
            projected.uid = allocateLibraryCardUid(library, "runlib_card")
            library.cards[#library.cards + 1] = projected
            bySourceKey[sourceKey] = projected
        end
    end

    return library
end

local function isCardOwnerActive(runState, card)
    if card and (card.ownerScope == "team" or card.type == "curse" or card.type == "status") then
        return true
    end
    local hero = findRosterHero(runState, card and card.ownerRosterId)
    return hero
        and hero.teamState ~= "bench"
        and hero.isDead ~= true
        and (tonumber(hero.currentHp) or 0) > 0
end

local function heroHasActiveSkill(hero, skillId)
    local id = tonumber(skillId) or 0
    if id <= 0 or type(hero) ~= "table" then
        return false
    end
    for _, skill in ipairs(hero.skillsConfig or {}) do
        if tonumber(skill.skillId or skill.id) == id and tostring(skill.runtimeKind or "active") ~= "passive" then
            return true
        end
    end
    for _, skill in ipairs(hero.buildState and hero.buildState.activeSkills or {}) do
        if tonumber(skill.id or skill.skillId) == id then
            return true
        end
    end
    return false
end

local function findRewardCardOwner(runState, entry)
    local policy = tostring(entry and entry.ownerPolicy or "class")
    local classId = tonumber(entry and entry.classId) or 0
    local skillId = tonumber(entry and entry.skillId) or 0
    for _, hero in ipairs(runState and runState.teamRoster or {}) do
        local active = hero.teamState ~= "bench" and hero.teamState ~= "dead"
            and hero.isDead ~= true and (tonumber(hero.currentHp) or 0) > 0
        local classMatches = policy ~= "class" or classId <= 0 or (tonumber(hero.classId) or 0) == classId
        if active and classMatches and heroHasActiveSkill(hero, skillId) then
            return hero
        end
    end
    return nil
end

local function buildDeck(runState)
    local library = CardBattle.SyncLibrary(runState)
    local cards = {}
    for _, card in ipairs(library and library.cards or {}) do
        local owner = findRosterHero(runState, card and card.ownerRosterId)
        local hasSkill = card.type == "status"
            or card.type == "curse"
            or card.ownerScope == "team"
            or heroHasActiveSkill(owner, card.skillId)
        if card.removed ~= true and isCardOwnerActive(runState, card) and hasSkill then
            cards[#cards + 1] = card
        end
    end
    return cards
end

local function findLibraryCard(runState, cardUid)
    local uid = tostring(cardUid or "")
    local library = ensureCardLibrary(runState)
    for _, card in ipairs(library and library.cards or {}) do
        if tostring(card.uid or "") == uid then
            return card
        end
    end
    return nil
end

local function countPlayableCardsForOwner(runState, ownerRosterId)
    local library = ensureCardLibrary(runState)
    local count = 0
    for _, card in ipairs(library and library.cards or {}) do
        if card.removed ~= true
            and tonumber(card.ownerRosterId) == tonumber(ownerRosterId)
            and card.type ~= "status"
            and card.type ~= "curse"
            and isCardOwnerActive(runState, card) then
            count = count + 1
        end
    end
    return count
end

function CardBattle.UpgradeLibraryCard(runState, cardUid)
    local card = findLibraryCard(runState, cardUid)
    if not card or card.removed == true then
        return false, "card_not_found"
    end
    if (tonumber(card.upgradeLevel) or 0) >= 1 or card.upgraded == true then
        return false, "card_already_upgraded"
    end

    card.upgraded = true
    card.upgradeLevel = 1
    if (tonumber(card.cost) or 0) > 0 then
        card.cost = math.max(0, (tonumber(card.cost) or 0) - 1)
    elseif (tonumber(card.guardValue) or 0) > 0 then
        card.guardValue = (tonumber(card.guardValue) or 0) + 2
    end
    return true, { cardUid = card.uid, cardName = card.name, upgraded = true }
end

function CardBattle.RemoveLibraryCard(runState, cardUid)
    local card = findLibraryCard(runState, cardUid)
    if not card or card.removed == true then
        return false, "card_not_found"
    end
    if card.type == "status" or card.type == "curse" then
        return false, "cannot_remove_status"
    end
    if countPlayableCardsForOwner(runState, card.ownerRosterId) <= 1 then
        return false, "last_owner_card"
    end

    card.removed = true
    return true, { cardUid = card.uid, cardName = card.name, removed = true }
end

function CardBattle.CloneLibraryCard(runState, cardUid, opts)
    opts = opts or {}
    local source = findLibraryCard(runState, cardUid)
    if not source or source.removed == true then
        return false, "card_not_found"
    end
    if source.type == "status" or source.type == "curse" then
        return false, "cannot_clone_pollution"
    end
    if not isCardOwnerActive(runState, source) then
        return false, "owner_inactive"
    end

    local library = ensureCardLibrary(runState)
    local copy = shallowCopyTable(source)
    copy.uid = allocateLibraryCardUid(library, "runlib_card")
    copy.sourceKey = string.format("%s:copy:%s", tostring(source.sourceKey or source.uid or "card"), tostring(copy.uid))
    copy.name = opts.name or source.name
    copy.removed = false
    library.cards[#library.cards + 1] = copy
    return true, { cardUid = copy.uid, cardName = copy.name, sourceCardUid = source.uid }
end

function CardBattle.CanAddRewardSkillCard(runState, entry)
    if type(entry) ~= "table" then
        return false, "invalid_reward_card"
    end
    local skill = SkillsTable.GetSkillConfig(entry.skillId)
    if not shouldCreatePlayableCard(skill) then
        return false, "skill_not_playable"
    end
    local owner = findRewardCardOwner(runState, entry)
    if not owner then
        return false, "reward_card_owner_missing"
    end
    return true, owner
end

function CardBattle.AddRewardSkillCard(runState, entry)
    local ok, ownerOrReason = CardBattle.CanAddRewardSkillCard(runState, entry)
    if not ok then
        return false, ownerOrReason
    end

    local library = ensureCardLibrary(runState)
    if not library then
        return false, "card_library_missing"
    end

    local uid = allocateLibraryCardUid(library, "reward_card")
    local card, reason = buildSkillCard(runState, ownerOrReason, nil, entry.skillId, {
        cardId = "reward_" .. tostring(entry.id or entry.skillId),
        sourceKey = string.format("reward_pool:%s:%s", tostring(entry.id or entry.skillId), tostring(uid)),
        name = entry.name,
        description = entry.description,
        cost = entry.cost,
        sequence = #library.cards + 1,
    })
    if not card then
        return false, reason or "reward_card_build_failed"
    end

    card.uid = uid
    card.rewardCardId = tonumber(entry.id)
    card.rarity = entry.rarity or "common"
    library.cards[#library.cards + 1] = card
    return true, {
        cardUid = card.uid,
        cardName = card.name,
        rewardCardId = card.rewardCardId,
        ownerRosterId = card.ownerRosterId,
        ownerName = card.ownerName,
    }
end

function CardBattle.AddCurseCard(runState, subtype)
    subtype = subtype or "doubt"
    local library = ensureCardLibrary(runState)
    if not library then
        return false, "card_library_missing"
    end

    local sequence = tonumber(library.nextSequence) or 1
    local card = {
        uid = allocateLibraryCardUid(library, "curse_card"),
        cardId = "curse_" .. tostring(subtype),
        sourceKey = string.format("curse:%s:%04d", tostring(subtype), sequence),
        name = subtype == "doubt" and "疑惧" or "诅咒",
        description = "不可打出。Run 级污染，跨战斗保留；占据手牌直到被净化。",
        ownerScope = "team",
        cost = 0,
        type = "curse",
        statusSubtype = subtype,
        guardValue = 0,
        targetSide = "none",
        targetMode = "",
        targetCount = 0,
        upgraded = false,
        upgradeLevel = 0,
        exhaust = false,
        retain = false,
        ethereal = false,
        disabled = true,
        removed = false,
        transient = false,
    }
    library.cards[#library.cards + 1] = card
    return true, { cardUid = card.uid, cardName = card.name, subtype = subtype }
end

function CardBattle.GetCurseCards(runState)
    local library = CardBattle.SyncLibrary(runState)
    local result = {}
    for _, card in ipairs(library and library.cards or {}) do
        if card.removed ~= true and card.type == "curse" then
            result[#result + 1] = card
        end
    end
    return result
end

function CardBattle.PurifyOneCurse(runState)
    local curses = CardBattle.GetCurseCards(runState)
    local card = curses[1]
    if not card then
        return false, "no_curse"
    end
    card.removed = true
    return true, { cardUid = card.uid, cardName = card.name, purified = true }
end

function CardBattle.GetUpgradeableCards(runState)
    local library = CardBattle.SyncLibrary(runState)
    local result = {}
    for _, card in ipairs(library and library.cards or {}) do
        if card.removed ~= true
            and card.upgraded ~= true
            and (tonumber(card.upgradeLevel) or 0) <= 0
            and isCardOwnerActive(runState, card) then
            result[#result + 1] = card
        end
    end
    return result
end

function CardBattle.GetRemovableCards(runState)
    local library = CardBattle.SyncLibrary(runState)
    local result = {}
    for _, card in ipairs(library and library.cards or {}) do
        if card.removed ~= true
            and card.type ~= "status"
            and card.type ~= "curse"
            and isCardOwnerActive(runState, card)
            and countPlayableCardsForOwner(runState, card.ownerRosterId) > 1 then
            result[#result + 1] = card
        end
    end
    return result
end

local function syncCardsAvailability(cards, aliveByInstanceId)
    for _, card in ipairs(cards or {}) do
        local instanceId = card and card.ownerInstanceId
        if instanceId ~= nil and aliveByInstanceId[tostring(instanceId)] ~= nil then
            card.disabled = aliveByInstanceId[tostring(instanceId)] ~= true
        end
    end
end

function CardBattle.SyncOwnerAvailability(runState, battleSnapshot)
    local state = runState and runState.cardBattle
    if type(state) ~= "table" or type(battleSnapshot) ~= "table" then
        return false
    end

    local aliveByInstanceId = {}
    for _, unit in ipairs(battleSnapshot.leftTeam or {}) do
        if unit and unit.id ~= nil then
            aliveByInstanceId[tostring(unit.id)] = unit.isAlive == true and (tonumber(unit.hp) or 0) > 0
        end
    end

    syncCardsAvailability(state.deck, aliveByInstanceId)
    syncCardsAvailability(state.drawPile, aliveByInstanceId)
    syncCardsAvailability(state.hand, aliveByInstanceId)
    syncCardsAvailability(state.discardPile, aliveByInstanceId)
    syncCardsAvailability(state.exhaustPile, aliveByInstanceId)
    syncCardsAvailability(state.powers, aliveByInstanceId)
    return true
end

local function makeRng(seed)
    local state = tonumber(seed) or 1
    if state <= 0 then
        state = 1
    end
    return function(max)
        state = (state * 1103515245 + 12345) % 2147483647
        return (state % max) + 1
    end
end

local function shuffle(cards, seed)
    local result = cloneArray(cards)
    local nextInt = makeRng(seed)
    for i = #result, 2, -1 do
        local j = nextInt(i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

local function drawCards(state, count)
    local target = tonumber(count) or DEFAULTS.drawCount
    while target > 0 and #state.hand < state.handLimit do
        if #state.drawPile == 0 and #state.discardPile > 0 then
            state.drawPile = shuffle(state.discardPile, (state.seed or 1) + state.shuffleCount + 31)
            state.discardPile = {}
            state.shuffleCount = state.shuffleCount + 1
        end
        if #state.drawPile == 0 then
            break
        end
        state.hand[#state.hand + 1] = table.remove(state.drawPile)
        target = target - 1
    end
end

local function bindBattleInstanceIds(runState, deck, battleSnapshot)
    if type(battleSnapshot) ~= "table" or type(battleSnapshot.leftTeam) ~= "table" then
        return
    end

    local activeRoster = {}
    for _, hero in ipairs(runState and runState.teamRoster or {}) do
        if hero.teamState ~= "bench" and hero.isDead ~= true and (tonumber(hero.currentHp) or 0) > 0 then
            activeRoster[#activeRoster + 1] = hero
        end
    end

    local instanceByRosterId = {}
    local instanceByName = {}
    for _, battleUnit in ipairs(battleSnapshot.leftTeam or {}) do
        if battleUnit and battleUnit.name then
            instanceByName[tostring(battleUnit.name)] = tonumber(battleUnit.id)
        end
    end

    for index, hero in ipairs(activeRoster) do
        local battleUnit = battleSnapshot.leftTeam[index]
        local instanceId = hero.name and instanceByName[tostring(hero.name)] or nil
        if not instanceId and battleUnit then
            instanceId = tonumber(battleUnit.id)
        end
        if instanceId and hero.rosterId ~= nil then
            instanceByRosterId[tostring(hero.rosterId)] = instanceId
        end
    end

    for _, card in ipairs(deck or {}) do
        local instanceId = instanceByRosterId[tostring(card.ownerRosterId)]
        if instanceId then
            card.ownerInstanceId = instanceId
            card.disabled = false
        elseif card.ownerRosterId ~= nil then
            card.ownerInstanceId = nil
            card.disabled = true
        end
    end
end

local function countActiveRoster(runState)
    local count = 0
    for _, hero in ipairs(runState and runState.teamRoster or {}) do
        if hero.teamState ~= "bench" and hero.isDead ~= true and (tonumber(hero.currentHp) or 0) > 0 then
            count = count + 1
        end
    end
    return count
end

local function resolveBaseEnergy(runState)
    local activeCount = countActiveRoster(runState)
    local energy = DEFAULTS.baseEnergy + math.max(0, activeCount - 3)
    return math.min(DEFAULTS.energyHardCap, math.max(DEFAULTS.baseEnergy, energy))
end

local function resolveDrawCount(runState)
    local activeCount = countActiveRoster(runState)
    local drawCount = DEFAULTS.drawCount + math.max(0, activeCount - 3)
    return math.min(DEFAULTS.handLimit, math.max(DEFAULTS.drawCount, drawCount))
end

function CardBattle.StartBattle(runState, battleSnapshot)
    local deck = buildDeck(runState)
    bindBattleInstanceIds(runState, deck, battleSnapshot)
    local seed = (tonumber(runState and runState.seed) or 0)
        + (tonumber(runState and runState.currentNodeId) or 0) * 97
        + (tonumber(runState and runState.currentBattleId) or 0) * 131
        + 17
    local baseEnergy = resolveBaseEnergy(runState)
    local drawCount = resolveDrawCount(runState)
    local state = {
        version = 1,
        turn = 1,
        phase = "player",
        seed = seed,
        shuffleCount = 0,
        baseEnergy = baseEnergy,
        maxEnergy = baseEnergy,
        teamEnergy = baseEnergy,
        tempEnergy = 0,
        chargeEnergy = 0,
        energyHardCap = DEFAULTS.energyHardCap,
        handLimit = DEFAULTS.handLimit,
        drawCount = drawCount,
        guard = 0,
        enemyIntents = {},
        nextStatusSequence = 1,
        statusCreatedCount = 0,
        deck = cloneArray(deck),
        drawPile = shuffle(deck, seed),
        hand = {},
        discardPile = {},
        exhaustPile = {},
        powers = {},
    }
    drawCards(state, state.drawCount)
    runState.cardBattle = state
    CardBattle.SyncOwnerAvailability(runState, battleSnapshot)
    BattleDmgHeal.BindCardBattleGuardState(state)
    return state
end

function CardBattle.RefreshEnemyIntents(runState, intents)
    local state = runState and runState.cardBattle
    if type(state) ~= "table" then
        return false
    end
    state.enemyIntents = intents or {}
    return true
end

function CardBattle.Clear(runState)
    if runState then
        BattleDmgHeal.ClearCardBattleGuardState(runState.cardBattle)
        runState.cardBattle = nil
    end
end

local function removeHandCard(state, cardUid)
    local uid = tostring(cardUid or "")
    for index, card in ipairs(state.hand or {}) do
        if tostring(card.uid) == uid then
            table.remove(state.hand, index)
            return card
        end
    end
    return nil
end

local function findHandCard(state, cardUid)
    local uid = tostring(cardUid or "")
    for index, card in ipairs(state.hand or {}) do
        if tostring(card.uid) == uid then
            return card, index
        end
    end
    return nil, nil
end

function CardBattle.PlayCard(runState, cardUid, opts)
    opts = opts or {}
    local state = runState and runState.cardBattle
    if type(state) ~= "table" then
        return false, "card_battle_not_started"
    end
    if state.phase ~= "player" then
        return false, "not_player_turn"
    end

    local card = findHandCard(state, cardUid)
    if not card then
        return false, "card_not_in_hand"
    end
    if card.type == "status" or card.type == "curse" then
        return false, "card_unplayable"
    end
    if card.disabled == true then
        return false, "card_disabled"
    end

    local cost = tonumber(card.cost) or 0
    if (tonumber(state.teamEnergy) or 0) < cost then
        return false, "not_enough_energy"
    end

    local castResult = nil
    if type(opts.castCard) == "function" then
        local ok, result = opts.castCard(card, opts.targetId)
        if not ok then
            return false, result or "cast_failed"
        end
        castResult = result
    end

    card = removeHandCard(state, cardUid)
    if not card then
        return false, "card_not_in_hand"
    end

    state.teamEnergy = (tonumber(state.teamEnergy) or 0) - cost
    local guardValue = math.max(0, math.floor(tonumber(card.guardValue) or 0))
    if guardValue > 0 then
        state.guard = (math.max(0, math.floor(tonumber(state.guard) or 0))) + guardValue
    end
    if card.exhaust == true then
        state.exhaustPile[#state.exhaustPile + 1] = card
    elseif card.type == "power" then
        state.powers[#state.powers + 1] = card
    else
        state.discardPile[#state.discardPile + 1] = card
    end

    runState.lastActionMessage = string.format("打出卡牌：%s", tostring(card.name or card.uid))
    return true, {
        cardUid = card.uid,
        cardName = card.name,
        cast = castResult,
        teamEnergy = state.teamEnergy,
    }
end

local function discardHandForTurnEnd(state)
    local retained = {}
    for _, card in ipairs(state.hand or {}) do
        if card.ethereal == true then
            state.exhaustPile[#state.exhaustPile + 1] = card
        elseif card.retain == true then
            retained[#retained + 1] = card
        else
            state.discardPile[#state.discardPile + 1] = card
        end
    end
    state.hand = retained
end

local function beginPlayerTurn(state, buildEnemyIntents)
    state.phase = "player"
    state.turn = (tonumber(state.turn) or 1) + 1
    state.guard = 0
    state.tempEnergy = 0
    state.teamEnergy = math.min(
        tonumber(state.energyHardCap) or DEFAULTS.energyHardCap,
        tonumber(state.maxEnergy) or DEFAULTS.maxEnergy
    )
    drawCards(state, state.drawCount)
    if type(buildEnemyIntents) == "function" then
        state.enemyIntents = buildEnemyIntents() or {}
    end
end

function CardBattle.EndTurn(runState, opts)
    opts = opts or {}
    local state = runState and runState.cardBattle
    if type(state) ~= "table" then
        return false, "card_battle_not_started"
    end
    if state.phase ~= "player" then
        return false, "not_player_turn"
    end

    discardHandForTurnEnd(state)
    state.teamEnergy = 0
    state.tempEnergy = 0
    state.phase = "enemy"
    runState.lastActionMessage = "结束回合：敌方按意图行动"

    for _, intent in ipairs(state.enemyIntents or {}) do
        local ok, result = true, nil
        if type(opts.executeEnemyIntent) == "function" then
            ok, result = opts.executeEnemyIntent(intent)
        end
        if extractTotalDamage(ok, result) > 0 then
            addStatusCards(state, "wound", DEFAULTS.woundPerDamagingIntent)
        end
        if type(opts.isBattleEnded) == "function" and opts.isBattleEnded() then
            state.phase = "ended"
            return true, { phase = state.phase }
        end
    end

    if type(opts.advanceBattleRound) == "function" then
        opts.advanceBattleRound()
        if type(opts.isBattleEnded) == "function" and opts.isBattleEnded() then
            state.phase = "ended"
            return true, { phase = state.phase }
        end
    end

    beginPlayerTurn(state, opts.buildEnemyIntents)
    runState.lastActionMessage = string.format("第 %d 回合：抽牌并恢复能量", tonumber(state.turn) or 1)
    return true, {
        phase = state.phase,
        turn = state.turn,
        handCount = #(state.hand or {}),
        teamEnergy = state.teamEnergy,
    }
end

local function serializeCards(cards)
    local result = {}
    for i, card in ipairs(cards or {}) do
        result[i] = {
            uid = card.uid,
            cardId = card.cardId,
            featId = card.featId,
            skillId = card.skillId,
            name = card.name,
            description = card.description,
            ownerRosterId = card.ownerRosterId,
            ownerInstanceId = card.ownerInstanceId,
            ownerHeroId = card.ownerHeroId,
            ownerName = card.ownerName,
            ownerClassId = card.ownerClassId,
            cost = card.cost,
            type = card.type,
            guardValue = card.guardValue,
            targetSide = card.targetSide,
            targetMode = card.targetMode,
            targetCount = card.targetCount,
            ignoreFrontProtection = card.ignoreFrontProtection == true,
            upgraded = card.upgraded == true,
            upgradeLevel = tonumber(card.upgradeLevel) or 0,
            exhaust = card.exhaust == true,
            retain = card.retain == true,
            ethereal = card.ethereal == true,
            disabled = card.disabled == true,
            removed = card.removed == true,
            sourceKey = card.sourceKey,
            ownerScope = card.ownerScope,
            statusSubtype = card.statusSubtype,
            transient = card.transient == true,
            rewardCardId = card.rewardCardId,
            rarity = card.rarity,
        }
    end
    return result
end

function CardBattle.SerializeLibrary(library)
    if type(library) ~= "table" then
        return nil
    end
    return {
        version = library.version or 1,
        nextSequence = tonumber(library.nextSequence) or 1,
        cards = serializeCards(library.cards),
    }
end

local function serializeIntents(intents)
    local result = {}
    for i, intent in ipairs(intents or {}) do
        local targetIds = {}
        for index, targetId in ipairs(intent.targetIds or {}) do
            targetIds[index] = targetId
        end
        local targetNames = {}
        for index, targetName in ipairs(intent.targetNames or {}) do
            targetNames[index] = targetName
        end
        result[i] = {
            enemyInstanceId = intent.enemyInstanceId,
            enemyName = intent.enemyName,
            type = intent.type or "attack",
            skillId = intent.skillId,
            skillName = intent.skillName,
            targetIds = targetIds,
            targetNames = targetNames,
        }
    end
    return result
end

function CardBattle.Serialize(state)
    if type(state) ~= "table" then
        return nil
    end
    return {
        version = state.version or 1,
        turn = state.turn or 1,
        phase = state.phase or "player",
        teamEnergy = state.teamEnergy or 0,
        baseEnergy = state.baseEnergy or DEFAULTS.baseEnergy,
        maxEnergy = state.maxEnergy or DEFAULTS.maxEnergy,
        energyHardCap = state.energyHardCap or DEFAULTS.energyHardCap,
        tempEnergy = state.tempEnergy or 0,
        chargeEnergy = state.chargeEnergy or 0,
        guard = state.guard or 0,
        handLimit = state.handLimit or DEFAULTS.handLimit,
        drawCount = state.drawCount or DEFAULTS.drawCount,
        deck = serializeCards(state.deck),
        hand = serializeCards(state.hand),
        drawPileCount = #(state.drawPile or {}),
        discardPile = serializeCards(state.discardPile),
        discardPileCount = #(state.discardPile or {}),
        exhaustPile = serializeCards(state.exhaustPile),
        exhaustPileCount = #(state.exhaustPile or {}),
        powers = serializeCards(state.powers),
        enemyIntents = serializeIntents(state.enemyIntents),
        statusCreatedCount = tonumber(state.statusCreatedCount) or 0,
    }
end

return CardBattle
