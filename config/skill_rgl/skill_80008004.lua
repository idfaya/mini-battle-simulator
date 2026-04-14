skill_80008004 = {}

function skill_80008004.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80008004_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80008004_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80008004.Execute(hero, targets, skill)
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
function skill_80008004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local damageRate = BattleSkill.GetPassiveAdjustedRate(hero, 15000, "iceDamageBonusPct")
    local freezeChance = BattleSkill.GetPassiveAdjustedChance(hero, 5000, "iceFreezeChanceBonus")
    local totalDamage = 0
    for _, target in ipairs(BattleSkill.SelectAllAliveTargets(hero)) do
        local damage = BattleSkill.CalculateDamageWithRate(hero, target, damageRate)
        BattleDmgHeal.ApplyDamage(target, damage, hero)
        if math.random(1, 10000) <= freezeChance then
            BattleSkill.ApplyFreeze(target, 1, 3000, hero)
        end
        totalDamage = totalDamage + damage
    end
    return totalDamage > 0
end

return skill_80008004
