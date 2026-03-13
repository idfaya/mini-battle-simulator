---
--- Hero Data Configuration
--- 使用原项目配置 (res_ally_info.json)
---

local AllyData = require("config.ally_data")

local HeroData = {}

-- 获取英雄数据（从原项目配置转换）
function HeroData.GetHero(heroId, level, star)
    return AllyData.ConvertToHeroData(heroId, level, star)
end

-- 获取英雄名称
function HeroData.GetHeroName(heroId)
    return AllyData.GetAllyName(heroId)
end

-- 获取所有玩家可用英雄ID列表
function HeroData.GetAllHeroIds()
    local ids = {}
    local playableHeroes = AllyData.GetPlayableHeroes()
    for _, hero in ipairs(playableHeroes) do
        table.insert(ids, hero.AllyID)
    end
    return ids
end

-- 获取所有玩家可用英雄
function HeroData.GetAllHeroes()
    return AllyData.GetPlayableHeroes()
end

-- 按职业获取英雄
function HeroData.GetHeroesByClass(class)
    return AllyData.GetPlayableHeroesByClass(class)
end

-- 按品质获取英雄
function HeroData.GetHeroesByQuality(quality)
    return AllyData.GetPlayableHeroesByQuality(quality)
end

-- 创建战斗阵容配置
-- leftHeroes: {{id=xxx, level=xx, star=x, wpType=x}, ...}
-- rightHeroes: 同上
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
    
    -- 转换左侧英雄
    for _, heroInfo in ipairs(leftHeroes or {}) do
        local heroData = AllyData.ConvertToHeroData(heroInfo.id, heroInfo.level, heroInfo.star)
        if heroData then
            table.insert(config.unit_status.attack_units.pcs, {
                config_id = heroInfo.id,
                unique_id = heroInfo.id,
                level = heroInfo.level or 1,
                wp_type = heroInfo.wpType or 1,
                wc_type = heroData.class or 1,
                enable = true,
                cast_priority = 1,
                skills = {},
                passive_skills = {},
                attribute_map = {
                    attr_array = {
                        { key = 1, value = heroData.maxHp },  -- HP
                        { key = 2, value = heroData.atk },    -- ATK
                        { key = 3, value = heroData.def },    -- DEF
                        { key = 4, value = heroData.speed or 100 }, -- SPEED
                    }
                }
            })
        end
    end
    
    -- 转换右侧英雄
    for _, heroInfo in ipairs(rightHeroes or {}) do
        local heroData = AllyData.ConvertToHeroData(heroInfo.id, heroInfo.level, heroInfo.star)
        if heroData then
            table.insert(config.unit_status.defend_units.pcs, {
                config_id = heroInfo.id,
                unique_id = heroInfo.id + 1000,  -- 右侧英雄ID偏移
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
    end
    
    return config
end

-- 创建测试阵容（3v3）
function HeroData.CreateTestBattleConfig()
    local playableHeroes = AllyData.GetPlayableHeroes()
    if #playableHeroes < 6 then
        error("Not enough playable heroes (need at least 6)")
    end
    
    -- 选择前6个可用英雄
    local leftHeroes = {}
    local rightHeroes = {}
    
    for i = 1, 3 do
        table.insert(leftHeroes, {
            id = playableHeroes[i].AllyID,
            level = 50,
            star = 5,
            wpType = i
        })
    end
    
    for i = 4, 6 do
        table.insert(rightHeroes, {
            id = playableHeroes[i].AllyID,
            level = 50,
            star = 5,
            wpType = i - 3
        })
    end
    
    return HeroData.CreateBattleConfig(leftHeroes, rightHeroes, 30)
end

-- 打印英雄列表（调试用）
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
            AllyData.GetQualityName(hero.BaseQuality or 1)
        ))
    end
end

return HeroData
