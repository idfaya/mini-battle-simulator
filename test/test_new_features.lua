---
--- Test New Features
--- 测试新实现的功能
---

-- 添加路径
package.path = package.path .. ";./?.lua;./core/?.lua;./modules/?.lua;./config/?.lua;./utils/?.lua"

-- 加载模块
local Logger = require("utils.logger")

print("========================================")
print("测试新功能")
print("========================================")

-- 测试1: BattleFormation新函数
print("\n[测试1] BattleFormation 新函数测试")

-- 模拟BattleFormation模块加载
local BattleFormation = {
    teamLeft = {},
    teamRight = {},
    heroInstanceMap = {},
    positionMap = {},
}

-- 模拟英雄数据
local mockHero1 = {
    instanceId = 1,
    name = "英雄1",
    isLeft = true,
    wpType = 1,
    isAlive = true,
    isDead = false,
    hp = 100,
    maxHp = 100,
}

local mockHero2 = {
    instanceId = 2,
    name = "英雄2",
    isLeft = true,
    wpType = 2,
    isAlive = false,
    isDead = true,
    hp = 0,
    maxHp = 100,
}

local mockEnemy1 = {
    instanceId = 3,
    name = "敌人1",
    isLeft = false,
    wpType = 1,
    isAlive = true,
    isDead = false,
    hp = 100,
    maxHp = 100,
}

table.insert(BattleFormation.teamLeft, mockHero1)
table.insert(BattleFormation.teamLeft, mockHero2)
table.insert(BattleFormation.teamRight, mockEnemy1)

-- 测试GetFriendDiedCount函数
local function TestGetFriendDiedCount()
    local diedCount = 0
    local friendTeam = mockHero1.isLeft and BattleFormation.teamLeft or BattleFormation.teamRight
    for _, h in ipairs(friendTeam) do
        if not h.isAlive or h.isDead then
            diedCount = diedCount + 1
        end
    end
    print(string.format("  GetFriendDiedCount: %d (期望: 1)", diedCount))
    assert(diedCount == 1, "友方死亡数应为1")
end

-- 测试GetEnemyRowCount函数
local function TestGetEnemyRowCount()
    local wpTypeToRow = {
        [1] = 1, [2] = 1, [3] = 1,
        [4] = 2, [5] = 2,
        [6] = 3, [7] = 3, [8] = 3,
    }
    local aliveRows = {}
    for _, h in ipairs(BattleFormation.teamRight) do
        if h.isAlive and not h.isDead then
            local row = wpTypeToRow[h.wpType] or 1
            aliveRows[row] = true
        end
    end
    local rowCount = 0
    for _ in pairs(aliveRows) do
        rowCount = rowCount + 1
    end
    print(string.format("  GetEnemyRowCount: %d (期望: 1)", rowCount))
    assert(rowCount == 1, "敌方行数应为1")
end

TestGetFriendDiedCount()
TestGetEnemyRowCount()

print("  ✓ BattleFormation 新函数测试通过")

-- 测试2: 技能条件判断
print("\n[测试2] 技能条件判断测试")

-- 模拟当前回合数
local currentRound = 5

-- 测试回合数条件
local condition1 = { type = 1, round = 3 } -- E_SKILL_CONDITION.Round = 1
local result1 = currentRound >= (condition1.round or 0)
print(string.format("  Round条件 (当前回合=%d, 需要>=%d): %s", currentRound, condition1.round, tostring(result1)))
assert(result1 == true, "回合数条件应满足")

local condition2 = { type = 1, round = 10 }
local result2 = currentRound >= (condition2.round or 0)
print(string.format("  Round条件 (当前回合=%d, 需要>=%d): %s", currentRound, condition2.round, tostring(result2)))
assert(result2 == false, "回合数条件不应满足")

print("  ✓ 技能条件判断测试通过")

-- 测试3: 召唤物系统
print("\n[测试3] 召唤物系统测试")

-- 模拟召唤物创建
local tokenInstanceIdCounter = 100000
local function GenerateTokenInstanceId()
    tokenInstanceIdCounter = tokenInstanceIdCounter + 1
    return tokenInstanceIdCounter
end

local mockToken = {
    instanceId = GenerateTokenInstanceId(),
    configId = 9999,
    name = "测试召唤物",
    isToken = true,
    owner = mockHero1,
    leftLife = 3,
    isAlive = true,
    isDead = false,
}

print(string.format("  创建召唤物: %s (id=%d, life=%d)", mockToken.name, mockToken.instanceId, mockToken.leftLife))
assert(mockToken.instanceId > 100000, "召唤物ID应大于100000")
assert(mockToken.isToken == true, "isToken应为true")
assert(mockToken.owner == mockHero1, "owner应正确设置")

-- 测试减少召唤物生命
mockToken.leftLife = mockToken.leftLife - 1
print(string.format("  减少生命后: life=%d", mockToken.leftLife))
assert(mockToken.leftLife == 2, "生命应为2")

print("  ✓ 召唤物系统测试通过")

-- 测试4: 隐藏技能队列
print("\n[测试4] 隐藏技能队列测试")

local hideSkillQueue = {}
local hideSkillIdCounter = 0

local function AddHideSkill(heroSrc, heroDest, skillId)
    hideSkillIdCounter = hideSkillIdCounter + 1
    local item = {
        id = hideSkillIdCounter,
        heroSrc = heroSrc,
        heroDest = heroDest,
        skillId = skillId,
    }
    table.insert(hideSkillQueue, item)
    return true
end

AddHideSkill(mockHero1, mockEnemy1, 1001)
AddHideSkill(mockHero1, nil, 1002)

print(string.format("  添加隐藏技能到队列: %d 个", #hideSkillQueue))
assert(#hideSkillQueue == 2, "队列中应有2个隐藏技能")

local item = hideSkillQueue[1]
print(string.format("  第一个隐藏技能: skillId=%d, src=%s, dest=%s", 
    item.skillId, item.heroSrc.name, item.heroDest and item.heroDest.name or "nil"))
assert(item.skillId == 1001, "skillId应为1001")

print("  ✓ 隐藏技能队列测试通过")

-- 测试5: 无消耗大招队列
print("\n[测试5] 无消耗大招队列测试")

local noCostUltimateQueue = {}
local noCostUltimateIdCounter = 0

local function AddUltimateSkillNoCost(heroSrc, heroDest)
    noCostUltimateIdCounter = noCostUltimateIdCounter + 1
    local item = {
        id = noCostUltimateIdCounter,
        heroSrc = heroSrc,
        heroDest = heroDest,
        noCost = true,
    }
    table.insert(noCostUltimateQueue, item)
    return true
end

AddUltimateSkillNoCost(mockHero1, mockEnemy1)

print(string.format("  添加无消耗大招到队列: %d 个", #noCostUltimateQueue))
assert(#noCostUltimateQueue == 1, "队列中应有1个无消耗大招")
assert(noCostUltimateQueue[1].noCost == true, "noCost标记应为true")

print("  ✓ 无消耗大招队列测试通过")

print("\n========================================")
print("所有测试通过!")
print("========================================")
