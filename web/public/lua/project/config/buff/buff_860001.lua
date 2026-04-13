local BattleSkill = require("modules.battle_skill")
local BattleDmgHeal = require("modules.battle_dmg_heal")

local buff_860001 = {
    buffId = 860001,
    mainType = E_BUFF_MAIN_TYPE.GOOD,
    subType = 860001,
    name = "亲和",
    initialStack = 1,
    maxStack = 1,
    duration = 99,
    isPermanent = true,
    canStack = false,
    stackRule = "refresh",
    effects = {
        {
            timing = 3,
            type = "custom",
            func = function(buff, hero, effect)
                if not hero or hero.isDead then
                    return
                end
                local healAmount = BattleSkill.CalculateHeal(hero, hero, 1000)
                BattleDmgHeal.ApplyHeal(hero, healAmount, hero)
            end
        }
    }
}

return {
    buff_860001 = buff_860001
}
