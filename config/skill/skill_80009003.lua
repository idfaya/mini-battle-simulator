local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80009003 = {}

function skill_80009003.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local chainTargets = BattleSkill.GetChainTargets(hero, targets and targets[1] or nil, 4)
    local frames = {}
    local frame = 8

    for hitIndex, chainTarget in ipairs(chainTargets or {}) do
        table.insert(frames, {
            frame = frame,
            op = "chain_damage",
            effect = "chain_lightning_arc",
            target = chainTarget,
            damageRate = 10000,
            chainIndex = hitIndex,
        })
        frame = frame + 6
    end

    return SkillTimelineCompiler.Build(hero, targets, skill, { id = 80009003, frames = frames })
end

return skill_80009003




