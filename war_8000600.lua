local BattleSkill = require("modules.battle_skill")
local BattleBuff = require("modules.battle_buff")

return function(context)
    local self = {}
    self.context = context

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        if not BattleBuff.GetBuff(hero, 860001) then
            BattleSkill.ApplyBuffFromSkill(hero, hero, 860001, nil)
        end
    end

    return self
end
