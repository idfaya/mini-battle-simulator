local RoguelikeRoster = require("roguelike.roguelike_roster")
local HeroData = require("config.hero_data")

local ChapterClearPrep = {}

local function collectOwnedClassIds(runState)
    local owned = {}
    for _, hero in ipairs(runState.ownedUnits or {}) do
        local classId = tonumber(hero.classId or hero.class or hero.Class) or 0
        if classId > 0 then
            owned[classId] = true
        end
    end
    return owned
end

local function buildRecruitOptions(runState, classIds, limit)
    local owned = collectOwnedClassIds(runState)
    local options = {}
    local seen = {}
    local function addOption(classId)
        local resolvedClassId = tonumber(classId) or 0
        if resolvedClassId <= 0 or seen[resolvedClassId] then
            return
        end
        local heroId = HeroData.GetRepresentativeHeroId(resolvedClassId)
        if not heroId then
            return
        end
        seen[resolvedClassId] = true
        local className = HeroData.GetClassName(resolvedClassId) or ("Class " .. tostring(resolvedClassId))
        options[#options + 1] = {
            rewardType = "recruit",
            refId = resolvedClassId,
            classId = resolvedClassId,
            label = className,
            description = "招募新队员并直接加入出战队伍",
            resultType = "new_class_unit",
            teamState = "active",
            summaryKey = HeroData.GetClassCardSummaryKey(resolvedClassId, "low"),
        }
    end

    for _, classId in ipairs(classIds or {}) do
        local resolvedClassId = tonumber(classId) or 0
        if resolvedClassId > 0 and owned[resolvedClassId] ~= true then
            addOption(resolvedClassId)
            if #options >= limit then
                return options
            end
        end
    end

    for _, classId in ipairs(classIds or {}) do
        addOption(classId)
        if #options >= limit then
            break
        end
    end
    return options
end

function ChapterClearPrep.BuildRecruitRewardState(runState, clearRewards)
    if not runState or type(clearRewards) ~= "table" then
        return nil
    end
    local targetTeamSize = math.max(0, math.floor(tonumber(clearRewards.targetTeamSize) or 0))
    if targetTeamSize <= 0 or #RoguelikeRoster.GetTeamUnits(runState) >= targetTeamSize then
        return nil
    end
    runState.maxHeroCount = math.max(tonumber(runState.maxHeroCount) or 0, targetTeamSize)

    local options = buildRecruitOptions(runState, clearRewards.recruitClassIds or {}, 3)
    if #options <= 0 then
        return nil
    end
    return {
        groupId = 0,
        kind = "node_recruit",
        source = "chapter_clear",
        targetTeamSize = targetTeamSize,
        options = options,
    }
end

function ChapterClearPrep.Apply(runState, clearRewards)
    if not runState or type(clearRewards) ~= "table" then
        return false
    end

    local healPct = tonumber(clearRewards.healPct) or 0
    local reviveCount = math.max(0, math.floor(tonumber(clearRewards.reviveCount) or 0))
    local revivePct = tonumber(clearRewards.revivePct) or 0
    local changed = false

    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState) or {}) do
        local maxHp = tonumber(hero.maxHp) or 0
        if hero.isDead and reviveCount > 0 and revivePct > 0 and maxHp > 0 then
            hero.isDead = false
            hero.teamState = "active"
            hero.currentHp = math.max(1, math.floor(maxHp * revivePct))
            reviveCount = reviveCount - 1
            changed = true
        elseif not hero.isDead and healPct > 0 and maxHp > 0 then
            local heal = math.floor(maxHp * healPct)
            if heal > 0 then
                hero.currentHp = math.min(maxHp, (tonumber(hero.currentHp) or 0) + heal)
                changed = true
            end
        end
    end

    local targetTeamSize = math.max(0, math.floor(tonumber(clearRewards.targetTeamSize) or 0))
    if targetTeamSize > 0 and (tonumber(runState.maxHeroCount) or 0) < targetTeamSize then
        runState.maxHeroCount = targetTeamSize
        changed = true
    end

    return changed
end

return ChapterClearPrep
