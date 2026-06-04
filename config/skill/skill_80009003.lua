local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80009003 = {}

local function getSkillEntry(hero, skillId)
    local buildState = hero and hero.buildState or nil
    local skillMods = buildState and buildState.skillMods or nil
    local entry = skillMods and skillMods[skillId] or nil
    return type(entry) == "table" and entry or nil
end

local function getSkillModInt(hero, skillId, key)
    local entry = getSkillEntry(hero, skillId)
    return math.max(0, math.floor(tonumber(entry and entry[key]) or 0))
end

local function hasSkillFlag(hero, skillId, key)
    local entry = getSkillEntry(hero, skillId)
    return entry and entry[key] == true or false
end

local function getSkillModString(hero, skillId, key)
    local entry = getSkillEntry(hero, skillId)
    local value = entry and entry[key] or nil
    return type(value) == "string" and value or nil
end

local function joinDiceParts(a, b)
    a = tostring(a or ""):gsub("^%s+", ""):gsub("%s+$", "")
    b = tostring(b or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if a == "" then
        return b
    end
    if b == "" then
        return a
    end
    return a .. ";" .. b
end

function skill_80009003.BuildTimeline(hero, targets, skill)
    local BattleFormation = require("modules.battle_formation")
    local BattleBuff = require("modules.battle_buff")
    local skillId = skill and skill.skillId or 80009003
    local preferMarked = hasSkillFlag(hero, skillId, "prioritizeMarkedTargets")
    local bonusFirstHopDice = getSkillModString(hero, skillId, "firstHopVsMarkBonusDice")
    local bonusLastHopDice = getSkillModString(hero, skillId, "lastHopBonusDice")
    local extraHits = getSkillModInt(hero, skillId, "chainCountDelta")
    local markDurationDelta = getSkillModInt(hero, skillId, "onHitMarkDurationDelta")
    local totalHits = 2 + extraHits
    local firstTarget = targets and targets[1] or nil
    local chainTargets = {}
    local picked = {}
    if firstTarget and not firstTarget.isDead then
        chainTargets[#chainTargets + 1] = firstTarget
        picked[tonumber(firstTarget.instanceId or firstTarget.id) or 0] = true
    end
    while #chainTargets < totalHits do
        local marked = {}
        local normal = {}
        for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
            local enemyId = tonumber(enemy and (enemy.instanceId or enemy.id)) or 0
            if enemy and not enemy.isDead and not picked[enemyId] then
                normal[#normal + 1] = enemy
                if BattleBuff.GetBuff(enemy, 890001) then
                    marked[#marked + 1] = enemy
                end
            end
        end
        local pool = normal
        if preferMarked and #marked > 0 then
            pool = marked
        end
        if #pool == 0 then
            break
        end
        local nextTarget = pool[1]
        local nextId = tonumber(nextTarget.instanceId or nextTarget.id) or 0
        picked[nextId] = true
        chainTargets[#chainTargets + 1] = nextTarget
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
        table.insert(frames, {
            frame = 8,
            op = "projectile",
            effect = "chain_lightning_projectile",
            target = chainTargets[1],
        })
    end

    for hitIndex, chainTarget in ipairs(chainTargets or {}) do
        local bonusDamageDice = nil
        if hitIndex == 1 and type(bonusFirstHopDice) == "string" and bonusFirstHopDice ~= "" and BattleBuff.GetBuff(chainTarget, 890001) then
            bonusDamageDice = joinDiceParts(bonusDamageDice, bonusFirstHopDice)
        end
        if hitIndex == #chainTargets and type(bonusLastHopDice) == "string" and bonusLastHopDice ~= "" and BattleBuff.GetBuff(chainTarget, 890001) then
            bonusDamageDice = joinDiceParts(bonusDamageDice, bonusLastHopDice)
        end
        local tags = {
            { tag = "set_damage_kind", phase = "pre", param = { kind = "thunder" } },
        }
        if markDurationDelta > 0 then
            tags[#tags + 1] = { tag = "extend_static_mark", phase = "post", param = { turns = markDurationDelta } }
        end
        table.insert(frames, {
            frame = frame,
            op = "chain_damage",
            effect = "chain_lightning_arc",
            target = chainTarget,
            chainIndex = hitIndex,
            bonusDamageDice = bonusDamageDice,
            tags = tags,
        })
        frame = frame + 8
    end

    if chainTargets and chainTargets[1] then
        table.insert(frames, {
            frame = frame + 1,
            op = "effect",
            effect = "chain_lightning_end",
            target = chainTargets[1],
        })
    end

    return SkillTimelineCompiler.Build(hero, targets, skill, { id = 80009003, frames = frames })
end

return skill_80009003
