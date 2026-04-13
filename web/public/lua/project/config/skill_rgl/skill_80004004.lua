skill_80004004 = {}

function skill_80004004.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80004004_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80004004_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80004004.Execute(hero, targets, skill)
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
function skill_80004004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleFormation = require("modules.battle_formation")
    local allies = BattleFormation.GetFriendTeam(hero)
    return (BattleSkill.ApplyBuffToTargets(hero, allies, skill) or 0) > 0
end

return skill_80004004

