skill_80008001 = {}

function skill_80008001.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
            BattleDmgHeal.ApplyDamage(target, damage, hero)
            BattleSkill.ApplyFreeze(target, 0, 3000)
            totalDamage = totalDamage + damage
        end
    end
    return totalDamage > 0
end

return skill_80008001
