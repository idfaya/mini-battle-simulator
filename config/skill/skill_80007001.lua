local SkillTimelineCompiler = require("skills.skill_timeline_compiler")
local Skill5eMeta = require("config.tables.skill_meta")

local skill_80007001 = {}

local function getProjectileCountDelta(hero, skillId)
    local buildState = hero and hero.buildState or nil
    local skillMods = buildState and buildState.skillMods or nil
    local entry = skillMods and skillMods[skillId] or nil
    return math.max(0, math.floor(tonumber(entry and entry.projectileCountDelta) or 0))
end

function skill_80007001.BuildTimeline(hero, targets, skill)
    local BattleFormation = require("modules.battle_formation")
    local skillId = skill and skill.skillId or 80007001
    local tier = tonumber(skill and skill.level) or 1
    local damageDice = Skill5eMeta.ResolveStageDamageDice(skillId, tier)
    local projectileDelta = getProjectileCountDelta(hero, skillId)
    local shotTargets = {}
    local picked = {}
    for _, target in ipairs(targets or {}) do
        local targetId = tonumber(target and (target.instanceId or target.id)) or 0
        if target and not target.isDead and targetId ~= 0 and not picked[targetId] then
            picked[targetId] = true
            shotTargets[#shotTargets + 1] = target
        end
    end
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        if projectileDelta <= 0 then
            break
        end
        local enemyId = tonumber(enemy and (enemy.instanceId or enemy.id)) or 0
        if enemy and not enemy.isDead and enemyId ~= 0 and not picked[enemyId] then
            picked[enemyId] = true
            shotTargets[#shotTargets + 1] = enemy
            projectileDelta = projectileDelta - 1
        end
    end
    if projectileDelta > 0 and #shotTargets > 0 then
        for index = 1, projectileDelta do
            local fallback = shotTargets[((index - 1) % #shotTargets) + 1]
            shotTargets[#shotTargets + 1] = fallback
        end
    end
    local frames = {}
    for _, t in ipairs(shotTargets) do
        if t and not t.isDead then
            table.insert(frames, { frame = 0, op = "cast", effect = "fireball_cast", target = t })
            table.insert(frames, { frame = 12, op = "projectile", effect = "fireball_projectile", target = t })
            table.insert(frames, {
                frame = 24,
                op = "damage",
                effect = "fire_bolt_hit",
                target = t,
                damageDice = damageDice,
                tags = {
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "fire" } },
                    { tag = "apply_burn_refresh_only", phase = "post", param = { turns = 2 } },
                },
            })
        end
    end

    return SkillTimelineCompiler.Build(hero, targets, skill, { id = 80007001, frames = frames })
end

return skill_80007001


