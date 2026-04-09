skill_80004004 = {}

function skill_80004004.Execute(hero, targets, skill)
    local BattleSkill = require("modules.battle_skill")
    local BattleFormation = require("modules.battle_formation")
    local allies = BattleFormation.GetFriendTeam(hero)
    return (BattleSkill.ApplyBuffToTargets(hero, allies, skill) or 0) > 0
end

return skill_80004004
