local skill_80005011 = {}

function skill_80005011.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local primaryTarget = targets and targets[1] or nil
    return {
        { frame = 0, op = "cast", effect = "ranger_basic_attack_cast", target = primaryTarget },
        { frame = 12, op = "projectile", effect = "ranger_basic_attack_projectile", target = primaryTarget },
        {
            frame = 24,
            op = "attack",
            target = primaryTarget,
            execute = function()
                local damage = BattleSkill.ExecuteDefaultAttackWithPassive(hero, targets, skill) or 0
                return {
                    damage = damage,
                    targets = targets,
                }
            end,
        },
        { frame = 36, op = "effect", effect = "ranger_basic_attack_end", target = primaryTarget },
    }
end

return skill_80005011
