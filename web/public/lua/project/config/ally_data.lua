local RglHeroData = require("config.rgl_hero_data")

local AllyData = {}

local CLASS_NAMES = {
    [1] = "Front",
    [2] = "Mid",
    [3] = "Back",
}

local QUALITY_NAMES = {
    [1] = "Common",
    [2] = "Good",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legend",
    [6] = "Myth",
}

function AllyData.Init()
    return true
end

function AllyData.GetAllyInfo(allyId)
    return RglHeroData.GetHeroInfo(allyId)
end

function AllyData.GetAllAllies()
    return RglHeroData.GetAllHeroes()
end

function AllyData.GetPlayableHeroes()
    return RglHeroData.GetPlayableHeroes()
end

function AllyData.GetPlayableHeroesByClass(class)
    return RglHeroData.GetHeroesByClass(class)
end

function AllyData.GetPlayableHeroesByQuality(quality)
    return RglHeroData.GetHeroesByQuality(quality)
end

function AllyData.GetAlliesByClass(class)
    return RglHeroData.GetHeroesByClass(class)
end

function AllyData.GetAlliesByFaction(faction)
    return RglHeroData.GetHeroesByFaction(faction)
end

function AllyData.GetAlliesByQuality(quality)
    return RglHeroData.GetHeroesByQuality(quality)
end

function AllyData.GetAllyName(allyId)
    return RglHeroData.GetHeroName(allyId)
end

function AllyData.GetClassName(class)
    return CLASS_NAMES[class] or "Unknown"
end

function AllyData.GetQualityName(quality)
    return QUALITY_NAMES[quality] or "Unknown"
end

function AllyData.CalculateHeroAttributes(allyId, level, star)
    return RglHeroData.CalculateHeroAttributes(allyId, level, star)
end

function AllyData.ConvertToHeroData(allyId, level, star)
    return RglHeroData.ConvertToHeroData(allyId, level, star)
end

return AllyData
