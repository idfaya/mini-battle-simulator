local BattleSkill = require("modules.battle_skill")
local BattleBuff = require("modules.battle_buff")

return function(context)
    local self = {}
    self.context = context

    function self:OnDmgMakeKill(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        if BattleBuff.GetBuff(hero, 840001) then
            BattleBuff.ModifyBuffStack(hero, 840001, 1)
        else
            BattleSkill.ApplyBuffFromSkill(hero, hero, 840001, nil)
        end
    end

    return self
end
