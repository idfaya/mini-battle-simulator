skill_80009001 = {}

function skill_80009001.BuildTimeline(hero, targets, skill)
    return {
        {
            frame = 0,
            op = "cast",
            effect = "skill_80009001_cast",
            targets = targets,
        },
        {
            frame = 12,
            op = "execute",
            effect = "skill_80009001_execute",
            targets = targets,
            execute = function(ctx, frame)
                hero.__scriptDamageAccumulator = 0
                local result = skill_80009001.Execute(hero, targets, skill)
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
function skill_80009001.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _, target in ipairs(targets or {}) do
        if target and not target.isDead then
            local damage = BattleSkill.CalculateDamageWithRate(hero, target, 11000)
            BattleDmgHeal.ApplyDamage(target, damage, hero)
            totalDamage = totalDamage + damage
        end
    end
    local chance = 2000
    if hero.skills then
        for _, s in ipairs(hero.skills) do
            if s.name == "雷电亲和" then
                chance = 4000
                break
            end
        end
    end
    if math.random(1, 10000) <= chance then
        BattleSkill.ProcessChainLightning(hero, 1, 10000)
    end
    return totalDamage > 0
end

return skill_80009001

