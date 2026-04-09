skill_80008004 = {}

function skill_80008004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectAllAliveTargets(hero)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, 15000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        if math.random(1, 10000) <= 5000 then
            BattleSkill.ApplyFreeze(target, 2, 3000)
        end
        totalDamage = totalDamage + damage
    end
    return totalDamage > 0
end

return skill_80008004
