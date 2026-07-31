local RoguelikeRoster = require("roguelike.roguelike_roster")

local ChapterClearPrep = {}

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

    return changed
end

return ChapterClearPrep
