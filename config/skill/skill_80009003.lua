local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80009003 = {}

function skill_80009003.BuildTimeline(hero, targets, skill)
    local BattleFormation = require("modules.battle_formation")
    local BattleBuff = require("modules.battle_buff")
    local firstTarget = targets and targets[1] or nil
    local chainTargets = {}
    if firstTarget and not firstTarget.isDead then
        chainTargets[#chainTargets + 1] = firstTarget
    end
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        if enemy and not enemy.isDead and enemy ~= firstTarget and BattleBuff.GetBuff(enemy, 890001) then
            chainTargets[#chainTargets + 1] = enemy
            break
        end
    end
    if #chainTargets < 2 then
        for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
            if enemy and not enemy.isDead and enemy ~= firstTarget then
                chainTargets[#chainTargets + 1] = enemy
                break
            end
        end
    end
    local frames = {}
    local frame = 12

    if chainTargets and chainTargets[1] then
        table.insert(frames, {
            frame = 0,
            op = "cast",
            effect = "chain_lightning_cast",
            target = chainTargets[1],
        })
    end

    for hitIndex, chainTarget in ipairs(chainTargets or {}) do
        table.insert(frames, {
            frame = frame,
            op = "chain_damage",
            effect = "chain_lightning_arc",
            target = chainTarget,
            damageRate = hitIndex == 1 and 9000 or 7000,
            chainIndex = hitIndex,
            tags = {
                { tag = "set_damage_kind", phase = "pre", param = { kind = "thunder" } },
            },
        })
        frame = frame + 8
    end

    if chainTargets and chainTargets[1] then
        table.insert(frames, {
            frame = 45,
            op = "effect",
            effect = "chain_lightning_end",
            target = chainTargets[1],
        })
    end

    return SkillTimelineCompiler.Build(hero, targets, skill, { id = 80009003, frames = frames })
end

return skill_80009003

