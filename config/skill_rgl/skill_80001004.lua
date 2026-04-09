skill_80001004 = {}

function skill_80001004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectAllAliveTargets(hero)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, 20000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        totalDamage = totalDamage + damage
        if target.isDead then
            BattleSkill.ProcessPursuitEffect(hero, target, skill)
        end
    end
    return totalDamage > 0
end

return skill_80001004
