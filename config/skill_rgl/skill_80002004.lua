skill_80002004 = {}

function skill_80002004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleBuff = require("modules.battle_buff")
    BattleBuff.DelBuffBySubType(hero, 820002)
    BattleSkill.ApplyBuffFromSkill(hero, hero, 820003, skill)
    return true
end

return skill_80002004
