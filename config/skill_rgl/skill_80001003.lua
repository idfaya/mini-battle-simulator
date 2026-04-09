skill_80001003 = {}

function skill_80001003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local target = BattleSkill.SelectLowestHpEnemy(hero)
    if not target then
        return false
    end
    local damage = BattleSkill.CalculateDamageWithRate(hero, target, 20000)
    BattleDmgHeal.ApplyDamage(target, damage, hero)
    if target.isDead then
        BattleSkill.ProcessPursuitEffect(hero, target, skill)
    end
    return damage > 0
end

return skill_80001003
