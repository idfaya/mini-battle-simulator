local skill_80005011 = {}

function skill_80005011.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    return {
        { frame = 0, op = "cast", effect = "ranger_basic_attack_cast", targetRef = "selected" },
        { frame = 12, op = "projectile", effect = "ranger_basic_attack_projectile", targetRef = "selected" },
        {
            frame = 24,
            op = "attack",
            targetRef = "selected",
            execute = function()
                local damage = BattleSkill.ExecuteDefaultAttackWithPassive(hero, targets, skill) or 0
                return {
                    damage = damage,
                    targets = targets,
                }
            end,
        },
        { frame = 36, op = "effect", effect = "ranger_basic_attack_end", targetRef = "selected" },
    }
end

return skill_80005011
