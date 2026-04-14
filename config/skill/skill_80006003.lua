skill_80006003 = {}

function skill_80006003.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80006003_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80006003_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80006003.Execute(hero, targets, skill)
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
function skill_80006003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    BattleSkill.ProcessGroupHeal(hero, skill)
    return true
end

return skill_80006003

