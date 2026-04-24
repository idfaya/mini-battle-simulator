local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80003003 = {}

local DEF = {
    id = 80003003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80003003_cast", targetRef = "self" },
        { frame = 24, op = "heal", effect = "skill_80003003_heal", targetRef = "self", healDice = "1d8+3" },
        {
            frame = 30,
            op = "effect",
            effect = "skill_80003003_cleanse",
            targetRef = "self",
            tags = {
                { tag = "remove_buff_by_subtype", phase = "pre", param = { subType = E_BUFF_SPEC_SUBTYPE.Frozen } },
                { tag = "remove_buff_by_subtype", phase = "pre", param = { subType = E_BUFF_SPEC_SUBTYPE.STUN } },
                { tag = "remove_buff_by_subtype", phase = "pre", param = { subType = E_BUFF_SPEC_SUBTYPE.SILENT } },
            },
        },
        { frame = 45, op = "effect", effect = "skill_80003003_end", targetRef = "selected" },
    },
}

function skill_80003003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80003003




