-- 技能战斗测试模块
-- 集成技能系统的战斗测试

local BattleWithSkills = {}

-- 设置包路径
local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = package.path
    .. ";" .. script_dir .. "../?.lua"
    .. ";" .. script_dir .. "../core/?.lua"
    .. ";" .. script_dir .. "../modules/?.lua"
    .. ";" .. script_dir .. "../config/?.lua"
    .. ";" .. script_dir .. "../utils/?.lua"

-- 加载必要的模块
require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local BattleFormula = require("core.battle_formula")
local SkillData = require("config.skill_data")
local SkillLoader = require("core.skill_loader")
local SkillExecutor = require("core.skill_executor")

-- 日志函数
local function Log(msg)
    print(string.format("[SKILL BATTLE] %s", msg))
end

-- 创建英雄（带技能）
local function CreateHeroWithSkills(heroId, level, star, position)
    local heroData, err = AllyData.ConvertToHeroData(heroId, level, star)
    if not heroData then
        return nil, err
    end
    
    -- 获取英雄的技能（根据RelationConfigID）
    -- 注意：SkillData中的ClassID格式为1310101, 1310102等
    -- 使用RelationConfigID（如13101）+ 01后缀来构建ClassID
    local relationConfigId = heroData.config and heroData.config.RelationConfigID or heroId
    local skillClassId = relationConfigId * 100 + 1  -- 13101 -> 1310101
    local skills = SkillData.GetSkillsByClass(skillClassId)
    
    -- 选择小技能（Type=1）和大招（Type=2）
    local normalSkill = nil
    local ultimateSkill = nil
    
    for _, skill in ipairs(skills) do
        if skill.Type == 1 and not normalSkill then
            normalSkill = skill
        elseif skill.Type == 2 and not ultimateSkill then
            ultimateSkill = skill
        end
    end
    
    -- 加载技能Lua数据
    local normalSkillLua = nil
    local ultimateSkillLua = nil
    
    if normalSkill then
        normalSkillLua, _ = SkillLoader.Load(normalSkill.ID)
        if normalSkillLua then
            normalSkill.effects = SkillExecutor.ExtractSkillEffects(normalSkillLua)
        end
    end
    
    if ultimateSkill then
        ultimateSkillLua, _ = SkillLoader.Load(ultimateSkill.ID)
        if ultimateSkillLua then
            ultimateSkill.effects = SkillExecutor.ExtractSkillEffects(ultimateSkillLua)
        end
    end
    
    return {
        id = heroId,
        name = string.format("Hero_%d", heroId),
        hp = heroData.hp or 1000,
        maxHp = heroData.maxHp or 1000,
        atk = heroData.atk or 100,
        def = heroData.def or 50,
        spd = heroData.spd or 100,
        crt = heroData.crt or 0.1,
        crtd = heroData.crtd or 1.5,
        hit = heroData.hit or 1.0,
        res = heroData.res or 0,
        Class = heroData.class or 2,
        side = "left",
        position = position,
        energy = 0,
        maxEnergy = 100,
        isAlive = true,
        buffs = {},
        -- 技能相关
        normalSkill = normalSkill,
        ultimateSkill = ultimateSkill,
        skillCooldown = 0,
        maxSkillCooldown = 3  -- 技能冷却3回合
    }
end

-- 创建敌人（简化版，不带技能）
local function CreateEnemy(enemyId, position, heroLevel)
    local enemyData = EnemyData.GetEnemy(enemyId)
    if not enemyData then
        return nil, "Enemy not found"
    end
    
    local level = heroLevel or 60
    local star = 5
    local quality = 4
    
    local baseHP = 12000 + level * 180 + star * 400
    local baseATK = 220 + level * 3 + star * 10
    local baseDEF = 100 + level * 4 + star * 10
    local baseSPD = 80 + level * 0.5
    
    local qualityMultipliers = {1.0, 1.1, 1.2, 1.3, 1.5, 1.8}
    local qm = qualityMultipliers[quality] or 1.0
    
    return {
        id = enemyId,
        name = string.format("Enemy_%d", enemyId),
        hp = math.floor(baseHP * qm),
        maxHp = math.floor(baseHP * qm),
        atk = math.floor(baseATK * qm),
        def = math.floor(baseDEF * qm),
        spd = math.floor(baseSPD),
        crt = 0.05 + star * 0.005,
        crtd = 1.5,
        hit = 1.0,
        res = 0,
        Class = enemyData.Class or 2,
        side = "right",
        position = position,
        energy = 0,
        maxEnergy = 100,
        isAlive = true,
        buffs = {}
    }
end

-- 计算技能伤害
local function CalculateSkillDamage(attacker, defender, skill)
    if not skill or not skill.effects then
        return CalculateNormalDamage(attacker, defender)
    end
    
    local totalDamage = 0
    local isCrit = false
    
    -- 遍历所有伤害效果
    for _, dmgEffect in ipairs(skill.effects.damages) do
        -- 基础伤害计算（简化版）
        local baseDamage = attacker.atk * 1.5  -- 技能伤害系数1.5
        local damage = baseDamage - defender.def
        if damage < 1 then damage = 1 end
        
        -- 暴击判定
        if math.random() < (attacker.crt or 0.1) then
            damage = damage * (attacker.crtd or 1.5)
            isCrit = true
        end
        
        totalDamage = totalDamage + math.floor(damage)
    end
    
    return totalDamage, isCrit
end

-- 计算普通伤害
local function CalculateNormalDamage(attacker, defender)
    local result = BattleFormula.CalcDamage(attacker, defender, 10000, E_ATTACK_TYPE.Physical)
    return result.damage, result.isCrit
end

-- 执行攻击（普通攻击或技能）
local function ExecuteAttack(attacker, defender, useSkill)
    local damage, isCrit
    local attackType = "普通攻击"
    
    if useSkill and attacker.normalSkill and attacker.skillCooldown <= 0 then
        -- 使用技能
        damage, isCrit = CalculateSkillDamage(attacker, defender, attacker.normalSkill)
        attackType = string.format("技能[%s]", attacker.normalSkill.Name or "Unknown")
        attacker.skillCooldown = attacker.maxSkillCooldown
    else
        -- 普通攻击
        damage, isCrit = CalculateNormalDamage(attacker, defender)
        -- 减少技能冷却（只对英雄有效）
        if attacker.skillCooldown and attacker.skillCooldown > 0 then
            attacker.skillCooldown = attacker.skillCooldown - 1
        end
    end
    
    defender.hp = (defender.hp or 0) - damage
    
    if defender.hp <= 0 then
        defender.hp = 0
        defender.isAlive = false
    end
    
    return {
        attacker = attacker.name,
        defender = defender.name,
        damage = damage,
        isCrit = isCrit,
        attackType = attackType,
        defenderHP = defender.hp,
        defenderAlive = defender.isAlive,
        skillCooldown = attacker.skillCooldown
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
    return alive[math.random(1, #alive)]
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
        return (a.spd or 0) > (b.spd or 0)
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
            -- 决定是否使用技能（有技能且冷却完毕且能量足够）
            local useSkill = false
            if unit.normalSkill and unit.skillCooldown <= 0 and unit.energy >= 30 then
                useSkill = true
                unit.energy = unit.energy - 30  -- 技能消耗30能量
            end
            
            -- 执行攻击
            local result = ExecuteAttack(unit, target, useSkill)
            local critStr = result.isCrit and " [暴击!]" or ""
            local cooldownStr = "" 
            if unit.skillCooldown and unit.skillCooldown > 0 then
                cooldownStr = string.format(" [技能CD:%d]", unit.skillCooldown)
            end
            
            Log(string.format("%s 使用 %s 攻击 %s, 造成 %d 伤害%s, %s 剩余 HP: %d/%d%s",
                result.attacker, result.attackType, result.defender, 
                result.damage, critStr,
                result.defender, result.defenderHP, target.maxHp or 100,
                cooldownStr))
            
            -- 增加能量（普通攻击回复能量）
            if not useSkill then
                unit.energy = math.min(unit.energy + 20, unit.maxEnergy)
            end
            
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

-- 运行技能战斗测试
function BattleWithSkills.Run()
    Log("开始技能战斗测试...")
    Log(string.rep("=", 50))
    
    -- 初始化数据
    Log("初始化数据模块...")
    AllyData.Init()
    EnemyData.Init()
    
    math.randomseed(os.time())
    
    -- 创建队伍
    Log("\n创建战斗队伍...")
    local leftTeam = {}
    local rightTeam = {}
    
    -- 创建3个英雄（带技能）
    local heroIds = {13101, 13102, 13103}
    for i, heroId in ipairs(heroIds) do
        local hero, err = CreateHeroWithSkills(heroId, 60, 5, i)
        if hero then
            table.insert(leftTeam, hero)
            local skillInfo = ""
            if hero.normalSkill then
                skillInfo = string.format(" [技能:%s]", hero.normalSkill.Name or "Unknown")
            end
            Log(string.format("左侧队伍: %s (HP:%.0f ATK:%.0f DEF:%.0f SPD:%.0f)%s",
                hero.name, hero.hp or 0, hero.atk or 0, hero.def or 0, hero.spd or 0, skillInfo))
        else
            Log(string.format("创建英雄 %d 失败: %s", heroId, tostring(err)))
        end
    end
    
    -- 创建4个敌人
    local enemyIds = {20701, 20702, 20703, 20704}
    for i, enemyId in ipairs(enemyIds) do
        local enemy, err = CreateEnemy(enemyId, i, 60)
        if enemy then
            table.insert(rightTeam, enemy)
            Log(string.format("右侧队伍: %s (HP:%d ATK:%d DEF:%d SPD:%d)",
                enemy.name, enemy.hp or 0, enemy.atk or 0, enemy.def or 0, enemy.spd or 0))
        else
            Log(string.format("创建敌人 %d 失败: %s", enemyId, tostring(err)))
        end
    end
    
    Log(string.format("\n队伍创建完成: 左侧%d人 vs 右侧%d人", #leftTeam, #rightTeam))
    
    -- 开始战斗
    Log("\n开始战斗!")
    Log(string.rep("=", 50))
    
    local maxRounds = 50
    local winner = nil
    
    for round = 1, maxRounds do
        local finished, leftAlive, rightAlive = ExecuteRound(round, leftTeam, rightTeam)
        
        Log(string.format("回合结束 - 左侧存活: %d, 右侧存活: %d", leftAlive, rightAlive))
        
        if finished then
            if leftAlive > 0 then
                winner = "left"
            else
                winner = "right"
            end
            break
        end
        
        if round == maxRounds then
            Log("达到最大回合数，战斗结束")
            local leftAlive = #GetAliveUnits(leftTeam)
            local rightAlive = #GetAliveUnits(rightTeam)
            if leftAlive > rightAlive then
                winner = "left"
            elseif rightAlive > leftAlive then
                winner = "right"
            else
                winner = "draw"
            end
        end
    end
    
    -- 显示结果
    Log(string.rep("=", 50))
    Log("战斗结束!")
    Log(string.format("获胜方: %s", winner or "未知"))
    
    local leftAlive = #GetAliveUnits(leftTeam)
    local rightAlive = #GetAliveUnits(rightTeam)
    Log(string.format("最终存活 - 左侧: %d, 右侧: %d", leftAlive, rightAlive))
    
    Log(string.rep("=", 50))
    Log("技能战斗测试完成!")
    
    return {
        winner = winner,
        leftAlive = leftAlive,
        rightAlive = rightAlive
    }
end

return BattleWithSkills
