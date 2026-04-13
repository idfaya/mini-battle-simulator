skill_80009003 = {}

function skill_80009003.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local timeline = {}
    local frame = 8

    for hitIndex = 1, 4 do
        table.insert(timeline, {
            frame = frame,
            op = "chain_damage",
            effect = "chain_lightning_arc",
            execute = function(ctx, frameData)
                local picked = BattleSkill.SelectRandomAliveEnemies(hero, 1)
                local target = picked and picked[1] or nil
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
