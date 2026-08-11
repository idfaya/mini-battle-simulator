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
    starterGuardValue = 5,
    momentumMax = 3,
    woundPerDamagingIntent = 1,
}

local heroHasActiveSkill

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

local function pickNumber(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            local number = tonumber(value)
            if number ~= nil then
                return number
            end
        end
    end
    return nil
end

local function applyCardEffectOverrides(card, effects)
    if type(card) ~= "table" or type(effects) ~= "table" then
        return card
    end

    local drawCardsValue = pickNumber(effects.drawCards, effects.draw, effects.cardDraw)
    if drawCardsValue ~= nil then
        card.drawCards = math.max(0, math.floor(drawCardsValue))
    end

    local energyGainValue = pickNumber(effects.energyGain, effects.energy, effects.gainEnergy)
    if energyGainValue ~= nil then
        card.energyGain = math.max(0, math.floor(energyGainValue))
    end

    local guardValue = pickNumber(effects.guardValue, effects.guard)
    if guardValue ~= nil and guardValue > 0 then
        card.guardValue = (tonumber(card.guardValue) or 0) + math.floor(guardValue)
    end

    local momentumGain = pickNumber(effects.momentumGain, effects.gainMomentum)
    if momentumGain ~= nil then
        card.momentumGain = math.max(0, math.floor(momentumGain))
    end

    local momentumSpend = pickNumber(effects.momentumSpend, effects.spendMomentum)
    if momentumSpend ~= nil then
        card.momentumSpend = math.max(0, math.floor(momentumSpend))
    end

    local momentumCostReduction = pickNumber(effects.momentumCostReduction, effects.momentumCostDiscount)
    if momentumCostReduction ~= nil then
        card.momentumCostReduction = math.max(0, math.floor(momentumCostReduction))
    end

    local momentumEnergyGain = pickNumber(effects.momentumEnergyGain)
    if momentumEnergyGain ~= nil then
        card.momentumEnergyGain = math.max(0, math.floor(momentumEnergyGain))
    end

    local momentumDrawCards = pickNumber(effects.momentumDrawCards, effects.momentumDraw)
    if momentumDrawCards ~= nil then
        card.momentumDrawCards = math.max(0, math.floor(momentumDrawCards))
    end

    local momentumGuardValue = pickNumber(effects.momentumGuardValue, effects.momentumGuard)
    if momentumGuardValue ~= nil then
        card.momentumGuardValue = math.max(0, math.floor(momentumGuardValue))
    end

    if effects.exhaust ~= nil then
        card.exhaust = effects.exhaust == true
    end
    if effects.retain ~= nil then
        card.retain = effects.retain == true
    end
    if effects.ethereal ~= nil then
        card.ethereal = effects.ethereal == true
    end
    if effects.type ~= nil then
        card.type = tostring(effects.type)
    end
    return card
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
    local card = {
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
        drawCards = 0,
        energyGain = 0,
        momentumGain = 0,
        momentumSpend = 0,
        momentumCostReduction = 0,
        momentumEnergyGain = 0,
        momentumDrawCards = 0,
        momentumGuardValue = 0,
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
    applyCardEffectOverrides(card, opts.cardEffects or opts.cardEffect)
    return card
end

local function getHeroActiveSkills(hero)
    local result = {}
    for _, skill in ipairs(hero and hero.skillsConfig or {}) do
        if tonumber(skill.skillId or skill.id) and tostring(skill.runtimeKind or "active") ~= "passive" then
            result[#result + 1] = skill
        end
    end
    for _, skill in ipairs(hero and hero.buildState and hero.buildState.activeSkills or {}) do
        if tonumber(skill.id or skill.skillId) then
            result[#result + 1] = skill
        end
    end
    return result
end

local function pickPrimaryStarterSkill(hero)
    for _, skill in ipairs(getHeroActiveSkills(hero)) do
        local skillId = tonumber(skill.id or skill.skillId)
        local config = SkillsTable.GetSkillConfig(skillId)
        if config and inferTargetSide(config) == "enemy" then
            return skillId
        end
    end
    local first = getHeroActiveSkills(hero)[1]
    return first and tonumber(first.id or first.skillId) or nil
end

local function pickUtilityStarterSkill(hero, primarySkillId)
    for _, skill in ipairs(getHeroActiveSkills(hero)) do
        local skillId = tonumber(skill.id or skill.skillId)
        if skillId and skillId ~= tonumber(primarySkillId) then
            return skillId
        end
    end
    return primarySkillId
end

local function buildStarterSkillCard(runState, hero, skillId, slotIndex, opts)
    if not skillId or not heroHasActiveSkill(hero, skillId) then
        return nil
    end
    opts = opts or {}
    local card, reason = buildSkillCard(runState, hero, nil, skillId, {
        cardId = string.format("starter_%s_%d", tostring(hero and hero.classId or 0), slotIndex),
        sourceKey = string.format("starter:%s:%d:%s",
            tostring(hero and (hero.rosterId or hero.heroId) or 0),
            slotIndex,
            tostring(skillId)),
        name = opts.name,
        description = opts.description,
        cost = opts.cost or 1,
        type = opts.type,
        cardEffects = opts.cardEffects,
        sequence = slotIndex,
    })
    if not card then
        return nil, reason
    end
    card.starter = true
    return card
end

local function buildStarterPureCard(hero, slotIndex, suffix, opts)
    opts = opts or {}
    suffix = suffix or "pure"
    local sourceKey = string.format("starter:%s:%d:%s",
        tostring(hero and (hero.rosterId or hero.heroId) or 0),
        slotIndex,
        tostring(suffix))
    return {
        uid = nil,
        cardId = string.format("starter_%s_%s", tostring(suffix), tostring(hero and hero.classId or 0)),
        featId = nil,
        skillId = nil,
        sourceKey = sourceKey,
        name = opts.name or "战术准备",
        description = opts.description or "Starter 策略牌。调整本回合出牌节奏。",
        ownerRosterId = hero and hero.rosterId or nil,
        ownerInstanceId = hero and hero.unitId or nil,
        ownerHeroId = hero and hero.heroId or nil,
        ownerName = hero and hero.name or nil,
        ownerClassId = hero and hero.classId or nil,
        cost = tonumber(opts.cost) or 0,
        type = opts.type or "skill",
        guardValue = tonumber(opts.guardValue) or 0,
        drawCards = tonumber(opts.drawCards) or 0,
        energyGain = tonumber(opts.energyGain) or 0,
        momentumGain = tonumber(opts.momentumGain) or 0,
        momentumSpend = tonumber(opts.momentumSpend) or 0,
        momentumCostReduction = tonumber(opts.momentumCostReduction) or 0,
        momentumEnergyGain = tonumber(opts.momentumEnergyGain) or 0,
        momentumDrawCards = tonumber(opts.momentumDrawCards) or 0,
        momentumGuardValue = tonumber(opts.momentumGuardValue) or 0,
        targetSide = opts.targetSide or "none",
        targetMode = opts.targetMode or "",
        targetCount = tonumber(opts.targetCount) or 0,
        ignoreFrontProtection = false,
        upgraded = false,
        exhaust = opts.exhaust == true,
        retain = opts.retain == true,
        ethereal = opts.ethereal == true,
        disabled = hero and (hero.isDead == true or (tonumber(hero.currentHp) or 0) <= 0) or false,
        removed = false,
        upgradeLevel = 0,
        starter = true,
    }
end

local function buildStarterSetupCard(hero, slotIndex)
    local classId = tonumber(hero and hero.classId) or 0
    local setupByClass = {
        [1] = { name = "伺机而动", description = "0 费 Setup。抽 1 张牌并获得 1 蓄势，为偷袭或诡诈窗口找牌。", drawCards = 1, momentumGain = 1 },
        [2] = { name = "战术号令", description = "0 费 Setup。抽 1 张牌并获得 1 蓄势，把能量集中给关键攻防牌。", drawCards = 1, momentumGain = 1 },
        [3] = { name = "疾风步法", description = "0 费 Setup。抽 1 张牌并获得 1 蓄势，寻找连段或防守牌。", drawCards = 1, momentumGain = 1 },
        [4] = { name = "誓约准备", description = "0 费 Setup。获得 3 Guard 与 1 蓄势，保留到需要承压的回合。", guardValue = 3, momentumGain = 1, retain = true },
        [5] = { name = "瞄准", description = "0 费 Setup。抽 1 张牌并获得 1 蓄势，保留以等待集火窗口。", drawCards = 1, momentumGain = 1, retain = true },
        [6] = { name = "短祷", description = "0 费 Setup。获得 3 Guard、抽 1 张牌并获得 1 蓄势。", guardValue = 3, drawCards = 1, momentumGain = 1 },
        [7] = { name = "聚炎", description = "0 费 Setup。获得 1 蓄势并回复 1 点能量，本场消耗，用于火焰爆发回合。", energyGain = 1, momentumGain = 1, exhaust = true },
        [8] = { name = "凝霜", description = "0 费 Setup。抽 1 张牌并获得 1 蓄势，保留以等待控制窗口。", drawCards = 1, momentumGain = 1, retain = true },
        [9] = { name = "魔契充能", description = "0 费 Setup。获得 1 蓄势并回复 1 点能量，本场消耗，用于雷链爆发回合。", energyGain = 1, momentumGain = 1, exhaust = true },
        [10] = { name = "鲁莽蓄势", description = "0 费 Setup。获得 1 蓄势并回复 1 点能量，本场消耗，用于重击或防守取舍。", energyGain = 1, momentumGain = 1, exhaust = true },
    }
    local opts = setupByClass[classId] or { name = "战术准备", description = "0 费 Setup。抽 1 张牌并获得 1 蓄势。", drawCards = 1, momentumGain = 1 }
    return buildStarterPureCard(hero, slotIndex, "setup", opts)
end

local function buildStarterDefenseCard(hero, slotIndex)
    local classId = tonumber(hero and hero.classId) or 0
    local frontliner = classId == 1 or classId == 2 or classId == 3 or classId == 4 or classId == 10
    local optsByClass = {
        [2] = { name = "架盾", description = "获得 7 Guard。战士可以把本回合资源转成承压窗口。", cost = 1, guardValue = 7 },
        [4] = { name = "守誓", description = "获得 5 Guard，回合结束保留。等待敌方 Intent 高压回合。", cost = 1, guardValue = 5, retain = true },
        [6] = { name = "庇护祈祷", description = "获得 5 Guard，回合结束保留。治疗牌可以等到真正需要时再打。", cost = 1, guardValue = 5, retain = true },
        [8] = { name = "冰障", description = "获得 4 Guard 并抽 1 张牌。防守同时寻找控制牌。", cost = 1, guardValue = 4, drawCards = 1 },
        [10] = { name = "硬扛", description = "获得 6 Guard。本回合选择承伤而非继续进攻。", cost = 1, guardValue = 6 },
    }
    local opts = optsByClass[classId] or {
        name = frontliner and "防御" or "走位",
        description = frontliner and "获得 5 Guard，用来抵挡随后敌方 Intent。" or "获得 4 Guard，后排角色用来处理被点名风险。",
        cost = 1,
        guardValue = frontliner and DEFAULTS.starterGuardValue or 4,
    }
    return buildStarterPureCard(hero, slotIndex, "guard", opts)
end

local function starterPrimaryEffects(classId)
    local effectsByClass = {
        [1] = { drawCards = 1 },
        [2] = { guardValue = 2 },
        [3] = { energyGain = 1 },
        [4] = { guardValue = 2 },
        [5] = { drawCards = 1 },
        [6] = { drawCards = 1 },
        [7] = { drawCards = 1 },
        [8] = { drawCards = 1 },
        [9] = { drawCards = 1 },
        [10] = { guardValue = 2 },
    }
    return effectsByClass[tonumber(classId) or 0] or {}
end

local function starterPayoffSpec(hero, utilitySkillId, primarySkillId)
    local classId = tonumber(hero and hero.classId) or 0
    local useUtility = utilitySkillId and utilitySkillId ~= primarySkillId
    local skillId = useUtility and utilitySkillId or primarySkillId
    local specsByClass = {
        [1] = { name = "偷袭兑现", description = "Payoff。若耗 1 蓄势，本张降 1 费并返还 1 能量，本场消耗。", cost = 1, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumEnergyGain = 1, exhaust = true } },
        [2] = { name = "回气窗口", description = "Payoff。保留救场能力；若耗 1 蓄势，本张降 1 费并获得 4 Guard，本场消耗。", cost = 1, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumGuardValue = 4, retain = true, exhaust = true } },
        [3] = { name = "连段收束", description = "Payoff。若耗 1 蓄势，本张降 1 费并抽 1 张牌。", cost = 1, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumDrawCards = 1 } },
        [4] = { name = "圣疗窗口", description = "Payoff。保留救场治疗；若耗 1 蓄势，本张降 1 费并获得 4 Guard，本场消耗。", cost = 1, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumGuardValue = 4, retain = true, exhaust = true } },
        [5] = { name = "集中射击", description = "Payoff。2 费集中火力；若耗 1 蓄势，本张降 1 费并抽 1 张牌，本场消耗。", cost = 2, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumDrawCards = 1, exhaust = true } },
        [6] = { name = "治愈窗口", description = "Payoff。保留治疗窗口；若耗 1 蓄势，本张降 1 费并获得 4 Guard。", cost = 1, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumGuardValue = 4, retain = true } },
        [7] = { name = "爆燃火花", description = "Payoff。2 费火焰爆发；若耗 1 蓄势，本张降 1 费并返还 1 能量，本场消耗。", cost = 2, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumEnergyGain = 1, exhaust = true } },
        [8] = { name = "冰封窗口", description = "Payoff。保留冰霜处理牌；若耗 1 蓄势，本张降 1 费并抽 1 张牌。", cost = 1, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumDrawCards = 1, retain = true } },
        [9] = { name = "雷涌窗口", description = "Payoff。2 费雷电爆发；若耗 1 蓄势，本张降 1 费、返还 1 能量并抽 1 张牌，本场消耗。", cost = 2, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumEnergyGain = 1, momentumDrawCards = 1, exhaust = true } },
        [10] = { name = "狂怒压上", description = "Payoff。2 费压制；若耗 1 蓄势，本张降 1 费并获得 4 Guard，本场消耗。", cost = 2, cardEffects = { momentumSpend = 1, momentumCostReduction = 1, momentumGuardValue = 4, exhaust = true } },
    }
    local spec = specsByClass[classId] or { name = "职业窗口", description = "Payoff。职业节奏牌。", cost = 1, cardEffects = {} }
    spec.skillId = skillId
    return spec
end

local function buildStarterCards(runState)
    local cards = {}
    for _, hero in ipairs(runState and runState.teamRoster or {}) do
        if hero.teamState ~= "bench" then
            local classId = tonumber(hero and hero.classId) or 0
            local primarySkillId = pickPrimaryStarterSkill(hero)
            local utilitySkillId = pickUtilityStarterSkill(hero, primarySkillId)
            local primarySkill = SkillsTable.GetSkillConfig(primarySkillId)

            local firstAttack = buildStarterSkillCard(runState, hero, primarySkillId, 1, {
                name = primarySkill and primarySkill.name or "基础攻击",
                description = "Starter 基础动作。提供最低输出，并按职业附带少量节奏收益。",
                cardEffects = starterPrimaryEffects(classId),
            })
            if firstAttack then cards[#cards + 1] = firstAttack end

            cards[#cards + 1] = buildStarterSetupCard(hero, 2)
            cards[#cards + 1] = buildStarterDefenseCard(hero, 3)

            local payoffSpec = starterPayoffSpec(hero, utilitySkillId, primarySkillId)
            local payoff = buildStarterSkillCard(runState, hero, payoffSpec.skillId, 4, {
                name = payoffSpec.name,
                description = payoffSpec.description,
                cost = payoffSpec.cost,
                cardEffects = payoffSpec.cardEffects,
            })
            if payoff then cards[#cards + 1] = payoff end
        end
    end
    return cards
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
                if (tonumber(feat and feat.level) or 0) > 1 then
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

    local projectedCards = buildStarterCards(runState)
    for _, projected in ipairs(buildProjectedCards(runState)) do
        projectedCards[#projectedCards + 1] = projected
    end

    for _, projected in ipairs(projectedCards) do
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

heroHasActiveSkill = function(hero, skillId)
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
            or card.skillId == nil
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
    if (tonumber(card.momentumSpend) or 0) > 0 then
        if (tonumber(card.momentumEnergyGain) or 0) > 0 then
            card.momentumEnergyGain = (tonumber(card.momentumEnergyGain) or 0) + 1
        elseif (tonumber(card.momentumDrawCards) or 0) > 0 then
            card.momentumDrawCards = (tonumber(card.momentumDrawCards) or 0) + 1
        elseif (tonumber(card.momentumGuardValue) or 0) > 0 then
            card.momentumGuardValue = (tonumber(card.momentumGuardValue) or 0) + 2
        else
            card.momentumCostReduction = (tonumber(card.momentumCostReduction) or 0) + 1
        end
    elseif (tonumber(card.momentumGain) or 0) > 0 then
        card.momentumGain = (tonumber(card.momentumGain) or 0) + 1
    elseif (tonumber(card.guardValue) or 0) > 0 then
        card.guardValue = (tonumber(card.guardValue) or 0) + 2
    elseif (tonumber(card.drawCards) or 0) > 0 then
        card.drawCards = (tonumber(card.drawCards) or 0) + 1
    elseif (tonumber(card.energyGain) or 0) > 0 then
        card.energyGain = (tonumber(card.energyGain) or 0) + 1
    elseif (tonumber(card.cost) or 0) > 0 then
        card.cost = math.max(0, (tonumber(card.cost) or 0) - 1)
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
        cardEffects = entry.cardEffects,
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
        drawCards = 0,
        energyGain = 0,
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
        momentum = 0,
        momentumMax = DEFAULTS.momentumMax,
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

local function resolveMomentumSpend(state, card)
    local available = math.max(0, math.floor(tonumber(state and state.momentum) or 0))
    local spend = math.max(0, math.floor(tonumber(card and card.momentumSpend) or 0))
    if spend <= 0 or available < spend then
        return 0
    end
    return spend
end

local function resolveEffectiveCost(state, card)
    local baseCost = math.max(0, math.floor(tonumber(card and card.cost) or 0))
    local momentumSpend = resolveMomentumSpend(state, card)
    if momentumSpend > 0 then
        baseCost = math.max(0, baseCost - math.max(0, math.floor(tonumber(card.momentumCostReduction) or 0)))
    end
    return baseCost, momentumSpend
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

    local cost, momentumSpend = resolveEffectiveCost(state, card)
    if (tonumber(state.teamEnergy) or 0) < cost then
        return false, "not_enough_energy"
    end

    local castResult = nil
    if card.skillId ~= nil and type(opts.castCard) == "function" then
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
    local momentumBefore = math.max(0, math.floor(tonumber(state.momentum) or 0))
    if momentumSpend > 0 then
        state.momentum = math.max(0, momentumBefore - momentumSpend)
    end
    local guardValue = math.max(0, math.floor(tonumber(card.guardValue) or 0))
    if momentumSpend > 0 then
        guardValue = guardValue + math.max(0, math.floor(tonumber(card.momentumGuardValue) or 0))
    end
    if guardValue > 0 then
        state.guard = (math.max(0, math.floor(tonumber(state.guard) or 0))) + guardValue
    end
    local energyGain = math.max(0, math.floor(tonumber(card.energyGain) or 0))
    if momentumSpend > 0 then
        energyGain = energyGain + math.max(0, math.floor(tonumber(card.momentumEnergyGain) or 0))
    end
    if energyGain > 0 then
        local hardCap = tonumber(state.energyHardCap) or DEFAULTS.energyHardCap
        state.teamEnergy = math.min(hardCap, (tonumber(state.teamEnergy) or 0) + energyGain)
    end
    local drawCount = math.max(0, math.floor(tonumber(card.drawCards) or 0))
    if momentumSpend > 0 then
        drawCount = drawCount + math.max(0, math.floor(tonumber(card.momentumDrawCards) or 0))
    end
    if drawCount > 0 then
        drawCards(state, drawCount)
    end
    local momentumGain = math.max(0, math.floor(tonumber(card.momentumGain) or 0))
    if momentumGain > 0 then
        local momentumMax = tonumber(state.momentumMax) or DEFAULTS.momentumMax
        state.momentum = math.min(momentumMax, (math.max(0, math.floor(tonumber(state.momentum) or 0))) + momentumGain)
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
        effectiveCost = cost,
        drawCards = drawCount,
        energyGain = energyGain,
        guardValue = guardValue,
        momentumBefore = momentumBefore,
        momentumSpend = momentumSpend,
        momentumGain = momentumGain,
        momentum = state.momentum,
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
    state.momentum = 0
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
            drawCards = tonumber(card.drawCards) or 0,
            energyGain = tonumber(card.energyGain) or 0,
            momentumGain = tonumber(card.momentumGain) or 0,
            momentumSpend = tonumber(card.momentumSpend) or 0,
            momentumCostReduction = tonumber(card.momentumCostReduction) or 0,
            momentumEnergyGain = tonumber(card.momentumEnergyGain) or 0,
            momentumDrawCards = tonumber(card.momentumDrawCards) or 0,
            momentumGuardValue = tonumber(card.momentumGuardValue) or 0,
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
        local preview = nil
        if type(intent.preview) == "table" then
            local keywords = {}
            for index, keyword in ipairs(intent.preview.keywords or {}) do
                keywords[index] = keyword
            end
            preview = {
                damageDice = intent.preview.damageDice,
                expectedDamage = intent.preview.expectedDamage,
                targetCount = intent.preview.targetCount,
                isAoe = intent.preview.isAoe == true,
                saveType = intent.preview.saveType,
                keywords = keywords,
                summary = intent.preview.summary,
            }
        end
        result[i] = {
            enemyInstanceId = intent.enemyInstanceId,
            enemyName = intent.enemyName,
            type = intent.type or "attack",
            skillId = intent.skillId,
            skillName = intent.skillName,
            targetIds = targetIds,
            targetNames = targetNames,
            preview = preview,
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
        momentum = tonumber(state.momentum) or 0,
        momentumMax = tonumber(state.momentumMax) or DEFAULTS.momentumMax,
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
