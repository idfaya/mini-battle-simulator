-- 简化版战斗测试 - 只负责阵容配置

-- 设置UTF-8编码（Windows）
os.execute("chcp 65001 >nul 2>&1")

package.path = package.path
    .. ";./?.lua"
    .. ";./core/?.lua"
    .. ";./modules/?.lua"
    .. ";./config/?.lua"
    .. ";./utils/?.lua"

require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")

local BattleMain = require("modules.battle_main")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local SkillData = require("config.skill_data")
local Logger = require("utils.logger")

local SimpleBattleTest = {}

local function Log(msg)
    print(string.format("[SIMPLE BATTLE] %s", msg))
end

-- 创建英雄数据
local function CreateHero(heroId, level, star)
    local heroData = AllyData.ConvertToHeroData(heroId, level, star)
    if not heroData then return nil end
    
    -- 获取英雄技能（查询所有相关的ClassID）
    local relationConfigId = heroData.config and heroData.config.RelationConfigID or heroId
    heroData.skillsConfig = {}
    
    -- 查询多个ClassID（1310101, 1310102, 1310103等）
    for i = 1, 5 do
        local skillClassId = relationConfigId * 100 + i
        local skills = SkillData.GetSkillsByClass(skillClassId)
        
        for _, skill in ipairs(skills) do
            table.insert(heroData.skillsConfig, {
                skillId = skill.ID,
                skillType = skill.Type == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL,
                name = skill.Name,
                skillCost = skill.Type == 2 and 100 or 0
            })
        end
    end
    
    return heroData
end

-- 创建敌人数据
local function CreateEnemy(enemyId, level)
    local enemyData = EnemyData.GetEnemy(enemyId)
    if not enemyData then return nil end
    
    local star, quality = 5, 4
    local qm = ({1.0, 1.1, 1.2, 1.3, 1.5, 1.8})[quality] or 1.0
    
    return {
        id = enemyId,
        name = string.format("Enemy_%d", enemyId),
        hp = math.floor((12000 + level * 180 + star * 400) * qm),
        maxHp = math.floor((12000 + level * 180 + star * 400) * qm),
        atk = math.floor((220 + level * 3 + star * 10) * qm),
        def = math.floor((100 + level * 4 + star * 10) * qm),
        spd = math.floor(80 + level * 0.5),
        crt = 0.05 + star * 0.005,
        crtd = 1.5,
        hit = 1.0,
        res = 0,
        isAlive = true,
        skillsConfig = {{skillId = 1001, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击"}}
    }
end

function SimpleBattleTest.Run()
    Log("开始简化战斗测试")
    
    -- 设置日志级别为 DEBUG 以查看详细日志
    Logger.SetLogLevel(Logger.LOG_LEVELS.DEBUG)
    
    AllyData.Init()
    SkillData.GetSkill(131010101)
    
    local beginState = {teamLeft = {}, teamRight = {}, seedArray = {123456789, 362436069, 521288629, 88675123}}
    
    Log("创建左侧队伍（英雄）：")
    for _, heroId in ipairs({13101, 13102, 13103}) do
        local hero = CreateHero(heroId, 60, 5)
        if hero then
            table.insert(beginState.teamLeft, hero)
            Log(string.format("  %s (HP:%d ATK:%d DEF:%d SPD:%d) - %d个技能", hero.name, hero.maxHp, hero.atk, hero.def, hero.spd, #hero.skillsConfig))
        end
    end
    
    Log("创建右侧队伍（敌人）：")
    for _, enemyId in ipairs({20701, 20702, 20703, 20704}) do
        local enemy = CreateEnemy(enemyId, 60)
        if enemy then
            table.insert(beginState.teamRight, enemy)
            Log(string.format("  %s (HP:%d ATK:%d DEF:%d)", enemy.name, enemy.maxHp, enemy.atk, enemy.def))
        end
    end
    
    Log(string.format("阵容配置完成: %d vs %d", #beginState.teamLeft, #beginState.teamRight))
    
    local battleFinished = false
    local battleResult = nil
    
    BattleMain.Start(beginState, function(result)
        battleFinished = true
        battleResult = result
    end)
    
    Log("\n========== 开始战斗 ==========")
    
    -- 设置更新间隔为0，确保每帧都执行
    BattleMain.SetUpdateInterval(0)
    
    -- 手动驱动战斗回合
    local maxRounds = 50
    local round = 0
    
    while not battleFinished and round < maxRounds do
        BattleMain.Update()
        round = round + 1
        
        -- 简单的回合间隔
        if round % 10 == 0 then
            Log(string.format("--- 已执行 %d 回合 ---", round))
        end
    end
    
    if not battleFinished then
        Log(string.format("达到最大回合数 %d，强制结束战斗", maxRounds))
    end
    
    Log("\n========== 战斗结束 ==========")
    if battleResult then
        Log(string.format("获胜方: %s", battleResult.winner or "draw"))
        Log(string.format("结束原因: %s", battleResult.reason or "unknown"))
    end
end

return SimpleBattleTest
