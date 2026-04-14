skill_80002001 = {}

function skill_80002001.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80002001_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80002001_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80002001.Execute(hero, targets, skill)
                local scriptDamage = hero.__scriptDamageAccumulator or 0
                hero.__scriptDamageAccumulator = nil
                if result ~= false and result ~= nil or scriptDamage > 0 then
                    return {
                        damage = scriptDamage,
                        targets = targets,
                    }
                end
                return {
                    damage = 0,
                    targets = targets,
                }
            end
        }
    }
end
function skill_80002001.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
            BattleDmgHeal.ApplyDamage(target, damage, hero)
            BattleSkill.ApplyBuffFromSkill(hero, target, 820001, skill)
            totalDamage = totalDamage + damage
        end
    end
    return totalDamage > 0
end

return skill_80002001

