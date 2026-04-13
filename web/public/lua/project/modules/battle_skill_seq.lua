---
--- Battle Skill Sequence Module
--- 战斗技能序列模块 - 管理终极技能队列和技能释放顺序
---

local Logger = require("utils.logger")

---@class BattleSkillSeq
local BattleSkillSeq = {}

-- 终极技能队列
local ultimateSkillQueue = {}

-- 被动技能队列: { [heroId] = { {hero, skill, buffSubType, funcName}, ... } }
local passiveSkillQueue = {}

-- 隐藏技能队列 (触发技能)
local hideSkillQueue = {}

-- 无消耗大招队列
local noCostUltimateQueue = {}

-- 技能序列ID计数器
local skillSeqIdCounter = 0

-- 被动技能ID计数器
local passiveSkillIdCounter = 0

-- 隐藏技能ID计数器
local hideSkillIdCounter = 0

-- 无消耗大招ID计数器
local noCostUltimateIdCounter = 0

--- 生成技能序列ID
---@return number 技能序列ID
local function GenerateSkillSeqId()
    skillSeqIdCounter = skillSeqIdCounter + 1
    return skillSeqIdCounter
end

--- 生成被动技能ID
---@return number 被动技能ID
local function GeneratePassiveSkillId()
    passiveSkillIdCounter = passiveSkillIdCounter + 1
    return passiveSkillIdCounter
end

--- 生成隐藏技能ID
---@return number 隐藏技能ID
local function GenerateHideSkillId()
    hideSkillIdCounter = hideSkillIdCounter + 1
    return hideSkillIdCounter
end

--- 生成无消耗大招ID
---@return number 无消耗大招ID
local function GenerateNoCostUltimateId()
    noCostUltimateIdCounter = noCostUltimateIdCounter + 1
    return noCostUltimateIdCounter
end

--- 获取英雄速度（用于排序）
---@param hero table 英雄对象
---@return number 英雄速度
local function GetHeroSpeed(hero)
    if not hero then
        return 0
    end
    -- 优先使用属性模块获取速度
    if hero.attributes and hero.attributes.speed then
        return hero.attributes.speed
    end
    -- 备用：直接从英雄数据获取
    return hero.speed or hero.Speed or 0
end

--- 初始化技能序列模块
function BattleSkillSeq.Init()
    -- 清空终极技能队列
    for i = #ultimateSkillQueue, 1, -1 do
        ultimateSkillQueue[i] = nil
    end
    
    -- 清空被动技能队列
    for heroId, _ in pairs(passiveSkillQueue) do
        passiveSkillQueue[heroId] = nil
    end
    
    -- 清空隐藏技能队列
    for i = #hideSkillQueue, 1, -1 do
        hideSkillQueue[i] = nil
    end
    
    -- 清空无消耗大招队列
    for i = #noCostUltimateQueue, 1, -1 do
        noCostUltimateQueue[i] = nil
    end
    
    skillSeqIdCounter = 0
    passiveSkillIdCounter = 0
    hideSkillIdCounter = 0
    noCostUltimateIdCounter = 0
    
    Logger.Debug("BattleSkillSeq.Init() - 技能序列模块已初始化")
end

--- 清理技能序列模块
function BattleSkillSeq.OnFinal()
    -- 清空终极技能队列
    for i = #ultimateSkillQueue, 1, -1 do
        ultimateSkillQueue[i] = nil
    end
    
    -- 清空被动技能队列
    for heroId, _ in pairs(passiveSkillQueue) do
        passiveSkillQueue[heroId] = nil
    end
    
    -- 清空隐藏技能队列
    for i = #hideSkillQueue, 1, -1 do
        hideSkillQueue[i] = nil
    end
    
    -- 清空无消耗大招队列
    for i = #noCostUltimateQueue, 1, -1 do
        noCostUltimateQueue[i] = nil
    end
    
    skillSeqIdCounter = 0
    passiveSkillIdCounter = 0
    hideSkillIdCounter = 0
    noCostUltimateIdCounter = 0
    
    Logger.Debug("BattleSkillSeq.OnFinal() - 技能序列模块已清理")
end

--- 添加终极技能到队列
---@param hero table 英雄对象
---@param skill table 技能对象
---@return boolean 是否添加成功
function BattleSkillSeq.AddUltimateSkill(hero, skill)
    if not hero then
        Logger.Error("[BattleSkillSeq.AddUltimateSkill] hero is nil")
        return false
    end
    
    if not skill then
        Logger.Error("[BattleSkillSeq.AddUltimateSkill] skill is nil")
        return false
    end
    
    -- 检查英雄是否已死亡
    if hero.isDead or not hero.isAlive then
        Logger.LogWarning("[BattleSkillSeq.AddUltimateSkill] Hero is dead, cannot add ultimate skill: " .. tostring(hero.name))
        return false
    end
    
    -- 检查技能是否为终极技能
    if skill.skillType ~= E_SKILL_TYPE_ULTIMATE then
        Logger.LogWarning("[BattleSkillSeq.AddUltimateSkill] Skill is not ultimate type: " .. tostring(skill.skillId))
        return false
    end
    
    -- 创建技能序列项
    local skillSeqItem = {
        id = GenerateSkillSeqId(),
        hero = hero,
        skill = skill,
        heroSpeed = GetHeroSpeed(hero),
        addTime = os.time(),
    }
    
    -- 插入队列并按速度排序（速度高的在前）
    table.insert(ultimateSkillQueue, skillSeqItem)
    
    -- 按速度降序排序（速度高的优先释放）
    table.sort(ultimateSkillQueue, function(a, b)
        if a.heroSpeed ~= b.heroSpeed then
            return a.heroSpeed > b.heroSpeed
        end
        -- 速度相同则按添加时间排序（先添加的先释放）
        return a.addTime < b.addTime
    end)
    
    Logger.Debug(string.format("[BattleSkillSeq.AddUltimateSkill] Added ultimate skill [%s] for hero [%s], speed=%d, queue size=%d",
        tostring(skill.name), tostring(hero.name), skillSeqItem.heroSpeed, #ultimateSkillQueue))
    
    return true
end

--- 获取序列中的下一个技能
---@return table|nil 技能序列项 {hero, skill, id, heroSpeed, addTime}
function BattleSkillSeq.GetSkillInSeq()
    -- 从队列头部获取技能
    while #ultimateSkillQueue > 0 do
        local skillSeqItem = ultimateSkillQueue[1]
        
        -- 检查英雄是否仍然存活
        if skillSeqItem.hero and not skillSeqItem.hero.isDead and skillSeqItem.hero.isAlive then
            -- 移除队列中的第一个元素
            table.remove(ultimateSkillQueue, 1)
            
            Logger.Debug(string.format("[BattleSkillSeq.GetSkillInSeq] Got skill [%s] for hero [%s], remaining queue size=%d",
                tostring(skillSeqItem.skill.name), tostring(skillSeqItem.hero.name), #ultimateSkillQueue))
            
            return skillSeqItem
        else
            -- 英雄已死亡，移除该技能
            Logger.LogWarning("[BattleSkillSeq.GetSkillInSeq] Hero is dead, removing skill from queue: " .. tostring(skillSeqItem.hero and skillSeqItem.hero.name))
            table.remove(ultimateSkillQueue, 1)
        end
    end
    
    return nil
end

--- 清除所有序列
function BattleSkillSeq.Clear()
    local count = #ultimateSkillQueue
    
    for i = #ultimateSkillQueue, 1, -1 do
        ultimateSkillQueue[i] = nil
    end
    
    Logger.Debug("[BattleSkillSeq.Clear] Cleared " .. count .. " skills from ultimate skill queue")
end

--- 检查序列中是否有技能
---@return boolean 是否有技能在序列中
function BattleSkillSeq.HasSkillInSeq()
    -- 清理已死亡英雄的技能
    for i = #ultimateSkillQueue, 1, -1 do
        local item = ultimateSkillQueue[i]
        if not item.hero or item.hero.isDead or not item.hero.isAlive then
            table.remove(ultimateSkillQueue, i)
        end
    end
    
    return #ultimateSkillQueue > 0
end

--- 获取终极技能队列数量
---@return number 队列中的技能数量
function BattleSkillSeq.GetUltimateSkillCount()
    return #ultimateSkillQueue
end

--- 获取被动技能队列
---@return table 被动技能队列 {hero, skill, buffSubType, funcName, id}
function BattleSkillSeq.GetPassiveSkillFunc()
    local result = {}
    
    for heroId, skillList in pairs(passiveSkillQueue) do
        for _, skillItem in ipairs(skillList) do
            table.insert(result, skillItem)
        end
    end
    
    -- 按添加顺序排序
    table.sort(result, function(a, b)
        return a.id < b.id
    end)
    
    Logger.Debug("[BattleSkillSeq.GetPassiveSkillFunc] Got " .. #result .. " passive skills")
    
    return result
end

--- 清除被动技能队列
function BattleSkillSeq.ClearPassiveSkillFunc()
    local count = 0
    
    for heroId, skillList in pairs(passiveSkillQueue) do
        count = count + #skillList
        passiveSkillQueue[heroId] = nil
    end
    
    Logger.Debug("[BattleSkillSeq.ClearPassiveSkillFunc] Cleared " .. count .. " passive skills")
end

--- 添加被动技能到队列
---@param hero table 英雄对象
---@param skill table 技能对象
---@param buffSubType number Buff子类型
---@param funcName string 回调函数名称
---@return boolean 是否添加成功
function BattleSkillSeq.InsertPassiveSkillFunc(hero, skill, buffSubType, funcName)
    if not hero then
        Logger.Error("[BattleSkillSeq.InsertPassiveSkillFunc] hero is nil")
        return false
    end
    
    if not skill then
        Logger.Error("[BattleSkillSeq.InsertPassiveSkillFunc] skill is nil")
        return false
    end
    
    if not funcName or funcName == "" then
        Logger.Error("[BattleSkillSeq.InsertPassiveSkillFunc] funcName is empty")
        return false
    end
    
    -- 检查英雄是否已死亡
    if hero.isDead or not hero.isAlive then
        Logger.LogWarning("[BattleSkillSeq.InsertPassiveSkillFunc] Hero is dead, cannot add passive skill: " .. tostring(hero.name))
        return false
    end
    
    local heroId = hero.id or hero.instanceId
    if not heroId then
        Logger.Error("[BattleSkillSeq.InsertPassiveSkillFunc] hero has no id")
        return false
    end
    
    -- 初始化该英雄的被动技能列表
    if not passiveSkillQueue[heroId] then
        passiveSkillQueue[heroId] = {}
    end
    
    -- 创建被动技能项
    local passiveSkillItem = {
        id = GeneratePassiveSkillId(),
        hero = hero,
        skill = skill,
        buffSubType = buffSubType or 0,
        funcName = funcName,
        addTime = os.time(),
    }
    
    table.insert(passiveSkillQueue[heroId], passiveSkillItem)
    
    Logger.Debug(string.format("[BattleSkillSeq.InsertPassiveSkillFunc] Added passive skill [%s] for hero [%s], func=%s, buffSubType=%d",
        tostring(skill.name), tostring(hero.name), funcName, buffSubType or 0))
    
    return true
end

--- 移除指定英雄的被动技能
---@param hero table 英雄对象
---@param skill table 技能对象（可选，不传则移除该英雄所有被动技能）
---@return number 移除的技能数量
function BattleSkillSeq.RemovePassiveSkillFunc(hero, skill)
    if not hero then
        return 0
    end
    
    local heroId = hero.id or hero.instanceId
    if not heroId then
        return 0
    end
    
    local skillList = passiveSkillQueue[heroId]
    if not skillList then
        return 0
    end
    
    local removedCount = 0
    
    if skill then
        -- 移除指定技能
        for i = #skillList, 1, -1 do
            if skillList[i].skill == skill or skillList[i].skill.skillId == skill.skillId then
                table.remove(skillList, i)
                removedCount = removedCount + 1
            end
        end
    else
        -- 移除该英雄所有被动技能
        removedCount = #skillList
        passiveSkillQueue[heroId] = nil
    end
    
    Logger.Debug(string.format("[BattleSkillSeq.RemovePassiveSkillFunc] Removed %d passive skills for hero [%s]",
        removedCount, tostring(hero.name)))
    
    return removedCount
end

--- 获取指定英雄的被动技能列表
---@param hero table 英雄对象
---@return table 被动技能列表
function BattleSkillSeq.GetHeroPassiveSkills(hero)
    if not hero then
        return {}
    end
    
    local heroId = hero.id or hero.instanceId
    if not heroId then
        return {}
    end
    
    return passiveSkillQueue[heroId] or {}
end

--- 检查指定英雄是否有被动技能
---@param hero table 英雄对象
---@return boolean 是否有被动技能
function BattleSkillSeq.HasHeroPassiveSkills(hero)
    local skills = BattleSkillSeq.GetHeroPassiveSkills(hero)
    return #skills > 0
end

--- 获取技能序列统计信息（用于调试）
---@return table 统计信息
function BattleSkillSeq.GetStats()
    local stats = {
        ultimateSkillCount = #ultimateSkillQueue,
        passiveSkillHeroCount = 0,
        totalPassiveSkillCount = 0,
        ultimateSkills = {},
        passiveSkills = {},
    }
    
    -- 统计终极技能
    for _, item in ipairs(ultimateSkillQueue) do
        table.insert(stats.ultimateSkills, {
            heroName = item.hero and item.hero.name,
            skillName = item.skill and item.skill.name,
            heroSpeed = item.heroSpeed,
        })
    end
    
    -- 统计被动技能
    for heroId, skillList in pairs(passiveSkillQueue) do
        stats.passiveSkillHeroCount = stats.passiveSkillHeroCount + 1
        stats.totalPassiveSkillCount = stats.totalPassiveSkillCount + #skillList
        
        for _, item in ipairs(skillList) do
            table.insert(stats.passiveSkills, {
                heroName = item.hero and item.hero.name,
                skillName = item.skill and item.skill.name,
                funcName = item.funcName,
                buffSubType = item.buffSubType,
            })
        end
    end
    
    return stats
end

--- 打印技能序列状态（调试用）
function BattleSkillSeq.Dump()
    Logger.Debug("========== BattleSkillSeq Dump ==========")
    
    Logger.Debug("--- Ultimate Skill Queue ---")
    for i, item in ipairs(ultimateSkillQueue) do
        Logger.Debug(string.format("  [%d] Hero: %s, Skill: %s, Speed: %d",
            i, tostring(item.hero and item.hero.name), tostring(item.skill and item.skill.name), item.heroSpeed))
    end
    
    Logger.Debug("--- Passive Skill Queue ---")
    for heroId, skillList in pairs(passiveSkillQueue) do
        Logger.Debug(string.format("  HeroID: %s, Count: %d", tostring(heroId), #skillList))
        for _, item in ipairs(skillList) do
            Logger.Debug(string.format("    - Skill: %s, Func: %s, BuffSubType: %d",
                tostring(item.skill and item.skill.name), item.funcName, item.buffSubType))
        end
    end
    
    Logger.Debug("=========================================")
end

-- ==================== 隐藏技能功能 ====================

--- 添加隐藏技能到队列
---@param heroSrc table 施法者英雄
---@param heroDest table 目标英雄（可为nil）
---@param skillId number 技能ID
---@return boolean 是否添加成功
function BattleSkillSeq.AddHideSkill(heroSrc, heroDest, skillId)
    if not heroSrc then
        Logger.Error("[BattleSkillSeq.AddHideSkill] heroSrc is nil")
        return false
    end
    
    if not skillId or skillId <= 0 then
        Logger.Error("[BattleSkillSeq.AddHideSkill] invalid skillId: " .. tostring(skillId))
        return false
    end
    
    -- 检查英雄是否已死亡
    if heroSrc.isDead or not heroSrc.isAlive then
        Logger.LogWarning("[BattleSkillSeq.AddHideSkill] Hero is dead, cannot add hide skill: " .. tostring(heroSrc.name))
        return false
    end
    
    -- 创建隐藏技能项
    local hideSkillItem = {
        id = GenerateHideSkillId(),
        heroSrc = heroSrc,
        heroDest = heroDest,
        skillId = skillId,
        addTime = os.time(),
    }
    
    table.insert(hideSkillQueue, hideSkillItem)
    
    Logger.Debug(string.format("[BattleSkillSeq.AddHideSkill] Added hide skill [%d] for hero [%s] -> [%s], queue size=%d",
        skillId, tostring(heroSrc.name), tostring(heroDest and heroDest.name or "nil"), #hideSkillQueue))
    
    return true
end

--- 获取下一个隐藏技能
---@return table|nil 隐藏技能项 {heroSrc, heroDest, skillId, id, addTime}
function BattleSkillSeq.GetHideSkillInSeq()
    while #hideSkillQueue > 0 do
        local hideSkillItem = hideSkillQueue[1]
        
        -- 检查施法者是否仍然存活
        if hideSkillItem.heroSrc and not hideSkillItem.heroSrc.isDead and hideSkillItem.heroSrc.isAlive then
            table.remove(hideSkillQueue, 1)
            
            Logger.Debug(string.format("[BattleSkillSeq.GetHideSkillInSeq] Got hide skill [%d] for hero [%s], remaining queue size=%d",
                hideSkillItem.skillId, tostring(hideSkillItem.heroSrc.name), #hideSkillQueue))
            
            return hideSkillItem
        else
            -- 施法者已死亡，移除该技能
            Logger.LogWarning("[BattleSkillSeq.GetHideSkillInSeq] Hero is dead, removing hide skill from queue")
            table.remove(hideSkillQueue, 1)
        end
    end
    
    return nil
end

--- 检查是否有隐藏技能在队列中
---@return boolean 是否有隐藏技能
function BattleSkillSeq.HasHideSkillInSeq()
    -- 清理已死亡英雄的技能
    for i = #hideSkillQueue, 1, -1 do
        local item = hideSkillQueue[i]
        if not item.heroSrc or item.heroSrc.isDead or not item.heroSrc.isAlive then
            table.remove(hideSkillQueue, i)
        end
    end
    
    return #hideSkillQueue > 0
end

--- 获取隐藏技能队列数量
---@return number 队列中的隐藏技能数量
function BattleSkillSeq.GetHideSkillCount()
    return #hideSkillQueue
end

-- ==================== 无消耗大招功能 ====================

--- 添加无消耗大招到队列
---@param heroSrc table 施法者英雄
---@param heroDest table 目标英雄（可为nil）
---@return boolean 是否添加成功
function BattleSkillSeq.AddUltimateSkillNoCost(heroSrc, heroDest)
    if not heroSrc then
        Logger.Error("[BattleSkillSeq.AddUltimateSkillNoCost] heroSrc is nil")
        return false
    end
    
    -- 检查英雄是否已死亡
    if heroSrc.isDead or not heroSrc.isAlive then
        Logger.LogWarning("[BattleSkillSeq.AddUltimateSkillNoCost] Hero is dead, cannot add no-cost ultimate: " .. tostring(heroSrc.name))
        return false
    end
    
    -- 获取英雄的终极技能
    local ultimateSkill = nil
    for _, skill in ipairs(heroSrc.skills or {}) do
        if skill.skillType == E_SKILL_TYPE_ULTIMATE then
            ultimateSkill = skill
            break
        end
    end
    
    if not ultimateSkill then
        Logger.LogWarning("[BattleSkillSeq.AddUltimateSkillNoCost] Hero has no ultimate skill: " .. tostring(heroSrc.name))
        return false
    end
    
    -- 创建无消耗大招项
    local noCostItem = {
        id = GenerateNoCostUltimateId(),
        heroSrc = heroSrc,
        heroDest = heroDest,
        skill = ultimateSkill,
        noCost = true,
        addTime = os.time(),
    }
    
    table.insert(noCostUltimateQueue, noCostItem)
    
    Logger.Debug(string.format("[BattleSkillSeq.AddUltimateSkillNoCost] Added no-cost ultimate [%s] for hero [%s], queue size=%d",
        tostring(ultimateSkill.name), tostring(heroSrc.name), #noCostUltimateQueue))
    
    return true
end

--- 获取下一个无消耗大招
---@return table|nil 无消耗大招项 {heroSrc, heroDest, skill, noCost, id, addTime}
function BattleSkillSeq.GetNoCostUltimateInSeq()
    while #noCostUltimateQueue > 0 do
        local noCostItem = noCostUltimateQueue[1]
        
        -- 检查施法者是否仍然存活
        if noCostItem.heroSrc and not noCostItem.heroSrc.isDead and noCostItem.heroSrc.isAlive then
            table.remove(noCostUltimateQueue, 1)
            
            Logger.Debug(string.format("[BattleSkillSeq.GetNoCostUltimateInSeq] Got no-cost ultimate [%s] for hero [%s], remaining queue size=%d",
                tostring(noCostItem.skill.name), tostring(noCostItem.heroSrc.name), #noCostUltimateQueue))
            
            return noCostItem
        else
            -- 施法者已死亡，移除该技能
            Logger.LogWarning("[BattleSkillSeq.GetNoCostUltimateInSeq] Hero is dead, removing no-cost ultimate from queue")
            table.remove(noCostUltimateQueue, 1)
        end
    end
    
    return nil
end

--- 检查是否有无消耗大招在队列中
---@return boolean 是否有无消耗大招
function BattleSkillSeq.HasNoCostUltimateInSeq()
    -- 清理已死亡英雄的技能
    for i = #noCostUltimateQueue, 1, -1 do
        local item = noCostUltimateQueue[i]
        if not item.heroSrc or item.heroSrc.isDead or not item.heroSrc.isAlive then
            table.remove(noCostUltimateQueue, i)
        end
    end
    
    return #noCostUltimateQueue > 0
end

--- 获取无消耗大招队列数量
---@return number 队列中的无消耗大招数量
function BattleSkillSeq.GetNoCostUltimateCount()
    return #noCostUltimateQueue
end

return BattleSkillSeq
