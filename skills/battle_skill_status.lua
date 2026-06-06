---
--- Battle Skill Status Module
--- 集中管理技能引发的状态效果：中毒、燃烧、流血、减速、冻结、静电印记、感染加深
---
--- 从 modules/battle_skill.lua [10] 区拆出（2026-04-27），后迁移到 skills/ 目录。
--- 仍复用 battle_skill.ApplyBuffFromSkill 作为 buff 挂载入口，以保持现有 buff 生命周期一致。
---
--- 外部契约：battle_skill.lua 会保留 BattleSkill.ApplyPoison/ApplyBurn/ApplyFreeze/ProcessInfectEffect
--- 作为转发接口，monkey-patch 仍然有效（见 bin/test_timeline_passive.lua）。
---

local Logger = require("utils.logger")

local BattleSkillStatus = {}

-- 懒引用 BattleSkill 以避免与 battle_skill.lua 形成加载期循环依赖。
local function GetBattleSkill()
    return require("modules.battle_skill")
end

-- §6 dotDurationDelta：caster 的 classMod 可全局延长 DoT/状态持续时间。
local function getDotDurationDelta(caster)
    if not caster then
        return 0
    end
    local buildState = caster.buildState
    if type(buildState) ~= "table" then
        return 0
    end
    local classMods = buildState.classMods
    local delta = 0
    if type(classMods) == "table" then
        delta = math.max(0, math.floor(tonumber(classMods.dotDurationDelta) or 0))
    end
    return delta
end

local function getSkillDurationDelta(caster, skillId)
    if not caster or not skillId then
        return 0
    end
    local buildState = caster.buildState
    if type(buildState) ~= "table" or type(buildState.skillMods) ~= "table" then
        return 0
    end
    local entry = buildState.skillMods[tonumber(skillId)]
    if type(entry) ~= "table" then
        return 0
    end
    return math.max(0, math.floor(tonumber(entry.dotDurationDelta) or 0))
end

local function getBurnDurationDelta(caster)
    return getDotDurationDelta(caster) + getSkillDurationDelta(caster, 80007002)
end

local function getSlowDurationDelta(caster)
    return getDotDurationDelta(caster) + getSkillDurationDelta(caster, 80008002)
end

local function getFrostDurationDelta(caster)
    return getSlowDurationDelta(caster)
end

local function initBurnSaveType(buff)
    if not buff then
        return
    end
    buff.__burnSaveType = "ref"
end

--- 处理中毒效果（T1 毒爆流）
---@param target table 目标
---@param layers number 中毒层数
---@param caster table|nil 施法者（决定 buff 归属，感染时为 target 自身）
function BattleSkillStatus.ApplyPoison(target, layers, caster)
    if not target or layers <= 0 then return end

    local BattleBuff = require("modules.battle_buff")
    local existingBuff = BattleBuff.GetBuff(target, 850001)
    if existingBuff then
        BattleBuff.ModifyBuffStack(target, 850001, layers)
        Logger.Log(string.format("[ApplyPoison] %s 中毒层数: %d (总计: %d)",
            target.name or "Unknown", layers, existingBuff.stackCount))
        return
    end

    GetBattleSkill().ApplyBuffFromSkill(caster or target, target, 850001, nil, {
        initialStack = layers,
    })
    local totalStacks = BattleBuff.GetBuffStackNumBySubType(target, 850001)
    Logger.Log(string.format("[ApplyPoison] %s 中毒层数: %d (总计: %d)",
        target.name or "Unknown", layers, totalStacks))
end

--- 处理感染效果（中毒自动加深）
--- 仅在 target 已带毒时叠一层，确保逻辑等价于旧实现。
---@param target table 目标
function BattleSkillStatus.ProcessInfectEffect(target)
    local BattleBuff = require("modules.battle_buff")
    if not target or BattleBuff.GetBuffStackNumBySubType(target, 850001) <= 0 then return end

    -- 通过 BattleSkill.ApplyPoison 走转发路径，保持 monkey-patch 兼容。
    GetBattleSkill().ApplyPoison(target, 1, target)
    Logger.Log(string.format("[ProcessInfectEffect] %s 中毒加深，当前层数: %d",
        target.name or "Unknown", BattleBuff.GetBuffStackNumBySubType(target, 850001)))
end

--- 施加燃烧（DoT，只刷新持续时间；若施法者带 870002 则延长 1 回合）
---@param target table
---@param stacks number 新增层数
---@param turns number|nil 持续回合
---@param caster table|nil
function BattleSkillStatus.ApplyBurn(target, stacks, turns, caster)
    if not target or stacks <= 0 then
        return
    end
    local BattleBuff = require("modules.battle_buff")
    local actualTurns = turns or 2
    if caster and BattleBuff.GetBuff(caster, 870002) then
        actualTurns = actualTurns + 1
    end
    actualTurns = actualTurns + getBurnDurationDelta(caster)
    local existingBuff = BattleBuff.GetBuff(target, 870001)
    if existingBuff then
        existingBuff.duration = math.max(existingBuff.duration or 0, actualTurns)
        initBurnSaveType(existingBuff)
    else
        GetBattleSkill().ApplyBuffFromSkill(caster or target, target, 870001, nil, {
            initialStack = 1,
            duration = actualTurns,
        })
        initBurnSaveType(BattleBuff.GetBuff(target, 870001))
    end
    Logger.Log(string.format("[ApplyBurn] %s 燃烧刷新到 %d 回合 (总计层数: %d)",
        target.name or "Unknown", actualTurns, BattleBuff.GetBuffStackNumBySubType(target, 870001)))
end

--- 施加燃烧，但已燃烧目标只刷新持续时间，不叠加层数。
---@param target table
---@param turns number|nil
---@param caster table|nil
function BattleSkillStatus.ApplyBurnRefreshOnly(target, turns, caster)
    if not target then
        return
    end
    local BattleBuff = require("modules.battle_buff")
    local actualTurns = turns or 2
    if caster and BattleBuff.GetBuff(caster, 870002) then
        actualTurns = actualTurns + 1
    end
    actualTurns = actualTurns + getBurnDurationDelta(caster)
    local existingBuff = BattleBuff.GetBuff(target, 870001)
    if existingBuff then
        existingBuff.duration = math.max(existingBuff.duration or 0, actualTurns)
        initBurnSaveType(existingBuff)
    else
        GetBattleSkill().ApplyBuffFromSkill(caster or target, target, 870001, nil, {
            initialStack = 1,
            duration = actualTurns,
        })
        initBurnSaveType(BattleBuff.GetBuff(target, 870001))
    end
    Logger.Log(string.format("[ApplyBurnRefreshOnly] %s 燃烧刷新到 %d 回合",
        target.name or "Unknown", actualTurns))
end

--- 施加减速（降先攻；重复施加只刷新持续）
---@param target table
---@param turns number|nil
---@param caster table|nil
---@param initiativePenalty number|nil 先攻降低量，默认 5
function BattleSkillStatus.ApplySlow(target, turns, caster, initiativePenalty)
    if not target then
        return
    end
    local BattleBuff = require("modules.battle_buff")
    local actualTurns = (turns or 2) + getSlowDurationDelta(caster)
    local penalty = math.max(1, math.floor(tonumber(initiativePenalty) or 5))
    local existingBuff = BattleBuff.GetBuff(target, 880001)
    if existingBuff then
        existingBuff.duration = math.max(existingBuff.duration or 0, actualTurns)
        existingBuff.value = penalty
    else
        GetBattleSkill().ApplyBuffFromSkill(caster or target, target, 880001, nil, {
            duration = actualTurns,
            value = penalty,
        })
    end
    Logger.Log(string.format("[ApplySlow] %s 减速回合: %d 先攻-%d",
        target.name or "Unknown", actualTurns, penalty))
end

--- 施加冻结（可选附带减速）
---@param target table
---@param turns number|nil 硬控冻结回合（880002）
---@param slowPenalty number|nil 先攻降低量（880001），<=0 则不施加减速
---@param caster table|nil
function BattleSkillStatus.ApplyFreeze(target, turns, slowPenalty, caster)
    if not target then
        return
    end
    local BattleSkill = GetBattleSkill()
    local delta = getDotDurationDelta(caster)
    if slowPenalty and slowPenalty > 0 then
        local penalty = slowPenalty > 20 and slowPenalty or 5
        BattleSkillStatus.ApplySlow(target, math.max(turns or 0, 2) + delta, caster, penalty)
    end
    if turns and turns > 0 then
        BattleSkill.ApplyBuffFromSkill(caster or target, target, 880002, nil, {
            duration = turns + delta,
        })
    end
    Logger.Log(string.format("[ApplyFreeze] %s 冻结回合: %d 减速先攻: %s",
        target.name or "Unknown", (turns or 0) + delta, tostring(slowPenalty or 0)))
end

---@deprecated 兼容旧调用；等价于 ApplySlow
function BattleSkillStatus.ApplyFrost(target, turns, caster)
    return BattleSkillStatus.ApplySlow(target, turns, caster)
end

--- 施加流血（体豁 DoT；只刷新持续，不叠层）
---@param target table
---@param turns number|nil
---@param caster table|nil
function BattleSkillStatus.ApplyBleed(target, turns, caster)
    if not target then
        return
    end
    local BattleBuff = require("modules.battle_buff")
    local actualTurns = turns or 2
    local existingBuff = BattleBuff.GetBuff(target, 880007)
    if existingBuff then
        existingBuff.duration = math.max(existingBuff.duration or 0, actualTurns)
    else
        GetBattleSkill().ApplyBuffFromSkill(caster or target, target, 880007, nil, {
            initialStack = 1,
            duration = actualTurns,
        })
    end
    Logger.Log(string.format("[ApplyBleed] %s 流血刷新到 %d 回合",
        target.name or "Unknown", actualTurns))
end

---@param target table
---@param turns number|nil
---@param caster table|nil
function BattleSkillStatus.ApplyStaticMark(target, turns, caster)
    if not target then
        return
    end
    local actualTurns = (turns or 2) + getDotDurationDelta(caster)
    GetBattleSkill().ApplyBuffFromSkill(caster or target, target, 890001, nil, {
        duration = actualTurns,
    })
end

---@param target table
---@return boolean
function BattleSkillStatus.HasStaticMark(target)
    local BattleBuff = require("modules.battle_buff")
    return BattleBuff.GetBuff(target, 890001) ~= nil
end

---@param target table
---@return boolean
function BattleSkillStatus.HasSlow(target)
    local BattleBuff = require("modules.battle_buff")
    return BattleBuff.GetBuff(target, 880001) ~= nil
end

---@param target table
---@return boolean
function BattleSkillStatus.HasFrost(target)
    return BattleSkillStatus.HasSlow(target)
end

return BattleSkillStatus
