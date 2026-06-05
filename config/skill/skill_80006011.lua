local skill_80006011 = {}

function skill_80006011.BuildTimeline(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local ClericBuildPassives = require("skills.cleric_build_passives")

    local function resolveTarget(ctx)
        return ctx and ctx.targets and ctx.targets[1] or nil
    end

    return {
        { frame = 0, op = "cast", effect = "cleric_basic_spell_cast", targetRef = "selected" },
        {
            frame = 10,
            op = "projectile",
            effect = "cleric_basic_spell_projectile",
            targetRef = "selected",
            execute = function(ctx)
                local target = resolveTarget(ctx)
                if not target then
                    return { targets = {} }
                end
                return { targets = { target } }
            end,
        },
        {
            frame = 20,
            op = "attack",
            effect = "cleric_basic_spell_execute",
            targetRef = "selected",
            execute = function(ctx)
                local resolvedTarget = resolveTarget(ctx)
                local amount = ClericBuildPassives.PerformBasicSpellAttack(ctx.hero, resolvedTarget, skill)
                return {
                    damage = amount,
                    targets = resolvedTarget and { resolvedTarget } or {},
                }
            end,
        },
        { frame = 36, op = "effect", effect = "cleric_basic_spell_end", targetRef = "selected" },
    }
end

return skill_80006011
