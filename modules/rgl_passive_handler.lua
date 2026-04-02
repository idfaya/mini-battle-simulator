local BattlePassiveSkill = require("modules.battle_passive_skill")

local RglPassiveHandler = {}

local function EnsurePassiveSkills(hero)
    hero.passiveSkills = hero.passiveSkills or {}
    local existing = {}
    for _, s in ipairs(hero.passiveSkills) do
        if s and s.skillId then
            existing[s.skillId] = true
        end
    end

    local skills = hero.skills or {}
    for _, s in ipairs(skills) do
        if s and s.skillId and s.skillType == E_SKILL_TYPE_PASSIVE then
            if not existing[s.skillId] then
                s.isPassiveActive = true
                table.insert(hero.passiveSkills, s)
                existing[s.skillId] = true
            end
        end
    end
end

function RglPassiveHandler.InitHeroPassiveSkills(hero)
    if not hero then
        return
    end

    EnsurePassiveSkills(hero)

    for _, passiveSkill in ipairs(hero.passiveSkills) do
        if passiveSkill and passiveSkill.isPassiveActive ~= false then
            BattlePassiveSkill.AddPassiveSkill2TriggerTime(hero, passiveSkill)
        end
    end
end

function RglPassiveHandler.ApplyPassiveAttributes(hero)
    if not hero then
        return
    end
end

return RglPassiveHandler
