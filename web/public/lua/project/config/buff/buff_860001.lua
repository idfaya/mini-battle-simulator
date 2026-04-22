local BattleDmgHeal = require("modules.battle_dmg_heal")
local Skill5eMeta = require("config.skill_5e_meta")
local Dice = require("core.dice")

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
                local meta = Skill5eMeta.Get(80006002) or {}
                local expr = meta.healDice or "1d4"
                local healAmount = math.max(1, math.floor(Dice.Roll(expr, { crit = false })))
                BattleDmgHeal.ApplyHeal(hero, healAmount, hero)
            end
        }
    }
}

return {
    buff_860001 = buff_860001
}
