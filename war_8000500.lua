local BattleSkill = require("modules.battle_skill")
local BattleFormation = require("modules.battle_formation")

return function(context)
    local self = {}
    self.context = context

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        local enemyTeam = BattleFormation.GetEnemyTeam(hero)
        for _, enemy in ipairs(enemyTeam) do
            if enemy and not enemy.isDead then
                BattleSkill.ProcessInfectEffect(enemy)
            end
        end
    end

    return self
end
