--[[
    战斗英雄工厂模块
    负责创建英雄和敌人的战斗数据
    支持 Roguelike 数据源切换
--]]

local BattleHeroFactory = {}

local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local RglHeroData = nil
local RglEnemyData = nil

local _useRglMode = false

function BattleHeroFactory.SetRglMode(enabled)
    _useRglMode = enabled
    if enabled and not RglHeroData then
        local SkillRglConfig = require("config.skill_rgl_config")
        SkillRglConfig.Init()
        RglHeroData = require("config.rgl_hero_data")
        RglEnemyData = require("config.rgl_enemy_data")
    end
end

function BattleHeroFactory.IsRglMode()
    return _useRglMode
end

function BattleHeroFactory.CreateHero(heroId, level, star)
    if _useRglMode then
        return BattleHeroFactory.CreateRglHero(heroId, level, star)
    end

    local heroData = AllyData.ConvertToHeroData(heroId, level, star)
    if not heroData then
        return nil
    end
    
    if heroData.skillsConfig then
        for _, cfg in ipairs(heroData.skillsConfig) do
            cfg.skillType = cfg.skillType == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL
        end
    end
    
    return heroData
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
            if cfg.skillType == E_SKILL_TYPE_PASSIVE and (cfg.classId and cfg.classId >= 8000010 and cfg.classId < 8000100) then
                -- passive skill, keep as is
            elseif cfg.skillType == 3 or cfg.skillCost and cfg.skillCost > 0 then
                cfg.skillType = E_SKILL_TYPE_ULTIMATE
            else
                cfg.skillType = E_SKILL_TYPE_NORMAL
            end
        end
    end
    
    return heroData
end

function BattleHeroFactory.CreateEnemy(enemyId, level)
    if _useRglMode then
        return BattleHeroFactory.CreateRglEnemy(enemyId, level)
    end

    local enemyData = EnemyData.ConvertToHeroData(enemyId)
    if not enemyData then
        return nil
    end
    
    enemyData.level = level
    
    if enemyData.skillsConfig then
        for _, cfg in ipairs(enemyData.skillsConfig) do
            cfg.skillType = cfg.skillType == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL
        end
    end
    
    return enemyData
end

function BattleHeroFactory.CreateRglEnemy(enemyId, level)
    if not RglEnemyData then
        RglEnemyData = require("config.rgl_enemy_data")
    end

    local enemyData = RglEnemyData.ConvertToHeroData(enemyId)
    if not enemyData then
        return nil
    end
    
    enemyData.level = level
    
    if enemyData.skillsConfig then
        for _, cfg in ipairs(enemyData.skillsConfig) do
            if cfg.skillType == E_SKILL_TYPE_PASSIVE then
                -- keep passive type for RGL passives
            elseif cfg.skillType == 3 or cfg.skillCost and cfg.skillCost > 0 then
                cfg.skillType = E_SKILL_TYPE_ULTIMATE
            else
                cfg.skillType = E_SKILL_TYPE_NORMAL
            end
        end
    end
    
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