local BattleSkill = require("modules.battle_skill")

return function(context)
    local self = {}
    self.context = context

    function self:OnDmgMakeKill(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam and extraParam.target or nil
        if not hero or hero.isDead or not target then
            return
        end
        BattleSkill.ProcessPursuitEffect(hero, target, nil)
    end

    return self
end
