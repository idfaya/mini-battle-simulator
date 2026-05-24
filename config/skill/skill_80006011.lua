local skill_80006011 = {}

function skill_80006011.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local ClericBuildPassives = require("skills.cleric_build_passives")
    local target = targets and targets[1] or nil
    local healAlly = target and BattleSkill.IsAlly(hero, target)

    local frames = {
        { frame = 0, op = "cast", effect = "cleric_basic_spell_cast", targetRef = "selected" },
    }

    if not healAlly then
        frames[#frames + 1] = { frame = 10, op = "projectile", effect = "cleric_basic_spell_projectile", targetRef = "selected" }
    end

    frames[#frames + 1] = {
        frame = healAlly and 14 or 20,
        op = "attack",
        effect = "cleric_basic_spell_execute",
        targetRef = "selected",
        execute = function()
            local resolvedTarget = targets and targets[1] or nil
            local damage = ClericBuildPassives.PerformBasicSpellAttack(hero, resolvedTarget, skill)
            return {
                damage = damage,
                targets = resolvedTarget and { resolvedTarget } or {},
            }
        end,
    }
    frames[#frames + 1] = {
        frame = healAlly and 30 or 36,
        op = "effect",
        effect = "cleric_basic_spell_end",
        targetRef = "selected",
    }

    return frames
end

return skill_80006011
