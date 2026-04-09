skill_80009003 = {}

function skill_80009003.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    BattleSkill.ProcessChainLightning(hero, 4, 10000)
    return true
end

return skill_80009003
