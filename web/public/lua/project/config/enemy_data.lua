local RglEnemyData = require("config.rgl_enemy_data")

local EnemyData = {}

function EnemyData.Init()
    return true
end

function EnemyData.GetEnemy(enemyId)
    return RglEnemyData.GetEnemy(enemyId)
end

function EnemyData.GetEnemyInfo(enemyId)
    return RglEnemyData.GetEnemy(enemyId)
end

function EnemyData.GetEnemiesByLevel(level)
    local result = {}
    for _, enemy in ipairs(RglEnemyData.GetAllEnemies()) do
        if enemy.Level == level then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetEnemiesByClass(class)
    local result = {}
    for _, enemy in ipairs(RglEnemyData.GetAllEnemies()) do
        if enemy.Class == class then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetAllEnemies()
    return RglEnemyData.GetAllEnemies()
end

function EnemyData.GetAllEnemyIds()
    return RglEnemyData.GetAllEnemyIds()
end

function EnemyData.GetClassName(class)
    return RglEnemyData.GetClassName(class)
end

function EnemyData.GetMonsterTypeName(monsterType)
    return RglEnemyData.GetMonsterTypeName(monsterType)
end

function EnemyData.ConvertToHeroData(enemyId)
    return RglEnemyData.ConvertToHeroData(enemyId)
end

function EnemyData.ConvertEnemiesToHeroData(enemyIds)
    return RglEnemyData.ConvertEnemiesToHeroData(enemyIds)
end

function EnemyData.GetHeroesByLevelRange(minLevel, maxLevel, count)
    local result = {}
    for _, enemy in ipairs(RglEnemyData.GetAllEnemies()) do
        local level = enemy.Level or 1
        if level >= minLevel and level <= maxLevel then
            table.insert(result, RglEnemyData.ConvertToHeroData(enemy.ID))
            if count and #result >= count then
                break
            end
        end
    end
    return result
end

function EnemyData.GetEnemiesByMonsterType(monsterType)
    local result = {}
    for _, enemy in ipairs(RglEnemyData.GetAllEnemies()) do
        if enemy.MonsterType == monsterType then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetAllBossIds()
    return RglEnemyData.GetAllBossIds()
end

function EnemyData.GetAllNormalEnemyIds()
    return RglEnemyData.GetAllNormalEnemyIds()
end

function EnemyData.Reload()
    return RglEnemyData.Reload()
end

return EnemyData
