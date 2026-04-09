local BattleSkill = require("modules.battle_skill")

return function(context)
    local self = {}
    self.context = context

    function self:OnDmgMakeKill(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        hero.rglWarSpiritStacks = math.min((hero.rglWarSpiritStacks or 0) + 1, 5)
    end

    return self
end
