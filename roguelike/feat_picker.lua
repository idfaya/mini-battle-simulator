-- Roguelike Feat Picker
-- 实现"队伍升级三选一"会话：在 partyExp 跨阈值时根据存活队员的下一级 feat 候选并集
-- 抽取最多 3 张选项；玩家选中后给对应英雄 +1 级并写入 feat。
-- 设计文档：design/character_progression_design.md §3
local FeatBuildConfig = require("config.tables.feats")
local HeroData = require("config.hero_data")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local LevelCurve = require("config.roguelike.level_curve")

local FeatPicker = {}

local MAX_OPTIONS = 3
local SUBCLASS_CORE_WEIGHT = 1.5
local DEFAULT_WEIGHT = 1.0

local function cloneArray(input)
    local result = {}
    for i, v in ipairs(input or {}) do
        result[i] = v
    end
    return result
end

local function ownedFeatIds(unit)
    if type(unit) ~= "table" then
        return {}
    end
    if type(unit.buildState) == "table" and type(unit.buildState.featIds) == "table" then
        return cloneArray(unit.buildState.featIds)
    end
    return cloneArray(unit.feats or unit.selectedFeatIds)
end

local function isAliveActive(unit)
    if type(unit) ~= "table" then
        return false
    end
    if unit.isDead == true or unit.teamState == "dead" then
        return false
    end
    if unit.teamState ~= "active" then
        return false
    end
    return (tonumber(unit.currentHp) or 0) > 0
end

-- 树形规则候选过滤（design/roguelike_feat_skill_fill_sheet.md §3 / §4）：
--   Lv3 → 仅 trunk == "T1"
--   Lv5 → 仅 trunk == "T2"
--   Lv10 → 仅 isCapstone == true（且 Run 内未选过其它 capstone）
--   其它 → 排除 R/T1/T2/Capstone（仅 B / J 自由点）
--   prerequisites：默认至少一个父节点已点过；requireAllPrerequisites=true 时必须全部满足
-- §5 单轨 SSOT：无 fallback；筛出 0 项即视为该等级无可选项，由调用方继续向上跳级。
local function filterByTreeRules(options, level, ownedSet, runHasCapstone)
    if not options or #options == 0 then
        return options
    end
    local matched = {}
    for _, item in ipairs(options) do
        local feat = item.feat or {}
        local treeSlot = feat.treeSlot
        local trunk = feat.trunk
        local isCapstone = feat.isCapstone == true
        local pass = true
        if level == 3 then
            pass = (trunk == "T1") or (treeSlot == "T1")
        elseif level == 5 then
            pass = (trunk == "T2") or (treeSlot == "T2")
        elseif level == 10 then
            pass = isCapstone and (not runHasCapstone)
        else
            -- 自由点：排除主干 / capstone / 根节点
            if treeSlot == "T1" or treeSlot == "T2" or treeSlot == "R" or isCapstone then
                pass = false
            end
        end
        if pass and type(feat.prerequisites) == "table" and #feat.prerequisites > 0 then
            local satisfied = feat.requireAllPrerequisites == true
            for _, parentId in ipairs(feat.prerequisites) do
                local hasParent = ownedSet[tonumber(parentId) or 0] == true
                if feat.requireAllPrerequisites == true then
                    if not hasParent then
                        satisfied = false
                        break
                    end
                elseif hasParent then
                    satisfied = true
                    break
                end
            end
            pass = satisfied
        end
        if pass then
            matched[#matched + 1] = item
        end
    end
    return matched
end

local function runHasCapstoneSelected(state, classId)
    if type(state) ~= "table" then
        return false
    end
    local units = RoguelikeRoster.GetTeamUnits(state) or {}
    for _, unit in ipairs(units) do
        if tonumber(unit.classId) == tonumber(classId) then
            for _, fid in ipairs(ownedFeatIds(unit)) do
                local feat = FeatBuildConfig.GetFeat(fid)
                if feat and feat.isCapstone == true then
                    return true
                end
            end
        end
    end
    return false
end

-- 收集候选：对每名存活队员，列出"下一级"全部未选 feat。
-- 若该等级无任何候选（典型：阶段 1 / 阶段 7 缺口职业 Lv2/Lv4 没有 feat），
-- 则按"跳级"机制（设计 §3.1 允许跳级）向上找最近一个有 feat 的等级，但不超过 partyLevel + 1。
-- 设计 §3：每次三选一只升 1 个英雄；hero.level 上限 = partyLevel。
-- 返回 { heroes = [{unit, nextLevel, options=[{featId, feat}]}], levelCap }
local function gatherCandidates(state)
    local levelCap = tonumber(state and state.levelCap) or 10
    local result = {}
    for _, unit in ipairs(RoguelikeRoster.GetTeamUnits(state) or {}) do
        if isAliveActive(unit) then
            local currentLevel = tonumber(unit.level) or 1
            local owned = {}
            for _, featId in ipairs(ownedFeatIds(unit)) do
                owned[tonumber(featId) or 0] = true
            end
            local classId = tonumber(unit.classId) or 0
            local hasCapstone = runHasCapstoneSelected(state, classId)
            -- 设计 §3：每次三选一只升 1 个英雄，hero.level += 1。
            -- 仅当 currentLevel+1 没有 feat 时，才向上"跳过空白级"找最近一个有 feat 的等级；
            -- searchCap = levelCap，与 partyLevel 解耦（partyLevel 在新模型里是累计升级次数，
            -- 不再约束单次 pick 的 nextLevel）。
            local searchCap = levelCap
            local foundLevel = nil
            local foundOptions = nil
            for nextLevel = currentLevel + 1, searchCap do
                local options = {}
                for _, feat in ipairs(FeatBuildConfig.GetFeatsByLevel(classId, nextLevel) or {}) do
                    local featId = tonumber(feat.id) or 0
                    if featId > 0 and not owned[featId] then
                        options[#options + 1] = { featId = featId, feat = feat }
                    end
                end
                -- 应用 §5 单轨树形规则（无 fallback；筛出 0 即跳级继续往上找）。
                options = filterByTreeRules(options, nextLevel, owned, hasCapstone)
                if #options > 0 then
                    foundLevel = nextLevel
                    foundOptions = options
                    break
                end
            end
            if foundOptions then
                result[#result + 1] = {
                    unit = unit,
                    rosterId = tonumber(unit.rosterId) or 0,
                    nextLevel = foundLevel,
                    classId = classId,
                    options = foundOptions,
                }
            end
        end
    end
    return result
end

-- 同 choiceGroup 已用过滤：从一个英雄的可选列表里移除指定 choiceGroup。
local function filterChoiceGroup(heroEntry, usedGroups)
    if not usedGroups or next(usedGroups) == nil then
        return heroEntry.options
    end
    local kept = {}
    for _, item in ipairs(heroEntry.options or {}) do
        local group = item.feat and item.feat.choiceGroup
        if not group or not usedGroups[group] then
            kept[#kept + 1] = item
        end
    end
    return kept
end

local function weightOf(item)
    if not item or not item.feat then
        return DEFAULT_WEIGHT
    end
    if item.feat.tier == "medium" and item.feat.isSubclassCore == true then
        return SUBCLASS_CORE_WEIGHT
    end
    return DEFAULT_WEIGHT
end

-- 加权抽 1 项；返回选中 item 与 index。
local function weightedPick(items)
    if not items or #items == 0 then
        return nil, nil
    end
    local total = 0.0
    for _, item in ipairs(items) do
        total = total + weightOf(item)
    end
    if total <= 0 then
        local idx = math.random(1, #items)
        return items[idx], idx
    end
    local roll = math.random() * total
    local accum = 0
    for index, item in ipairs(items) do
        accum = accum + weightOf(item)
        if roll <= accum then
            return item, index
        end
    end
    return items[#items], #items
end

local function shuffleArray(list)
    for i = #list, 2, -1 do
        local j = math.random(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

local function buildOptionPayload(unit, item, targetLevel)
    local feat = item.feat
    -- targetLevel 来自 entry.nextLevel；跳级时（如 Lv1 → Lv3）值会大于 unit.level + 1。
    local resolvedLevel = tonumber(targetLevel) or ((tonumber(unit.level) or 1) + 1)
    return {
        featId = item.featId,
        heroId = tonumber(unit.heroId) or 0,
        rosterId = tonumber(unit.rosterId) or 0,
        heroName = unit.name or "",
        classId = tonumber(unit.classId) or 0,
        level = resolvedLevel,
        tier = feat and feat.tier or "small",
        isSubclassCore = feat and feat.isSubclassCore == true or false,
        featName = feat and feat.name or "",
        featDescription = feat and feat.description or "",
        choiceGroup = feat and feat.choiceGroup or nil,
    }
end

-- 候选生成：保底每个存活英雄至少 1 张候选进池，再随机补满到 MAX_OPTIONS。
-- 同 choiceGroup 已用项过滤。返回一份 options 数组。
-- 当存活英雄 > MAX_OPTIONS 时，扩展候选上限到 #heroEntries，
-- 严格满足设计 §3.1 / §9 "保底每个存活英雄至少 1 张候选进池"。
local function buildOptions(heroEntries)
    local options = {}
    local usedGroups = {}
    -- 这里 shuffle 一份副本进入 pass1，让 multi-session 视角下每个英雄都有公平机会。
    local shuffledEntries = {}
    for _, entry in ipairs(heroEntries) do
        shuffledEntries[#shuffledEntries + 1] = entry
    end
    shuffleArray(shuffledEntries)
    -- 实际上限：默认 3，但若存活英雄 > 3，则扩展到英雄数（保底每人 1 张）。
    local optionCap = math.max(MAX_OPTIONS, #shuffledEntries)
    -- pass1：每个英雄保底 1 张
    local remainder = {}
    for _, entry in ipairs(shuffledEntries) do
        local pool = filterChoiceGroup(entry, usedGroups)
        if #pool > 0 then
            local picked, idx = weightedPick(pool)
            if picked then
                options[#options + 1] = buildOptionPayload(entry.unit, picked, entry.nextLevel)
                if picked.feat and picked.feat.choiceGroup then
                    usedGroups[picked.feat.choiceGroup] = true
                end
                -- 从 pool 中移除已选项；剩余项进入 remainder（下一轮可补位）
                local rest = {}
                for index, item in ipairs(pool) do
                    if index ~= idx then
                        rest[#rest + 1] = { entry = entry, item = item }
                    end
                end
                for _, leftover in ipairs(rest) do
                    remainder[#remainder + 1] = leftover
                end
            end
        end
        if #options >= optionCap then
            break
        end
    end

    -- pass2：保底未满 optionCap 时，从剩余池里加权抽（同 choiceGroup 过滤）
    while #options < optionCap do
        local candidates = {}
        for _, entry in ipairs(remainder) do
            local group = entry.item and entry.item.feat and entry.item.feat.choiceGroup
            if not group or not usedGroups[group] then
                candidates[#candidates + 1] = entry
            end
        end
        if #candidates == 0 then
            break
        end
        local items = {}
        for _, c in ipairs(candidates) do
            items[#items + 1] = c.item
        end
        local picked, idx = weightedPick(items)
        if not picked then
            break
        end
        local chosenEntry = candidates[idx]
        options[#options + 1] = buildOptionPayload(chosenEntry.entry.unit, chosenEntry.item, chosenEntry.entry.nextLevel)
        if picked.feat and picked.feat.choiceGroup then
            usedGroups[picked.feat.choiceGroup] = true
        end
        -- 从 remainder 移除被选中的具体项
        local newRemainder = {}
        for _, e in ipairs(remainder) do
            if e ~= chosenEntry then
                newRemainder[#newRemainder + 1] = e
            end
        end
        remainder = newRemainder
    end

    shuffleArray(options)
    return options
end

-- 计算队伍当前应处的等级（按 partyExp 跨阈值，统一走 LevelCurve）。
local function computePartyLevel(state, _heroLevelCap)
    local exp = math.max(0, math.floor(tonumber(state and state.partyExp) or 0))
    return LevelCurve.GetLevelForExp(exp, LevelCurve.CHAPTER_LEVEL_CAP)
end

--- 检查并启动一次升级会话（partyExp 跨阈值时调用）
--- 调用前应已经把战斗经验累加到 state.partyExp。
--- 设计 §3 语义：partyLevel 每升 1 级 = 1 次三选一 = 升 1 个英雄；
---   候选池 = 所有存活队员"下一个等级"可选 feat 的并集；玩家选中即给该英雄 +1 级。
---   pendingLevels = newPartyLevel - oldPartyLevel（队伍升级次数，与队员人数无关）。
---   partyLevel 在新模型里语义 ≈ "全队累计三选一次数"，而不是"角色平均等级"。
--- @param state any
--- @param thresholds table<integer, integer>|nil  保留参数兼容旧调用，新实现统一走 LevelCurve
--- @return table|nil session  session 即新的 rewardState（kind="feat_levelup"）
function FeatPicker.BeginSession(state, thresholds)
    if type(state) ~= "table" then
        return nil
    end
    -- thresholds 参数已废弃但保留签名兼容；曲线统一从 LevelCurve 读取
    local _ = thresholds
    local levelCap = tonumber(state.levelCap) or LevelCurve.CHAPTER_LEVEL_CAP
    local oldPartyLevel = tonumber(state.partyLevel) or (LevelCurve.STARTER_LEVEL or 1)
    local newPartyLevel = computePartyLevel(state, levelCap)
    state.partyLevel = newPartyLevel

    local newOwed = (tonumber(state.partyLevelOwed) or 0) + math.max(0, newPartyLevel - oldPartyLevel)
    state.partyLevelOwed = newOwed
    if newOwed <= 0 then
        return nil
    end

    local entries = gatherCandidates(state)
    if #entries == 0 then
        return nil
    end
    local options = buildOptions(entries)
    if #options == 0 then
        return nil
    end

    local session = {
        kind = "feat_levelup",
        groupId = 0,
        options = options,
        pendingLevels = newOwed,
    }
    state.featPickerSession = session
    state.rewardState = session
    return session
end

-- 玩家选中候选项 index（1-based）。
-- 副作用：
--   1) 根据 option.rosterId 找到对应英雄；
--   2) 该英雄 level += 1；
--   3) 把 featId 追加到 unit.feats（避免重复）；
--   4) 用 HeroData.RefreshClassUnit 重建战斗属性（保留 currentHp、状态）。
-- 返回 { picked, sessionExhausted, nextSession }
function FeatPicker.Pick(state, optionIndex)
    if type(state) ~= "table" then
        return false, "no_state"
    end
    local session = state.featPickerSession
    if not session or session.kind ~= "feat_levelup" then
        return false, "no_session"
    end
    local options = session.options or {}
    local idx = tonumber(optionIndex) or 0
    local option = options[idx]
    if not option then
        return false, "invalid_option"
    end

    -- 找到目标英雄
    local target = nil
    for _, unit in ipairs(RoguelikeRoster.GetTeamUnits(state) or {}) do
        if tonumber(unit.rosterId) == tonumber(option.rosterId) then
            target = unit
            break
        end
    end
    if not target then
        return false, "hero_not_found"
    end

    -- 追加 featId 到 unit.feats（去重）
    target.feats = target.feats or {}
    local seen = {}
    for _, fid in ipairs(target.feats) do
        seen[tonumber(fid) or 0] = true
    end
    if not seen[tonumber(option.featId) or 0] then
        target.feats[#target.feats + 1] = option.featId
    end

    -- 设计 §3：每次三选一只升 1 个英雄、严格 +1 级。
    -- option.level 来自跳级搜索结果（≥ oldLevel+1），仅用于在 UI/feat 资源解锁判定上选取
    -- 该 feat 的合法等级；hero 实际 level 严格 += 1，避免单次 pick 跨多级。
    local oldLevel = tonumber(target.level) or 1
    local newLevel = oldLevel + 1
    local oldCurrentHp = tonumber(target.currentHp) or 0
    local oldMaxHp = tonumber(target.maxHp) or 0
    local oldUltCharges = tonumber(target.ultimateCharges) or 1
    local oldUltMax = tonumber(target.ultimateChargesMax) or 1
    local oldCooldowns = target.skillCooldowns or {}
    HeroData.RefreshClassUnit(target, {
        level = newLevel,
        promotionStage = target.promotionStage,
        teamState = target.teamState,
        currentHp = oldCurrentHp,
        isDead = target.isDead,
        ultimateCharges = oldUltCharges,
        ultimateChargesMax = oldUltMax,
        skillCooldowns = oldCooldowns,
        source = target.source,
    })
    -- 把 feat 重新写回（RefreshClassUnit 会基于 canonical feats 重建，这里追加自定义 feat）
    target.feats = target.feats or {}
    if not seen[tonumber(option.featId) or 0] then
        local exists = false
        for _, fid in ipairs(target.feats) do
            if tonumber(fid) == tonumber(option.featId) then
                exists = true
                break
            end
        end
        if not exists then
            target.feats[#target.feats + 1] = option.featId
        end
    end
    -- 同步 currentHp 增长（按 maxHp 提升量）
    if not (target.isDead == true) then
        local newMaxHp = tonumber(target.maxHp) or oldMaxHp
        local deltaHp = math.max(0, newMaxHp - oldMaxHp)
        target.currentHp = math.max(1, math.min(newMaxHp, oldCurrentHp + deltaHp))
        target.hp = target.currentHp
    end

    -- 当前 session 消费一次 pendingLevels；同步扣减 state.partyLevelOwed（持久化欠债）。
    session.pendingLevels = math.max(0, (tonumber(session.pendingLevels) or 1) - 1)
    state.partyLevelOwed = math.max(0, (tonumber(state.partyLevelOwed) or 0) - 1)
    state.featPickerSession = nil
    state.rewardState = nil

    local result = {
        picked = {
            heroId = option.heroId,
            rosterId = option.rosterId,
            featId = option.featId,
            newLevel = newLevel,
            heroName = option.heroName,
            tier = option.tier,
            isSubclassCore = option.isSubclassCore,
        },
        sessionExhausted = session.pendingLevels <= 0,
    }

    -- 若仍有 pending 升级，启动下一轮（沿用旧 thresholds 不需要——这里直接基于存活队伍补一次）
    if session.pendingLevels > 0 then
        local entries = gatherCandidates(state)
        if #entries > 0 then
            local nextOptions = buildOptions(entries)
            if #nextOptions > 0 then
                local nextSession = {
                    kind = "feat_levelup",
                    groupId = 0,
                    options = nextOptions,
                    pendingLevels = session.pendingLevels,
                }
                state.featPickerSession = nextSession
                state.rewardState = nextSession
                result.nextSession = nextSession
            end
        end
    end

    return true, result
end

-- 测试 / 工具：返回当前 session（可能为 nil）
function FeatPicker.GetSession(state)
    return state and state.featPickerSession or nil
end

-- 测试专用：暴露内部加权抽样函数，便于单测验证 ×1.5 权重分布。
function FeatPicker._weightedPickForTest(items)
    return weightedPick(items)
end

-- 测试专用：暴露树形规则过滤函数。
function FeatPicker._filterByTreeRulesForTest(options, level, ownedSet, runHasCapstone)
    return filterByTreeRules(options, level, ownedSet or {}, runHasCapstone == true)
end

return FeatPicker
