--[[
    战斗英雄工厂模块
    负责创建九流派英雄和敌人的战斗数据
--]]

local BattleHeroFactory = {}

local RglHeroData = require("config.rgl_hero_data")
local RglEnemyData = require("config.rgl_enemy_data")
local _useRglMode = true

function BattleHeroFactory.SetRglMode(enabled)
    _useRglMode = enabled ~= false
end

function BattleHeroFactory.IsRglMode()
    return true
end

function BattleHeroFactory.CreateHero(heroId, level, star)
    return BattleHeroFactory.CreateRglHero(heroId, level, star)
end

function BattleHeroFactory.CreateRglHero(heroId, level, star)
    if not RglHeroData then
        RglHeroData = require("config.rgl_hero_data")
    end

    local heroData = RglHeroData.ConvertToHeroData(heroId, level, star)
    if not heroData then
        return nil
    end
    
    if heroData.skillsConfig then
        for _, cfg in ipairs(heroData.skillsConfig) do
            if cfg.skillType == nil then
                cfg.skillType = E_SKILL_TYPE_NORMAL
            elseif cfg.skillType == 3 or cfg.skillCost and cfg.skillCost > 0 then
                cfg.skillType = E_SKILL_TYPE_ULTIMATE
            end
        end
    end
    
    return heroData
end

function BattleHeroFactory.CreateEnemy(enemyId, level)
    return BattleHeroFactory.CreateRglEnemy(enemyId, level)
end

function BattleHeroFactory.CreateRglEnemy(enemyId, level)
    if not RglEnemyData then
        RglEnemyData = require("config.rgl_enemy_data")
    end

    local enemyData = RglEnemyData.ConvertToHeroData(enemyId, level)
    if not enemyData then
        return nil
    end
    
    enemyData.level = level
    
    return enemyData
end

function BattleHeroFactory.CreateHeroes(heroIds, level, star)
    local heroes = {}
    for _, heroId in ipairs(heroIds) do
        local hero = BattleHeroFactory.CreateHero(heroId, level, star)
        if hero then
            table.insert(heroes, hero)
        end
    end
    return heroes
end

function BattleHeroFactory.CreateEnemies(enemyIds, level)
    local enemies = {}
    for _, enemyId in ipairs(enemyIds) do
        local enemy = BattleHeroFactory.CreateEnemy(enemyId, level)
        if enemy then
            table.insert(enemies, enemy)
        end
    end
    return enemies
end

return BattleHeroFactory
