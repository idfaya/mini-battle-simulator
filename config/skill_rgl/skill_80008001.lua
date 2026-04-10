skill_80008001 = {}

function skill_80008001.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local timeline = {}

    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            table.insert(timeline, {
                frame = 0,
                op = "cast",
                effect = "ice_arrow_cast",
                target = target,
            })
            table.insert(timeline, {
                frame = 10,
                op = "projectile",
                effect = "ice_arrow_projectile",
                target = target,
            })
            table.insert(timeline, {
                frame = 20,
                op = "damage",
                effect = "ice_arrow_hit",
                target = target,
                execute = function(ctx, frame)
                    local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
                    BattleDmgHeal.ApplyDamage(target, damage, hero)
                    BattleSkill.ApplyFreeze(target, 0, 3000, hero)
                    return {
                        target = target,
                        damage = damage,
                        buffId = 880001,
                    }
                end
            })
        end
    end

    return timeline
end

function skill_80008001.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
            BattleDmgHeal.ApplyDamage(target, damage, hero)
            BattleSkill.ApplyFreeze(target, 0, 3000, hero)
            totalDamage = totalDamage + damage
        end
    end
    return totalDamage > 0
end

return skill_80008001
