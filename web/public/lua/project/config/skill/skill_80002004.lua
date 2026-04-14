skill_80002004 = {}

function skill_80002004.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80002004_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80002004_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80002004.Execute(hero, targets, skill)
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
function skill_80002004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleBuff = require("modules.battle_buff")
    BattleBuff.DelBuffBySubType(hero, 820002)
    BattleSkill.ApplyBuffFromSkill(hero, hero, 820003, skill)
    return true
end

return skill_80002004

