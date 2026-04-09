skill_80008003 = {}

function skill_80008003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectAllAliveTargets(hero)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        BattleSkill.ApplyFreeze(target, 2, 3000)
        totalDamage = totalDamage + damage
    end
    return totalDamage > 0
end

return skill_80008003
