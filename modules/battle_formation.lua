---
--- Battle Formation Module
--- 管理战斗双方的阵型、英雄位置和状态
---

local Logger = require("utils.logger")

---@class BattleFormation
local BattleFormation = {}

-- 队伍数据
BattleFormation.teamLeft = {}   -- 左侧队伍 (camp A)
BattleFormation.teamRight = {}  -- 右侧队伍 (camp B)

-- 英雄实例映射表
BattleFormation.heroInstanceMap = {}  -- key: instanceId, value: hero

-- 位置映射表
BattleFormation.positionMap = {}  -- key: "isLeft_wpType", value: instanceId

-- 实例ID计数器
BattleFormation.instanceIdCounter = 0

--- 生成唯一实例ID
---@return number 实例ID
local function GenerateInstanceId()
    BattleFormation.instanceIdCounter = BattleFormation.instanceIdCounter + 1
    return BattleFormation.instanceIdCounter
end

--- 创建英雄数据结构
---@param heroData table 英雄原始数据
---@param wpType number 位置类型
---@param isLeft boolean 是否在左侧队伍
---@return table 英雄对象
local function CreateHero(heroData, wpType, isLeft)
    local hero = {
        -- 基础信息
        instanceId = GenerateInstanceId(),
        configId = heroData.configId or heroData.heroId or 0,
        name = heroData.name or "Unknown",
        wpType = wpType,
        camp = isLeft and E_CAMP_TYPE.A or E_CAMP_TYPE.B,
        isLeft = isLeft,
        
        -- 等级和基础属性
        level = heroData.level or 1,
        hp = heroData.hp or heroData.curHp or 0,
        maxHp = heroData.maxHp or heroData.hp or 100,
        atk = heroData.atk or 0,
        def = heroData.def or 0,
        speed = heroData.speed or 0,
        
        -- 扩展属性
        critRate = heroData.critRate or 0,
        critDamage = heroData.critDamage or 150,
        hitRate = heroData.hitRate or 100,
        dodgeRate = heroData.dodgeRate or 0,
        damageReduce = heroData.damageReduce or 0,
        damageIncrease = heroData.damageIncrease or 0,
        
        -- 技能相关
        skills = heroData.skills or {},
        passiveSkills = heroData.passiveSkills or {},
        buffs = {},
        
        -- 能量相关
        energy = heroData.energy or 0,
        maxEnergy = heroData.maxEnergy or 100,
        energyType = heroData.energyType or E_ENERGY_TYPE.Bar,
        
        -- 战斗状态
        isAlive = true,
        isDead = false,
        actionForce = 0,
        
        -- 额外数据
        extraData = heroData.extraData or {},
    }
    
    -- 确保HP不超过最大值
    if hero.hp > hero.maxHp then
        hero.hp = hero.maxHp
    end
    
    return hero
end

--- 从beginState初始化阵型
---@param beginState table 战斗开始状态
---@param fieldInfo table 战场信息 (可选)
function BattleFormation.Init(beginState, fieldInfo)
    Logger.Debug("BattleFormation.Init - 开始初始化阵型")
    
    -- 清理旧数据
    BattleFormation.OnFinal()
    
    if not beginState then
        Logger.LogWarning("BattleFormation.Init - beginState 为空")
        return
    end
    
    -- 初始化左侧队伍
    if beginState.teamLeft then
        Logger.Debug(string.format("BattleFormation.Init - 初始化左侧队伍，英雄数量: %d", #beginState.teamLeft))
        for _, heroData in ipairs(beginState.teamLeft) do
            local wpType = heroData.wpType or 0
            local hero = CreateHero(heroData, wpType, true)
            table.insert(BattleFormation.teamLeft, hero)
            BattleFormation.heroInstanceMap[hero.instanceId] = hero
            BattleFormation.positionMap["true_" .. wpType] = hero.instanceId
            Logger.Debug(string.format("  添加左侧英雄: %s (instanceId: %d, wpType: %d)", hero.name, hero.instanceId, wpType))
        end
    end
    
    -- 初始化右侧队伍
    if beginState.teamRight then
        Logger.Debug(string.format("BattleFormation.Init - 初始化右侧队伍，英雄数量: %d", #beginState.teamRight))
        for _, heroData in ipairs(beginState.teamRight) do
            local wpType = heroData.wpType or 0
            local hero = CreateHero(heroData, wpType, false)
            table.insert(BattleFormation.teamRight, hero)
            BattleFormation.heroInstanceMap[hero.instanceId] = hero
            BattleFormation.positionMap["false_" .. wpType] = hero.instanceId
            Logger.Debug(string.format("  添加右侧英雄: %s (instanceId: %d, wpType: %d)", hero.name, hero.instanceId, wpType))
        end
    end
    
    Logger.Debug(string.format("BattleFormation.Init - 初始化完成，总英雄数: %d", 
        #BattleFormation.teamLeft + #BattleFormation.teamRight))
end

--- 清理阵型数据
function BattleFormation.OnFinal()
    Logger.Debug("BattleFormation.OnFinal - 清理阵型数据")
    
    BattleFormation.teamLeft = {}
    BattleFormation.teamRight = {}
    BattleFormation.heroInstanceMap = {}
    BattleFormation.positionMap = {}
    BattleFormation.instanceIdCounter = 0
end

--- 根据实例ID查找英雄
---@param instanceId number 实例ID
---@return table|nil 英雄对象，未找到返回nil
function BattleFormation.FindHeroByInstanceId(instanceId)
    if not instanceId then
        return nil
    end
    return BattleFormation.heroInstanceMap[instanceId]
end

--- 根据阵营和位置查找英雄
---@param isLeft boolean 是否在左侧队伍
---@param wpType number 位置类型
---@return table|nil 英雄对象，未找到返回nil
function BattleFormation.FindHeroByCampAndPos(isLeft, wpType)
    local key = tostring(isLeft) .. "_" .. (wpType or 0)
    local instanceId = BattleFormation.positionMap[key]
    if instanceId then
        return BattleFormation.heroInstanceMap[instanceId]
    end
    return nil
end

--- 获取双方队伍
---@return table, table 左侧队伍和右侧队伍
function BattleFormation.GetTeams()
    return BattleFormation.teamLeft, BattleFormation.teamRight
end

--- 获取友好队伍
---@param hero table 英雄对象
---@return table 友好队伍数组
function BattleFormation.GetFriendTeam(hero)
    if not hero then
        Logger.LogWarning("BattleFormation.GetFriendTeam - hero 为空")
        return {}
    end
    return hero.isLeft and BattleFormation.teamLeft or BattleFormation.teamRight
end

--- 获取敌方队伍
---@param hero table 英雄对象
---@return table 敌方队伍数组
function BattleFormation.GetEnemyTeam(hero)
    if not hero then
        Logger.LogWarning("BattleFormation.GetEnemyTeam - hero 为空")
        return {}
    end
    return hero.isLeft and BattleFormation.teamRight or BattleFormation.teamLeft
end

--- 获取随机敌人的实例ID
---@param hero table 英雄对象
---@return number|nil 随机敌人的实例ID，无敌人返回nil
function BattleFormation.GetRandomEnemyInstanceId(hero)
    local enemyTeam = BattleFormation.GetEnemyTeam(hero)
    if not enemyTeam or #enemyTeam == 0 then
        return nil
    end
    
    -- 只选择存活的敌人
    local aliveEnemies = {}
    for _, enemy in ipairs(enemyTeam) do
        if enemy.isAlive and not enemy.isDead then
            table.insert(aliveEnemies, enemy)
        end
    end
    
    if #aliveEnemies == 0 then
        return nil
    end
    
    local randomIndex = math.random(1, #aliveEnemies)
    return aliveEnemies[randomIndex].instanceId
end

--- 获取随机友军的实例ID
---@param hero table 英雄对象
---@param includeSelf boolean 是否包含自己
---@return number|nil 随机友军的实例ID，无友军返回nil
function BattleFormation.GetRandomFriendInstanceId(hero, includeSelf)
    local friendTeam = BattleFormation.GetFriendTeam(hero)
    if not friendTeam or #friendTeam == 0 then
        return nil
    end
    
    -- 只选择存活的友军
    local aliveFriends = {}
    for _, friend in ipairs(friendTeam) do
        if friend.isAlive and not friend.isDead then
            if includeSelf or friend.instanceId ~= hero.instanceId then
                table.insert(aliveFriends, friend)
            end
        end
    end
    
    if #aliveFriends == 0 then
        return nil
    end
    
    local randomIndex = math.random(1, #aliveFriends)
    return aliveFriends[randomIndex].instanceId
end

--- 根据位置获取实例ID
---@param isLeft boolean 是否在左侧队伍
---@param wpType number 位置类型
---@return number|nil 实例ID，未找到返回nil
function BattleFormation.GetInstanceIdByWpType(isLeft, wpType)
    local key = tostring(isLeft) .. "_" .. (wpType or 0)
    return BattleFormation.positionMap[key]
end

--- 从队伍中移除英雄
---@param hero table 英雄对象
function BattleFormation.RemoveHero(hero)
    if not hero then
        Logger.LogWarning("BattleFormation.RemoveHero - hero 为空")
        return
    end
    
    local team = hero.isLeft and BattleFormation.teamLeft or BattleFormation.teamRight
    local key = tostring(hero.isLeft) .. "_" .. hero.wpType
    
    -- 从队伍数组中移除
    for i, h in ipairs(team) do
        if h.instanceId == hero.instanceId then
            table.remove(team, i)
            Logger.Debug(string.format("RemoveHero - 从队伍移除英雄: %s (instanceId: %d)", hero.name, hero.instanceId))
            break
        end
    end
    
    -- 从映射表中移除
    BattleFormation.heroInstanceMap[hero.instanceId] = nil
    BattleFormation.positionMap[key] = nil
    
    -- 标记为死亡
    hero.isAlive = false
    hero.isDead = true
end

--- 复活英雄
---@param wpType number 位置类型
---@param heroData table 英雄数据
---@param isLeft boolean 是否在左侧队伍 (默认为true)
---@return table|nil 复活的英雄对象
function BattleFormation.ReviveHero(wpType, heroData, isLeft)
    if not heroData then
        Logger.LogWarning("BattleFormation.ReviveHero - heroData 为空")
        return nil
    end
    
    isLeft = isLeft ~= false  -- 默认为true
    
    -- 检查位置是否已被占用
    local existingInstanceId = BattleFormation.GetInstanceIdByWpType(isLeft, wpType)
    if existingInstanceId then
        local existingHero = BattleFormation.FindHeroByInstanceId(existingInstanceId)
        if existingHero and existingHero.isAlive then
            Logger.LogWarning(string.format("ReviveHero - 位置已被存活英雄占用: isLeft=%s, wpType=%d", 
                tostring(isLeft), wpType))
            return nil
        end
    end
    
    -- 创建新英雄
    local hero = CreateHero(heroData, wpType, isLeft)
    
    -- 标记为复活状态
    hero.isAlive = true
    hero.isDead = false
    hero.hp = heroData.hp or hero.maxHp * 0.3  -- 复活时恢复30%血量或指定血量
    
    -- 添加到队伍
    local team = isLeft and BattleFormation.teamLeft or BattleFormation.teamRight
    table.insert(team, hero)
    
    -- 更新映射表
    BattleFormation.heroInstanceMap[hero.instanceId] = hero
    local key = tostring(isLeft) .. "_" .. wpType
    BattleFormation.positionMap[key] = hero.instanceId
    
    Logger.Debug(string.format("ReviveHero - 复活英雄: %s (instanceId: %d, isLeft: %s, wpType: %d)", 
        hero.name, hero.instanceId, tostring(isLeft), wpType))
    
    return hero
end

--- 获取存活英雄数量
---@param isLeft boolean 是否在左侧队伍
---@return number 存活英雄数量
function BattleFormation.GetAliveHeroCount(isLeft)
    local team = isLeft and BattleFormation.teamLeft or BattleFormation.teamRight
    local count = 0
    for _, hero in ipairs(team) do
        if hero.isAlive and not hero.isDead then
            count = count + 1
        end
    end
    return count
end

--- 检查队伍是否全灭
---@param isLeft boolean 是否在左侧队伍
---@return boolean 是否全灭
function BattleFormation.IsTeamWiped(isLeft)
    return BattleFormation.GetAliveHeroCount(isLeft) == 0
end

--- 获取所有存活英雄
---@return table 所有存活英雄的数组
function BattleFormation.GetAllAliveHeroes()
    local aliveHeroes = {}
    
    for _, hero in ipairs(BattleFormation.teamLeft) do
        if hero.isAlive and not hero.isDead then
            table.insert(aliveHeroes, hero)
        end
    end
    
    for _, hero in ipairs(BattleFormation.teamRight) do
        if hero.isAlive and not hero.isDead then
            table.insert(aliveHeroes, hero)
        end
    end
    
    return aliveHeroes
end

--- 获取所有英雄（包括死亡）
---@return table 所有英雄的数组
function BattleFormation.GetAllHeroes()
    local allHeroes = {}
    
    for _, hero in ipairs(BattleFormation.teamLeft) do
        table.insert(allHeroes, hero)
    end
    
    for _, hero in ipairs(BattleFormation.teamRight) do
        table.insert(allHeroes, hero)
    end
    
    return allHeroes
end

--- 打印当前阵型信息（调试用）
function BattleFormation.DumpFormation()
    Logger.Debug("========== 当前阵型信息 ==========")
    Logger.Debug(string.format("左侧队伍 (存活: %d/%d):", 
        BattleFormation.GetAliveHeroCount(true), #BattleFormation.teamLeft))
    for _, hero in ipairs(BattleFormation.teamLeft) do
        Logger.Debug(string.format("  [%d] %s (wpType:%d) HP:%d/%d %s", 
            hero.instanceId, hero.name, hero.wpType, hero.hp, hero.maxHp,
            hero.isAlive and "存活" or "死亡"))
    end
    
    Logger.Debug(string.format("右侧队伍 (存活: %d/%d):", 
        BattleFormation.GetAliveHeroCount(false), #BattleFormation.teamRight))
    for _, hero in ipairs(BattleFormation.teamRight) do
        Logger.Debug(string.format("  [%d] %s (wpType:%d) HP:%d/%d %s", 
            hero.instanceId, hero.name, hero.wpType, hero.hp, hero.maxHp,
            hero.isAlive and "存活" or "死亡"))
    end
    Logger.Debug("==================================")
end

return BattleFormation
