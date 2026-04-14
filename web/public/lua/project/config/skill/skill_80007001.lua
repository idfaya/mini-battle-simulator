skill_80007001 = {}

function skill_80007001.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local timeline = {}

    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            table.insert(timeline, {
                frame = 0,
                op = "cast",
                effect = "fireball_cast",
                target = target,
            })
            table.insert(timeline, {
                frame = 12,
                op = "projectile",
                effect = "fireball_projectile",
                target = target,
            })
            table.insert(timeline, {
                frame = 24,
                op = "damage",
                effect = "fireball_hit",
                target = target,
                execute = function(ctx, frame)
                    local damage = BattleSkill.CalculateDamageWithRate(hero, target, 12000)
                    BattleDmgHeal.ApplyDamage(target, damage, hero)
                    BattleSkill.ApplyBurn(target, 1, 2, hero)
                    return {
                        target = target,
                        damage = damage,
                        buffId = 870001,
                    }
                end
            })
        end
    end

    return timeline
end

function skill_80007001.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            local damage = BattleSkill.CalculateDamageWithRate(hero, target, 12000)
            BattleDmgHeal.ApplyDamage(target, damage, hero)
            BattleSkill.ApplyBurn(target, 1, 2, hero)
            totalDamage = totalDamage + damage
        end
    end
    return totalDamage > 0
end

return skill_80007001
