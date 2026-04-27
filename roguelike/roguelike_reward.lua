local RunRewardPool = require("config.roguelike.run_reward_pool")
local RunRelicConfig = require("config.roguelike.run_relic_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local HeroData = require("config.hero_data")

local RoguelikeReward = {}
local RECRUIT_LEVEL = 1
local RECRUIT_STAR = 1

local function allocateRosterId(runState)
    runState.nextRosterId = (runState.nextRosterId or 1)
    local rosterId = runState.nextRosterId
    runState.nextRosterId = rosterId + 1
    return rosterId
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function containsHeroId(roster, heroId)
    for _, hero in ipairs(roster or {}) do
        if tonumber(hero.heroId) == tonumber(heroId) then
            return true
        end
    end
    return false
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
    if entry.rewardType == "heal_pct" then
        return string.format("全队治疗 %.0f%%", (tonumber(entry.value) or 0) * 100)
    end
    if entry.rewardType == "relic" then
        local relic = RunRelicConfig.GetRelic(entry.refId)
        return relic and relic.name or ("Relic " .. tostring(entry.refId))
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.name or ("Blessing " .. tostring(entry.refId))
    end
    if entry.rewardType == "recruit" then
        return "招募 " .. HeroData.GetHeroName(entry.refId)
    end
    return tostring(entry.rewardType or "reward")
end

local function buildDescription(entry)
    if entry.rewardType == "relic" then
        local relic = RunRelicConfig.GetRelic(entry.refId)
        return relic and relic.code or ""
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.code or ""
    end
    if entry.rewardType == "recruit" then
        return HeroData.GetClassName((HeroData.GetHeroInfo(entry.refId) or {}).Class or 0)
    end
    return ""
end

local function applyTeamHeal(runState, healPct)
    for _, hero in ipairs(runState.teamRoster or {}) do
        if not hero.isDead then
            local heal = math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0))
            hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
        end
    end
end

local function addUnique(list, value)
    if not contains(list, value) then
        list[#list + 1] = value
    end
end

local function createHeroRecord(runState, heroId)
    local recruitLevel = math.max(RECRUIT_LEVEL, tonumber(runState and runState.partyLevel) or RECRUIT_LEVEL)
    local attrs = HeroData.CalculateHeroAttributes(heroId, recruitLevel, RECRUIT_STAR)
    local heroInfo = HeroData.GetHeroInfo(heroId)
    if not attrs or not heroInfo then
        return nil
    end

    return {
        rosterId = allocateRosterId(runState),
        heroId = heroId,
        name = HeroData.GetHeroName(heroId),
        classId = heroInfo.Class or 0,
        level = attrs.level or recruitLevel,
        star = attrs.star or RECRUIT_STAR,
        maxHp = attrs.maxHp,
        currentHp = attrs.maxHp,
        isDead = false,
        source = "reward",
    }
end

function RoguelikeReward.AddRecruit(runState, heroId, options)
    local recruitOptions = options or {}
    local heroRecord = createHeroRecord(runState, heroId)
    if not heroRecord then
        return false, "invalid_recruit"
    end
    heroRecord.ultimateChargesMax = heroRecord.ultimateChargesMax or 1
    heroRecord.ultimateCharges = heroRecord.ultimateCharges or heroRecord.ultimateChargesMax

    if recruitOptions.forceBench then
        runState.benchRoster[#runState.benchRoster + 1] = heroRecord
        runState.lastActionMessage = "新招募已加入候补"
        return true, heroRecord
    end

    for index, rosterHero in ipairs(runState.teamRoster or {}) do
        if rosterHero.isDead or (tonumber(rosterHero.currentHp) or 0) <= 0 then
            runState.teamRoster[index] = heroRecord
            runState.lastActionMessage = "新招募已补入上阵空缺"
            return true, heroRecord
        end
    end

    if #(runState.teamRoster or {}) < (runState.maxHeroCount or 5) then
        runState.teamRoster[#runState.teamRoster + 1] = heroRecord
        runState.lastActionMessage = "新招募已直接加入上阵队伍"
    else
        runState.benchRoster[#runState.benchRoster + 1] = heroRecord
        runState.lastActionMessage = "新招募已加入候补"
    end

    return true, heroRecord
end

function RoguelikeReward.GenerateRecruitRewardState(runState, optionCount)
    local count = math.max(1, tonumber(optionCount) or 3)
    local pool = HeroData.GetAllHeroIds() or {}
    local candidates = {}
    for _, heroId in ipairs(pool) do
        if not containsHeroId(runState.teamRoster, heroId) and not containsHeroId(runState.benchRoster, heroId) then
            candidates[#candidates + 1] = heroId
        end
    end
    if #candidates < count then
        candidates = {}
        for _, heroId in ipairs(pool) do
            candidates[#candidates + 1] = heroId
        end
    end

    local options = {}
    local picked = {}
    while #options < count and #picked < #candidates do
        local idx = math.random(1, #candidates)
        local heroId = candidates[idx]
        if not picked[heroId] then
            picked[heroId] = true
            options[#options + 1] = {
                rewardType = "recruit",
                refId = heroId,
                label = "招募 " .. HeroData.GetHeroName(heroId),
                description = HeroData.GetClassName((HeroData.GetHeroInfo(heroId) or {}).Class or 0),
            }
        end
    end

    return {
        groupId = 0,
        kind = "battle_recruit",
        options = options,
    }
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
                options[#options + 1] = {
                    rewardType = entry.rewardType,
                    refId = entry.refId,
                    value = entry.value,
                    label = buildLabel(entry),
                    description = buildDescription(entry),
                }
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
        options[#options + 1] = {
            rewardType = entry.rewardType,
            refId = entry.refId,
            value = entry.value,
            label = buildLabel(entry),
            description = buildDescription(entry),
        }
    end

    return {
        groupId = groupId,
        kind = group.kind,
        options = options,
    }
end

function RoguelikeReward.ApplyReward(runState, rewardState, index)
    local option = rewardState and rewardState.options and rewardState.options[index] or nil
    if not option then
        return false, "invalid_reward"
    end

    if option.rewardType == "gold" then
        runState.gold = (runState.gold or 0) + (option.value or 0)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "heal_pct" then
        applyTeamHeal(runState, option.value)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "relic" then
        addUnique(runState.relicIds, option.refId)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "blessing" then
        addUnique(runState.blessingIds, option.refId)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "recruit" then
        local added, reason = RoguelikeReward.AddRecruit(runState, option.refId)
        if not added then
            return false, reason
        end
        if not runState.lastActionMessage or runState.lastActionMessage == "" then
            runState.lastActionMessage = option.label
        end
    else
        return false, "unsupported_reward"
    end

    return true
end

return RoguelikeReward
