skill_80006003 = {}

function skill_80006003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    BattleSkill.ProcessGroupHeal(hero, skill)
    return true
end

return skill_80006003
