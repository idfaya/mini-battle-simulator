skill_80002003 = {}

function skill_80002003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleFormation = require("modules.battle_formation")
    BattleSkill.ApplyBuffFromSkill(hero, hero, 820002, skill)
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        if enemy and not enemy.isDead then
            BattleSkill.ApplyBuffFromSkill(hero, enemy, 820001, skill)
        end
    end
    return true
end

return skill_80002003
