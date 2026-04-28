local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80009003 = {}

function skill_80009003.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local tier = tonumber(skill and skill.level) or 1
    local chainTargets = BattleSkill.GetChainTargets(hero, targets and targets[1] or nil, 4 + math.max(0, tier - 1))
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
            damageRate = 7000 + math.max(0, tier - 1) * 500,
            chainIndex = hitIndex,
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


