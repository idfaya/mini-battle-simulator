skill_80003001 = {}

function skill_80003001.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80003001_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80003001_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80003001.Execute(hero, targets, skill)
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
function skill_80003001.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
            BattleDmgHeal.ApplyDamage(target, damage, hero)
            totalDamage = totalDamage + damage
            local extraHits = BattleSkill.ProcessComboEffect(hero, {target}, skill)
            for _ = 1, extraHits do
                BattleSkill.CastSmallSkill(hero, target)
            end
        end
    end
    return totalDamage > 0
end

return skill_80003001

