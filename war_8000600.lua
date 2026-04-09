local BattleSkill = require("modules.battle_skill")
local BattleDmgHeal = require("modules.battle_dmg_heal")

return function(context)
    local self = {}
    self.context = context

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        local healAmount = BattleSkill.CalculateHeal(hero, hero, 1000)
        BattleDmgHeal.ApplyHeal(hero, healAmount, hero)
    end

    return self
end
