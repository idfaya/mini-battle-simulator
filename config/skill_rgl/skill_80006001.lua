skill_80006001 = {}

function skill_80006001.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local ally = BattleSkill.SelectLowestHpAlly(hero)
    if ally then
        BattleSkill.ProcessHolyLightEffect(hero, ally, skill)
        return true
    end
    return false
end

return skill_80006001
