skill_80005004 = {}

function skill_80005004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    BattleSkill.ProcessPoisonBurst(hero, skill)
    return true
end

return skill_80005004
