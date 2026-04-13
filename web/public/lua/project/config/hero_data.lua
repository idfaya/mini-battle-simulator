local AllyData = require("config.ally_data")

local HeroData = {}

function HeroData.GetHero(heroId, level, star)
    return AllyData.ConvertToHeroData(heroId, level, star)
end

function HeroData.GetHeroName(heroId)
    return AllyData.GetAllyName(heroId)
end

function HeroData.GetAllHeroIds()
    local ids = {}
    for _, hero in ipairs(AllyData.GetPlayableHeroes()) do
        table.insert(ids, hero.AllyID)
    end
    return ids
end

function HeroData.GetAllHeroes()
    return AllyData.GetPlayableHeroes()
end

function HeroData.GetHeroesByClass(class)
    return AllyData.GetPlayableHeroesByClass(class)
end

function HeroData.GetHeroesByQuality(quality)
    return AllyData.GetPlayableHeroesByQuality(quality)
end

function HeroData.CreateBattleConfig(leftHeroes, rightHeroes, maxRound, seedArray)
    local config = {
        max_round = maxRound or 30,
        random_num = seedArray or {123456789, 362436069, 521288629, 88675123},
        unit_status = {
            attack_units = {
                pcs = {},
                collections = {},
                energy_data = { point = 0, point_limit = 10, bar = 0, bar_limit = 3 },
            },
            defend_units = {
                pcs = {},
                collections = {},
                energy_data = { point = 0, point_limit = 10, bar = 0, bar_limit = 3 },
            }
        }
    }

    local function AppendHero(targetList, heroInfo, uniqueId)
        local heroData = AllyData.ConvertToHeroData(heroInfo.id, heroInfo.level, heroInfo.star)
        if not heroData then
            return
        end
        table.insert(targetList, {
            config_id = heroInfo.id,
            unique_id = uniqueId,
            level = heroInfo.level or 1,
            wp_type = heroInfo.wpType or 1,
            wc_type = heroData.class or 1,
            enable = true,
            cast_priority = 1,
            skills = {},
            passive_skills = {},
            attribute_map = {
                attr_array = {
                    { key = 1, value = heroData.maxHp },
                    { key = 2, value = heroData.atk },
                    { key = 3, value = heroData.def },
                    { key = 4, value = heroData.speed or 100 },
                }
            }
        })
    end

    for _, heroInfo in ipairs(leftHeroes or {}) do
        AppendHero(config.unit_status.attack_units.pcs, heroInfo, heroInfo.id)
    end
    for _, heroInfo in ipairs(rightHeroes or {}) do
        AppendHero(config.unit_status.defend_units.pcs, heroInfo, heroInfo.id + 1000)
    end

    return config
end

function HeroData.CreateTestBattleConfig()
    local playableHeroes = AllyData.GetPlayableHeroes()
    if #playableHeroes < 6 then
        error("Not enough playable heroes (need at least 6)")
    end

    local leftHeroes = {}
    local rightHeroes = {}
    for i = 1, 3 do
        table.insert(leftHeroes, { id = playableHeroes[i].AllyID, level = 50, star = 5, wpType = i })
    end
    for i = 4, 6 do
        table.insert(rightHeroes, { id = playableHeroes[i].AllyID, level = 50, star = 5, wpType = i - 3 })
    end
    return HeroData.CreateBattleConfig(leftHeroes, rightHeroes, 30)
end

function HeroData.PrintHeroList()
    local heroes = AllyData.GetPlayableHeroes()
    print("=== Playable Heroes ===")
    print(string.format("Total: %d", #heroes))
    print("")
    for _, hero in ipairs(heroes) do
        local heroData = AllyData.ConvertToHeroData(hero.AllyID, 1, 1)
        print(string.format("ID: %d | Name: %s | Class: %s | Quality: %s",
            hero.AllyID,
            heroData.name,
            AllyData.GetClassName(hero.Class),
            AllyData.GetQualityName(hero.BaseQuality or 1)))
    end
end

return HeroData
