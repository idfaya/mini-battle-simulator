skill_80009003 = {}

function skill_80009003.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local chainTargets = BattleSkill.GetChainTargets(hero, targets and targets[1] or nil, 4)
    local timeline = {}
    local frame = 8

    for hitIndex, chainTarget in ipairs(chainTargets) do
        table.insert(timeline, {
            frame = frame,
            op = "chain_damage",
            effect = "chain_lightning_arc",
            execute = function(ctx, frameData)
                local target = chainTarget
                if not target or target.isDead then
                    return { damage = 0 }
                end
                local damage = BattleSkill.CalculateDamageWithRate(hero, target, 10000)
                BattleDmgHeal.ApplyDamage(target, damage, hero)
                return {
                    target = target,
                    damage = damage,
                    chainIndex = hitIndex,
                }
            end
        })
        frame = frame + 6
    end

    return timeline
end

function skill_80009003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    BattleSkill.ProcessChainLightning(hero, 4, 10000)
    return true
end

return skill_80009003
