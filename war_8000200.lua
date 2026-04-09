local BattleSkill = require("modules.battle_skill")
local BattleBuff = require("modules.battle_buff")

return function(context)
    local self = {}
    self.context = context

    function self:OnSelfTurnBegin(ctx)
        return
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not hero or hero.isDead or not extraParam then
            return
        end
        local attacker = extraParam.attacker
        if not attacker or attacker.isDead then
            return
        end

        if BattleBuff.GetBuffBySubType(hero, 820003) then
            extraParam.damage = math.max(0, math.floor((extraParam.damage or 0) * 0.5))
            extraParam.blocked = true
            local counterDamage = BattleSkill.CalculateDamageWithRate(hero, attacker, 15000)
            local BattleDmgHeal = require("modules.battle_dmg_heal")
            BattleDmgHeal.ApplyDamage(attacker, counterDamage, hero)
            return
        end

        if BattleBuff.GetBuffBySubType(hero, 820002) then
            BattleBuff.DelBuffBySubType(hero, 820002, 1)
            local counterDamage = BattleSkill.CalculateDamageWithRate(hero, attacker, 15000)
            local BattleDmgHeal = require("modules.battle_dmg_heal")
            BattleDmgHeal.ApplyDamage(attacker, counterDamage, hero)
            return
        end

        local roll = math.random(1, 10000)
        if roll > 2500 then
            return
        end
        extraParam.damage = math.max(0, math.floor((extraParam.damage or 0) * 0.5))
        extraParam.blocked = true
        BattleSkill.CastSmallSkill(hero, attacker)
    end

    return self
end
