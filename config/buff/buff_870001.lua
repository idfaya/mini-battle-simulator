local BattleDmgHeal = require("modules.battle_dmg_heal")

local buff_870001 = {
    buffId = 870001,
    mainType = E_BUFF_MAIN_TYPE.BAD,
    subType = 870001,
    name = "燃烧",
    initialStack = 1,
    maxStack = 99,
    duration = 2,
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
                local damage = math.max(1, math.floor((hero.maxHp or 0) * 0.05 * buff.stackCount))
                BattleDmgHeal.ApplyDamage(hero, damage, buff.caster or hero)
            end
        }
    }
}

return {
    buff_870001 = buff_870001
}
