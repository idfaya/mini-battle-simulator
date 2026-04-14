--[[
    战斗英雄工厂模块
    负责创建九流派英雄和敌人的战斗数据
--]]

local BattleHeroFactory = {}

local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")

function BattleHeroFactory.CreateHero(heroId, level, star)
    local heroData = HeroData.ConvertToHeroData(heroId, level, star)
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
    local enemyData = EnemyData.ConvertToHeroData(enemyId, level)
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
