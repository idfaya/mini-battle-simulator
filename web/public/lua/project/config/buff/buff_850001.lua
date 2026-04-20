local BattleDmgHeal = require("modules.battle_dmg_heal")

local buff_850001 = {
    buffId = 850001,
    mainType = E_BUFF_MAIN_TYPE.BAD,
    subType = 850001,
    name = "中毒",
    initialStack = 1,
    maxStack = 99,
    duration = 99,
    isPermanent = true,
    canStack = true,
    stackRule = "add",
    effects = {
        {
            timing = 3,
            type = "custom",
            func = function(buff, hero, effect)
                if not hero or hero.isDead then
                    return
                end
                local damage = math.max(1, math.floor((hero.maxHp or 0) * 0.02 * buff.stackCount))
                BattleDmgHeal.ApplyDamage(hero, damage, buff.caster or hero, {
                    damageKind = "dot",
                })
            end
        }
    }
}

return {
    buff_850001 = buff_850001
}
