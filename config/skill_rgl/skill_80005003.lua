skill_80005003 = {}

function skill_80005003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectRandomAliveEnemies(hero, 3)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        BattleSkill.ApplyPoison(target, 2)
        totalDamage = totalDamage + damage
    end
    return totalDamage > 0
end

return skill_80005003
