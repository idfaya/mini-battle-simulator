-- 随机出战阵容战斗测试
-- 随机选择英雄和敌人，等级大体平衡

-- 设置包路径
package.path = package.path
    .. ";../?.lua"
    .. ";../core/?.lua"
    .. ";../modules/?.lua"
    .. ";../config/?.lua"
    .. ";../utils/?.lua"

-- 加载必要的模块
require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local BattleFormula = require("core.battle_formula")

-- 日志函数
local function Log(msg)
    print(string.format("[RANDOM BATTLE] %s", msg))
end

-- 随机数生成器
local Random = {
    seed = os.time(),
    Next = function(self, min, max)
        self.seed = (self.seed * 1103515245 + 12345) % 2147483648
        local range = max - min + 1
        return min + (self.seed % range)
    end,
    NextDouble = function(self)
        self.seed = (self.seed * 1103515245 + 12345) % 2147483648
        return self.seed / 2147483648
    end
}

-- 随机选择英雄
local function GetRandomHeroes(count, level, star)
    local heroes = {}
    local allHeroes = AllyData.GetPlayableHeroes()
    
    if #allHeroes == 0 then
        LogError("没有可用的英雄")
        return heroes
    end
    
    -- 随机选择不重复的英雄
    local selectedIndices = {}
    local selectedCount = 0
    
    while selectedCount < count and selectedCount < #allHeroes do
        local index = Random:Next(1, #allHeroes)
        if not selectedIndices[index] then
            selectedIndices[index] = true
            selectedCount = selectedCount + 1
            
            local heroInfo = allHeroes[index]
            local heroData, err = AllyData.ConvertToHeroData(heroInfo.AllyID, level, star)
            
            if heroData then
                local hero = {
                    id = heroInfo.AllyID,
                    name = string.format("Hero_%d", heroInfo.AllyID),
                    HP = heroData.HP or 1000,
                    MaxHP = heroData.HP or 1000,
                    ATK = heroData.ATK or 100,
                    DEF = heroData.DEF or 50,
                    SPD = heroData.SPD or 100,
                    CRT = heroData.CRT or 0.1,
                    CRTD = heroData.CRTD or 1.5,
                    HIT = heroData.HIT or 1.0,
                    RES = heroData.RES or 0,
                    Class = heroData.Class or 2,
                    side = "left",
                    position = selectedCount,
                    energy = 0,
                    maxEnergy = 100,
                    isAlive = true,
                    buffs = {}
                }
                table.insert(heroes, hero)
                Log(string.format("选择英雄: %s (Lv%d ★%d) HP:%.0f ATK:%.0f DEF:%.0f SPD:%.0f",
                    hero.name, level, star, hero.HP, hero.ATK, hero.DEF, hero.SPD))
            end
        end
    end
    
    return heroes
end

-- 根据英雄等级选择合适等级的敌人
local function GetEnemiesByLevel(heroLevel, count)
    local enemies = {}
    local allEnemyIds = EnemyData.GetAllEnemyIds()
    
    if #allEnemyIds == 0 then
        LogError("没有可用的敌人")
        return enemies
    end
    
    -- 筛选合适等级的敌人 (英雄等级 ± 10级)
    local minLevel = math.max(1, heroLevel - 10)
    local maxLevel = heroLevel + 10
    local suitableEnemies = {}
    
    for _, enemyId in ipairs(allEnemyIds) do
        local enemyData = EnemyData.GetEnemy(enemyId)
        if enemyData and enemyData.Level then
            if enemyData.Level >= minLevel and enemyData.Level <= maxLevel then
                table.insert(suitableEnemies, enemyData)
            end
        end
    end
    
    -- 如果没有合适等级的敌人，使用所有敌人
    if #suitableEnemies == 0 then
        for _, enemyId in ipairs(allEnemyIds) do
            local enemyData = EnemyData.GetEnemy(enemyId)
            if enemyData then
                table.insert(suitableEnemies, enemyData)
            end
        end
    end
    
    -- 随机选择敌人
    local selectedIndices = {}
    local selectedCount = 0
    
    while selectedCount < count and selectedCount < #suitableEnemies do
        local index = Random:Next(1, #suitableEnemies)
        if not selectedIndices[index] then
            selectedIndices[index] = true
            selectedCount = selectedCount + 1
            
            local enemyData = suitableEnemies[index]
            local enemy = {
                id = enemyData.ID or 0,
                name = string.format("Enemy_%d", enemyData.ID or 0),
                HP = enemyData.HP or 800,
                MaxHP = enemyData.HP or 800,
                ATK = enemyData.ATK or 80,
                DEF = enemyData.DEF or 40,
                SPD = enemyData.SPD or 90,
                CRT = enemyData.CRT or 0.05,
                CRTD = enemyData.CRTD or 1.5,
                HIT = enemyData.HIT or 1.0,
                RES = enemyData.RES or 0,
                Class = enemyData.Class or 2,
                Level = enemyData.Level or 1,
                side = "right",
                position = selectedCount,
                energy = 0,
                maxEnergy = 100,
                isAlive = true,
                buffs = {}
            }
            table.insert(enemies, enemy)
            Log(string.format("选择敌人: %s (Lv%d) HP:%d ATK:%d DEF:%d SPD:%d",
                enemy.name, enemy.Level, enemy.HP, enemy.ATK, enemy.DEF, enemy.SPD))
        end
    end
    
    return enemies
end

-- 计算队伍总战力
local function CalculateTeamPower(team)
    local totalPower = 0
    for _, unit in ipairs(team) do
        local power = (unit.HP or 0) * 0.5 + (unit.ATK or 0) * 2 + (unit.DEF or 0) * 1.5 + (unit.SPD or 0) * 1
        totalPower = totalPower + power
    end
    return totalPower
end

-- 计算伤害
local function CalculateDamage(attacker, defender)
    local result = BattleFormula.CalcDamage(attacker, defender, 10000, E_ATTACK_TYPE.Physical)
    return result.damage, result.isCrit
end

-- 执行攻击
local function ExecuteAttack(attacker, defender)
    local damage, isCrit = CalculateDamage(attacker, defender)
    defender.HP = defender.HP - damage
    
    if defender.HP <= 0 then
        defender.HP = 0
        defender.isAlive = false
    end
    
    return {
        attacker = attacker.name,
        defender = defender.name,
        damage = damage,
        isCrit = isCrit,
        defenderHP = defender.HP,
        defenderAlive = defender.isAlive
    }
end

-- 获取存活单位
local function GetAliveUnits(team)
    local alive = {}
    for _, unit in ipairs(team) do
        if unit.isAlive then
            table.insert(alive, unit)
        end
    end
    return alive
end

-- 选择目标
local function SelectTarget(team)
    local alive = GetAliveUnits(team)
    if #alive == 0 then
        return nil
    end
    return alive[Random:Next(1, #alive)]
end

-- 执行回合
local function ExecuteRound(round, leftTeam, rightTeam)
    Log(string.format("===== 回合 %d =====", round))
    
    -- 收集所有存活单位并按速度排序
    local allUnits = {}
    for _, unit in ipairs(leftTeam) do
        if unit.isAlive then
            table.insert(allUnits, unit)
        end
    end
    for _, unit in ipairs(rightTeam) do
        if unit.isAlive then
            table.insert(allUnits, unit)
        end
    end
    
    -- 按速度排序
    table.sort(allUnits, function(a, b)
        return a.SPD > b.SPD
    end)
    
    -- 每个单位行动
    for _, unit in ipairs(allUnits) do
        if not unit.isAlive then
            goto continue
        end
        
        -- 选择目标
        local targetTeam = (unit.side == "left") and rightTeam or leftTeam
        local target = SelectTarget(targetTeam)
        
        if target then
            -- 执行攻击
            local result = ExecuteAttack(unit, target)
            local critStr = result.isCrit and " [暴击!]" or ""
            Log(string.format("%s 攻击 %s, 造成 %d 伤害%s, %s 剩余 HP: %d/%d",
                result.attacker, result.defender, result.damage, critStr,
                result.defender, result.defenderHP, target.MaxHP))
            
            if not result.defenderAlive then
                Log(string.format("  -> %s 被击败!", result.defender))
            end
        end
        
        -- 检查战斗是否结束
        local leftAlive = #GetAliveUnits(leftTeam)
        local rightAlive = #GetAliveUnits(rightTeam)
        
        if leftAlive == 0 or rightAlive == 0 then
            return true, leftAlive, rightAlive
        end
        
        ::continue::
    end
    
    return false, #GetAliveUnits(leftTeam), #GetAliveUnits(rightTeam)
end

-- 运行随机战斗测试
local function RunRandomBattle()
    Log("开始随机战斗测试...")
    Log(string.rep("=", 50))
    
    -- 初始化数据
    Log("初始化数据模块...")
    AllyData.Init()
    EnemyData.Init()
    
    -- 随机参数
    local heroCount = Random:Next(3, 5)  -- 3-5个英雄
    local enemyCount = Random:Next(3, 5)  -- 3-5个敌人
    local heroLevel = Random:Next(30, 80)  -- 英雄等级 30-80
    local heroStar = Random:Next(3, 7)  -- 英雄星级 3-7星
    
    Log(string.format("\n战斗参数:"))
    Log(string.format("  英雄数量: %d", heroCount))
    Log(string.format("  敌人数量: %d", enemyCount))
    Log(string.format("  英雄等级: Lv%d ★%d", heroLevel, heroStar))
    
    -- 创建队伍
    Log("\n创建随机队伍...")
    local leftTeam = GetRandomHeroes(heroCount, heroLevel, heroStar)
    local rightTeam = GetEnemiesByLevel(heroLevel, enemyCount)
    
    if #leftTeam == 0 or #rightTeam == 0 then
        Log("队伍创建失败，无法开始战斗")
        return nil
    end
    
    -- 显示队伍战力
    local leftPower = CalculateTeamPower(leftTeam)
    local rightPower = CalculateTeamPower(rightTeam)
    Log(string.format("\n队伍战力对比:"))
    Log(string.format("  英雄方: %.0f", leftPower))
    Log(string.format("  敌人方: %.0f", rightPower))
    Log(string.format("  战力比: %.2f", leftPower / rightPower))
    
    -- 开始战斗
    Log("\n开始战斗!")
    Log(string.rep("=", 50))
    
    local maxRounds = 50
    local winner = nil
    
    for round = 1, maxRounds do
        local finished, leftAlive, rightAlive = ExecuteRound(round, leftTeam, rightTeam)
        
        Log(string.format("回合结束 - 英雄存活: %d, 敌人存活: %d", leftAlive, rightAlive))
        
        if finished then
            if leftAlive > 0 then
                winner = "heroes"
            else
                winner = "enemies"
            end
            break
        end
        
        if round == maxRounds then
            Log("达到最大回合数，战斗结束")
            local leftAlive = #GetAliveUnits(leftTeam)
            local rightAlive = #GetAliveUnits(rightTeam)
            if leftAlive > rightAlive then
                winner = "heroes"
            elseif rightAlive > leftAlive then
                winner = "enemies"
            else
                winner = "draw"
            end
        end
    end
    
    -- 显示结果
    Log(string.rep("=", 50))
    Log("战斗结束!")
    
    local winnerNames = {
        heroes = "英雄方获胜",
        enemies = "敌人方获胜",
        draw = "平局"
    }
    Log(string.format("获胜方: %s", winnerNames[winner] or winner))
    
    local leftAlive = #GetAliveUnits(leftTeam)
    local rightAlive = #GetAliveUnits(rightTeam)
    Log(string.format("最终存活 - 英雄: %d/%d, 敌人: %d/%d", 
        leftAlive, #leftTeam, rightAlive, #rightTeam))
    
    Log(string.rep("=", 50))
    Log("随机战斗测试完成!")
    
    return {
        winner = winner,
        leftAlive = leftAlive,
        rightAlive = rightAlive,
        totalRounds = maxRounds,
        leftTeam = leftTeam,
        rightTeam = rightTeam
    }
end

-- 运行多次随机战斗
local function RunMultipleBattles(battleCount)
    battleCount = battleCount or 5
    
    Log(string.format("\n运行 %d 场随机战斗...", battleCount))
    Log(string.rep("=", 50))
    
    local results = {
        heroes = 0,
        enemies = 0,
        draw = 0
    }
    
    for i = 1, battleCount do
        Log(string.format("\n========== 第 %d/%d 场战斗 ==========", i, battleCount))
        local result = RunRandomBattle()
        if result then
            results[result.winner] = (results[result.winner] or 0) + 1
        end
    end
    
    Log(string.rep("=", 50))
    Log("多场战斗统计:")
    Log(string.format("  英雄获胜: %d 场", results.heroes))
    Log(string.format("  敌人获胜: %d 场", results.enemies))
    Log(string.format("  平局: %d 场", results.draw))
    Log(string.rep("=", 50))
end

-- 主函数
local function main()
    -- 解析命令行参数
    local battleCount = 1
    if arg and arg[1] then
        battleCount = tonumber(arg[1]) or 1
    end
    
    if battleCount > 1 then
        RunMultipleBattles(battleCount)
    else
        RunRandomBattle()
    end
end

main()
