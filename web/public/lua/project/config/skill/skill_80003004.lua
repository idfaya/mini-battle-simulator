skill_80003004 = {}

function skill_80003004.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80003004_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80003004_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80003004.Execute(hero, targets, skill)
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
function skill_80003004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _ = 1, 6 do
        local randomTarget = BattleSkill.SelectRandomAliveEnemies(hero, 1)
        if randomTarget and randomTarget[1] then
            local damage = BattleSkill.CalculateDamageWithRate(hero, randomTarget[1], 10000)
            BattleDmgHeal.ApplyDamage(randomTarget[1], damage, hero)
            totalDamage = totalDamage + damage
            if randomTarget[1].isDead then
                BattleSkill.ProcessPursuitEffect(hero, randomTarget[1], skill)
            end
        end
    end
    return totalDamage > 0
end

return skill_80003004

