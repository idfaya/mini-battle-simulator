skill_80007004 = {}

function skill_80007004.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80007004_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80007004_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80007004.Execute(hero, targets, skill)
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
function skill_80007004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectAllAliveTargets(hero)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, 20000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        BattleSkill.ApplyBurn(target, 3, 3, hero)
        totalDamage = totalDamage + damage
    end
    return totalDamage > 0
end

return skill_80007004

