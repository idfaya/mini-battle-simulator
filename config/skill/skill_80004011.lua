local skill_80004011 = {}

function skill_80004011.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    return {
        { frame = 0, op = "cast", effect = "paladin_basic_attack_cast", targetRef = "selected" },
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
        { frame = 24, op = "effect", effect = "paladin_basic_attack_end", targetRef = "selected" },
    }
end

return skill_80004011
