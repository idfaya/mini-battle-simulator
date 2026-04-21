--[[
    配置驱动技能系统 Viewport 测试 (bin版)
    从当前配置表自动读取英雄/敌人
    使用方法: lua test_viewport_final.lua [等级] [英雄数量] [敌人数量] [更新速度]
--]]

os.execute("chcp 65001 >nul 2>&1")

package.path = package.path .. ";../?.lua;../?/init.lua"

local targetLevel = tonumber(arg[1]) or 20
local heroCount = math.min(tonumber(arg[2]) or 3, 6)
local enemyCount = math.min(tonumber(arg[3]) or 6, 6)
local updateSpeed = tonumber(arg[4]) or 800

print(string.format("=== Viewport 战斗测试 (Lv.%d) ===", targetLevel))

require("core.battle_enum")
require("modules.BattleDefaultTypesOpt")
local BattleHeroFactory = require("modules.battle_hero_factory")
local BattleDriver = require("modules.battle_driver")
local ViewportRenderer = require("ui.viewport_renderer")
local Logger = require("utils.logger")
local ArrayUtils = require("utils.array_utils")

Logger.SetLogLevel(Logger.LOG_LEVELS.INFO)
ViewportRenderer.SetFastMode(updateSpeed <= 0)

local function Main()
    math.randomseed(os.time())

    local HeroData = require("config.hero_data")
    local EnemyData = require("config.enemy_data")

    local allHeroIds = {}
    for _, h in ipairs(HeroData.GetPlayableHeroes()) do
        if h.AllyID then table.insert(allHeroIds, h.AllyID) end
    end
    local allEnemyIds = EnemyData.GetAllEnemyIds()
    local allBossIds = EnemyData.GetAllBossIds()

    print(string.format("可用英雄: %d, 小怪: %d, Boss: %d", #allHeroIds, #allEnemyIds, #allBossIds))
    if #allHeroIds == 0 then
        print("错误: 无法加载英雄配置")
        return
    end

    local selectedHeroIds = ArrayUtils.RandomSelect(allHeroIds, heroCount)
    local selectedEnemyIds = {}
    local selectedEnemyMap = {}
    local function AddEnemyId(id)
        if id and not selectedEnemyMap[id] then
            selectedEnemyMap[id] = true
            table.insert(selectedEnemyIds, id)
        end
    end
    if #allBossIds > 0 then
        AddEnemyId(allBossIds[math.random(#allBossIds)])
    end
    local remaining = enemyCount - #selectedEnemyIds
    if remaining > 0 and #allEnemyIds > 0 then
        for _, id in ipairs(ArrayUtils.RandomSelect(allEnemyIds, remaining)) do
            AddEnemyId(id)
        end
    end
    if #selectedEnemyIds < enemyCount then
        for _, id in ipairs(allEnemyIds) do
            AddEnemyId(id)
            if #selectedEnemyIds >= enemyCount then
                break
            end
        end
    end

    print("\n【英雄阵容】")
    local heroes = {}
    for i, id in ipairs(selectedHeroIds) do
        local h = BattleHeroFactory.CreateHero(id, targetLevel, 5)
        if h then
            h.wpType = i
            h.isLeft = true
            table.insert(heroes, h)
            print(string.format("  %d. %s (HP:%d ATK:%d DEF:%d)", i, h.name or ("Hero_" .. id), h.hp or 0, h.atk or 0, h.def or 0))
        end
    end

    print("\n【敌人阵容】")
    local enemies = {}
    for i, id in ipairs(selectedEnemyIds) do
        local e = BattleHeroFactory.CreateEnemy(id, targetLevel)
        if e then
            e.wpType = i
            e.isLeft = false
            table.insert(enemies, e)
            local prefix = (e._monsterType == 2) and "【BOSS】" or ""
            print(string.format("  %d. %s%s (HP:%d ATK:%d)", i, prefix, e.name or ("Enemy_" .. id), e.hp or 0, e.atk or 0))
        end
    end

    if #heroes == 0 or #enemies == 0 then
        print("\n错误: 阵容创建失败，无法开始战斗")
        return
    end

    print("\n=== 启动 Viewport 战斗 ===\n")

    BattleDriver.Init({
        maxSteps = 20000,
        updateInterval = updateSpeed,
    })

    BattleDriver.Start({
        teamLeft = heroes,
        teamRight = enemies,
        seedArray = {os.time(), math.random(1000000), 123456789, 362436069},
        disableDefaultRenderer = true,
        renderer = ViewportRenderer,
    }, function(result)
        print("\n=== 战斗结束 ===")
        if result then
            print(string.format("胜利方: %s", result.winner or "未知"))
            print(string.format("总回合: %d", result.totalRound or result.totalRounds or 0))
        end
    end)

    BattleDriver.RunUntilEnd()

    print("\n=== 测试完成 ===")
end

Main()
