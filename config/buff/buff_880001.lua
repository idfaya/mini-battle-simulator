local Ability5e = require("modules.ability_5e")

local function getFrozenAcPenalty(hero)
    local classId = tonumber(hero and (hero.class or hero.Class or hero._class)) or 0
    local dex = tonumber(hero and hero.dexMod) or 0
    local wis = tonumber(hero and hero.wisMod) or 0
    local con = tonumber(hero and hero.conMod) or 0
    local withDex = Ability5e.CalculateArmorClass(classId, {
        dex = dex,
        wis = wis,
        con = con,
    })
    local withoutDex = Ability5e.CalculateArmorClass(classId, {
        dex = 0,
        wis = wis,
        con = con,
    })
    return math.max(0, (tonumber(withDex) or 0) - (tonumber(withoutDex) or 0))
end

local function applyFrozenDexPenalty(buff, hero)
    if not hero or hero.isDead or buff.__dexPenaltyApplied then
        return
    end
    local acPenalty = getFrozenAcPenalty(hero)
    local currentSaveRef = tonumber(hero.saveRef) or 0
    local dexSaveBonus = math.max(0, tonumber(hero.dexMod) or 0)
    local savePenalty = math.max(0, math.min(currentSaveRef, dexSaveBonus))
    buff.__frozenAcPenalty = acPenalty
    buff.__frozenSavePenalty = savePenalty
    if acPenalty > 0 then
        hero.ac = math.max(0, math.floor((tonumber(hero.ac) or 0) - acPenalty))
    end
    if savePenalty > 0 then
        hero.saveRef = math.max(0, math.floor((tonumber(hero.saveRef) or 0) - savePenalty))
    end
    buff.__dexPenaltyApplied = true
end

local function removeFrozenDexPenalty(buff, hero)
    if not hero or not buff.__dexPenaltyApplied then
        return
    end
    local acPenalty = math.max(0, math.floor(tonumber(buff.__frozenAcPenalty) or 0))
    local savePenalty = math.max(0, math.floor(tonumber(buff.__frozenSavePenalty) or 0))
    if acPenalty > 0 then
        hero.ac = math.max(0, math.floor((tonumber(hero.ac) or 0) + acPenalty))
    end
    if savePenalty > 0 then
        hero.saveRef = math.max(0, math.floor((tonumber(hero.saveRef) or 0) + savePenalty))
    end
    buff.__dexPenaltyApplied = false
    buff.__frozenAcPenalty = 0
    buff.__frozenSavePenalty = 0
end

local buff_880001 = {
    buffId = 880001,
    mainType = E_BUFF_MAIN_TYPE.BAD,
    subType = 880001,
    name = "减速",
    initialStack = 1,
    maxStack = 1,
    value = 3000,
    maxValue = 3000,
    displayMode = "pct",
    duration = 2,
    canStack = false,
    stackRule = "refresh",
    effects = {
        {
            timing = 1,
            type = "custom",
            func = function(buff, hero)
                applyFrozenDexPenalty(buff, hero)
            end
        },
        {
            timing = 2,
            type = "custom",
            func = function(buff, hero)
                removeFrozenDexPenalty(buff, hero)
            end
        }
    }
}

return {
    buff_880001 = buff_880001
}
