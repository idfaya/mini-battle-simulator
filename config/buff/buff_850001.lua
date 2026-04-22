local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleSkill = require("modules.battle_skill")

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
                local stacks = math.max(1, tonumber(buff.stackCount) or 1)
                local diceExpr = string.format("%dd4", stacks) -- per stack +1d4
                local dmgResult = BattleSkill.ResolveScaledDamage(buff.caster or hero, hero, {
                    skipCheck = true,
                    noClassScalar = true,
                    kind = "spell",
                    damageKind = "poison",
                    damageDice = diceExpr,
                })
                local damage = tonumber(dmgResult and dmgResult.damage) or 0
                BattleDmgHeal.ApplyDamage(hero, damage, buff.caster or hero, {
                    damageKind = "poison",
                })
            end
        }
    }
}

return {
    buff_850001 = buff_850001
}
