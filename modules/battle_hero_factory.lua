--[[
    战斗英雄工厂模块
    负责创建英雄和敌人的战斗数据
--]]

local BattleHeroFactory = {}

-- 依赖模块
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")

--- 创建英雄战斗数据
---@param heroId number 英雄ID (AllyID)
---@param level number 英雄等级
---@param star number 英雄星级
---@return table|nil 英雄战斗数据
function BattleHeroFactory.CreateHero(heroId, level, star)
    local heroData = AllyData.ConvertToHeroData(heroId, level, star)
    if not heroData then
        return nil
    end
    
    -- skillsConfig 已由 AllyData.ConvertToHeroData 自动生成
    -- 只需要转换 skillType 为战斗系统使用的枚举值
    if heroData.skillsConfig then
        for _, cfg in ipairs(heroData.skillsConfig) do
            cfg.skillType = cfg.skillType == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL
        end
    end
    
    return heroData
end

--- 创建敌人战斗数据
---@param enemyId number 敌人ID
---@param level number 敌人等级
---@return table|nil 敌人战斗数据
function BattleHeroFactory.CreateEnemy(enemyId, level)
    local enemyData = EnemyData.ConvertToHeroData(enemyId)
    if not enemyData then
        return nil
    end
    
    -- 设置敌人等级
    enemyData.level = level
    
    -- skillsConfig 已由 EnemyData.ConvertToHeroData 自动生成
    -- 只需要转换 skillType 为战斗系统使用的枚举值
    if enemyData.skillsConfig then
        for _, cfg in ipairs(enemyData.skillsConfig) do
            cfg.skillType = cfg.skillType == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL
        end
    end
    
    return enemyData
end

--- 批量创建英雄
---@param heroIds table 英雄ID列表
---@param level number 英雄等级
---@param star number 英雄星级
---@return table 英雄战斗数据列表
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

--- 批量创建敌人
---@param enemyIds table 敌人ID列表
---@param level number 敌人等级
---@return table 敌人战斗数据列表
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
