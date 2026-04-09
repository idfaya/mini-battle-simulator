skill_80009004 = {}

function skill_80009004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectAllAliveTargets(hero)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        totalDamage = totalDamage + damage
    end
    totalDamage = totalDamage + BattleSkill.ProcessChainLightning(hero, 3, 10000)
    return totalDamage > 0
end

return skill_80009004
