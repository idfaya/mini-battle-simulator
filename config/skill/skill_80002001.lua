local skill_80002001 = {}

function skill_80002001.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    return {
        { frame = 0, op = "cast", effect = "fighter_basic_attack_cast", targetRef = "selected" },
        {
            frame = 12,
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
        { frame = 24, op = "effect", effect = "fighter_basic_attack_end", targetRef = "selected" },
    }
end

return skill_80002001


