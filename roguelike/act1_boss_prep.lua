local RoguelikeRoster = require("roguelike.roguelike_roster")

local Act1BossPrep = {}

Act1BossPrep.HEAL_PCT = 0.35
Act1BossPrep.REVIVE_PCT = 0.50

function Act1BossPrep.Apply(runState)
    if not runState then
        return false
    end
    if runState.act1BossPrepUsed == true then
        return false
    end

    local changed = false
    local revived = false
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState) or {}) do
        local maxHp = tonumber(hero.maxHp) or 0
        if hero.isDead and revived ~= true and maxHp > 0 then
            hero.isDead = false
            hero.teamState = "active"
            hero.currentHp = math.max(1, math.floor(maxHp * Act1BossPrep.REVIVE_PCT))
            revived = true
            changed = true
        elseif not hero.isDead and (tonumber(hero.currentHp) or 0) > 0 then
            local heal = math.floor(maxHp * Act1BossPrep.HEAL_PCT)
            if heal > 0 then
                hero.currentHp = math.min(maxHp, (tonumber(hero.currentHp) or 0) + heal)
                changed = true
            end
        end
    end

    runState.act1BossPrepUsed = true
    if changed then
        runState.lastActionMessage = "终局整备：复活 1 名队员，存活队员恢复 35% 生命"
    end
    return changed
end

return Act1BossPrep
