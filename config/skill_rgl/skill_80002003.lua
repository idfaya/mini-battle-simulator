skill_80002003 = {}

function skill_80002003.Execute(hero, targets, skill)
    local BattleFormation = require("modules.battle_formation")
    hero.rglCounterStanceHits = 1
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        if enemy and not enemy.isDead then
            enemy.rglForcedTargetId = hero.instanceId
        end
    end
    return true
end

return skill_80002003
