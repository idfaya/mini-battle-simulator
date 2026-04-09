skill_80007004 = {}

function skill_80007004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectAllAliveTargets(hero)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, 30000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        BattleSkill.ApplyBurn(target, 3, 3, hero)
        totalDamage = totalDamage + damage
    end
    return totalDamage > 0
end

return skill_80007004
