local BattleEnergy = {}

local POINTS_PER_BAR = 100

function BattleEnergy.Init(beginState)
    BattleEnergy.heroEnergy = {}
    BattleEnergy.heroEnergyPoint = {}
    
    if beginState and beginState.heroEnergy then
        for heroId, energy in pairs(beginState.heroEnergy) do
            BattleEnergy.heroEnergy[heroId] = energy
            BattleEnergy.heroEnergyPoint[heroId] = 0
        end
    end
end

function BattleEnergy.OnFinal()
    BattleEnergy.heroEnergy = nil
    BattleEnergy.heroEnergyPoint = nil
end

function BattleEnergy.AddPoint(hero, points)
    if not hero or not points or points <= 0 then
        return
    end
    
    local heroId = hero.id
    if not heroId then
        return
    end
    
    BattleEnergy.heroEnergyPoint[heroId] = (BattleEnergy.heroEnergyPoint[heroId] or 0) + points
    
    while BattleEnergy.heroEnergyPoint[heroId] >= POINTS_PER_BAR do
        BattleEnergy.heroEnergyPoint[heroId] = BattleEnergy.heroEnergyPoint[heroId] - POINTS_PER_BAR
        BattleEnergy.AddEnergy(hero, 1)
    end
end

function BattleEnergy.AddEnergy(hero, energy)
    if not hero or not energy or energy <= 0 then
        return
    end
    
    local heroId = hero.id
    if not heroId then
        return
    end
    
    BattleEnergy.heroEnergy[heroId] = (BattleEnergy.heroEnergy[heroId] or 0) + energy
end

function BattleEnergy.ConsumeEnergy(hero, amount)
    if not hero or not amount or amount <= 0 then
        return false
    end
    
    local heroId = hero.id
    if not heroId then
        return false
    end
    
    local currentEnergy = BattleEnergy.heroEnergy[heroId] or 0
    if currentEnergy < amount then
        return false
    end
    
    BattleEnergy.heroEnergy[heroId] = currentEnergy - amount
    return true
end

function BattleEnergy.GetEnergyPoint(hero)
    if not hero or not hero.id then
        return 0
    end
    
    return BattleEnergy.heroEnergyPoint[hero.id] or 0
end

function BattleEnergy.GetEnergyBar(hero)
    if not hero or not hero.id then
        return 0
    end
    
    return BattleEnergy.heroEnergy[hero.id] or 0
end

function BattleEnergy.CanCastUltimate(hero, skill)
    if not hero or not skill then
        return false
    end
    
    local energyCost = skill.energyCost or skill.energy_cost or 0
    if energyCost <= 0 then
        return true
    end
    
    local currentEnergy = BattleEnergy.GetEnergyBar(hero)
    return currentEnergy >= energyCost
end

function BattleEnergy.OnHeroAction(hero)
    if not hero then
        return
    end
    
    local points = 20
    BattleEnergy.AddPoint(hero, points)
end

function BattleEnergy.OnHeroDamaged(hero, damage)
    if not hero or not damage or damage <= 0 then
        return
    end
    
    local points = math.floor(damage / 10)
    if points < 1 then
        points = 1
    end
    
    BattleEnergy.AddPoint(hero, points)
end

function BattleEnergy.ResetEnergy(hero)
    if not hero or not hero.id then
        return
    end
    
    local heroId = hero.id
    BattleEnergy.heroEnergy[heroId] = 0
    BattleEnergy.heroEnergyPoint[heroId] = 0
end

return BattleEnergy
