skill_80006004 = {}

function skill_80006004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    BattleSkill.ProcessFullHealAndCleanse(hero, skill)
    return true
end

return skill_80006004
