local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RunNodePool = require("config.roguelike.run_node_pool")
local RunShopGoods = require("config.roguelike.run_shop_goods")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local BattleFormation = require("modules.battle_formation")
local HeroData = require("config.hero_data")

--[[
平衡测试工具

用法:
  lua55 bin/test_roguelike_balance.lua
  lua55 bin/test_roguelike_balance.lua --route=all --runs=10
  lua55 bin/test_roguelike_balance.lua --route=safe --runs=20 --seed=101
  lua55 bin/test_roguelike_balance.lua --nodes=101001,101003,101005,101007,101009,101010,101011
  lua55 bin/test_roguelike_balance.lua --shop=leave --verbose

默认策略:
  - 路线: chapter101 的 safe + combat
  - 奖励: recruit > equipment > blessing > gold
    - 商店: basic（优先买装备/治疗/祝福）
  - 营地: 优先 blessing，其次复活
  - 事件: 选 optionId=1
  - 候补: 队伍未满时自动上阵
]]

local ROUTE_PRESETS = {
    [101] = {
        safe = {
            "battle_normal", "recruit", "battle_normal", "camp", "battle_normal", "battle_normal", "recruit", "boss",
        },
        combat = {
            "battle_normal", "battle_normal", "battle_elite", "battle_normal", "battle_elite", "battle_normal", "recruit", "boss",
        },
    },
}

local DEFAULT_CONFIG = {
    chapterId = 101,
    route = "all",
    runs = 10,
    seed = 101,
    tickMs = 800,
    maxBattleTicks = 1200,
    verbose = false,
    shopPolicy = "basic",
    autoUltimate = true,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
}

local REWARD_PRIORITY = {
    recruit = 1,
    equipment = 2,
    blessing = 3,
    gold = 4,
}

local SHOP_PRIORITY = {
    equipment = 1,
    service_heal = 2,
    blessing = 4,
    service_other = 5,
}

local function split(str, sep)
    local result = {}
    if not str or str == "" then
        return result
    end
    for token in string.gmatch(str, "([^" .. sep .. "]+)") do
        result[#result + 1] = token
    end
    return result
end

local function parseIntCsv(value)
    local result = {}
    for _, token in ipairs(split(value or "", ",")) do
        local number = tonumber(token)
        if number then
            result[#result + 1] = math.floor(number)
        end
    end
    return result
end

local function round(value)
    return math.floor((value or 0) + 0.5)
end

local function formatPct(numerator, denominator)
    if not denominator or denominator <= 0 then
        return "0.0%"
    end
    return string.format("%.1f%%", (numerator / denominator) * 100)
end

local function formatNumber(value)
    return string.format("%.1f", tonumber(value) or 0)
end

local function getMissingHp(currentHp, maxHp)
    return math.max(0, (tonumber(maxHp) or 0) - (tonumber(currentHp) or 0))
end

-- #region debug-point A:debug-server-reporting
local DEBUG_SESSION_FILE = ".dbg/frozen-gate-zero-loss.env"
local DEBUG_LOCAL_LOG = ".dbg/trae-debug-log-frozen-gate-zero-loss.ndjson"
local debugServerConfig = nil

local function jsonEscape(value)
    local str = tostring(value or "")
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\"", "\\\"")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\n", "\\n")
    str = str:gsub("\t", "\\t")
    return str
end

local function isArrayTable(value)
    if type(value) ~= "table" then
        return false
    end
    local index = 1
    for key, _ in pairs(value) do
        if key ~= index then
            return false
        end
        index = index + 1
    end
    return true
end

local function encodeJson(value)
    local valueType = type(value)
    if valueType == "nil" then
        return "null"
    end
    if valueType == "number" then
        if value ~= value then
            return "0"
        end
        return tostring(value)
    end
    if valueType == "boolean" then
        return value and "true" or "false"
    end
    if valueType == "string" then
        return "\"" .. jsonEscape(value) .. "\""
    end
    if valueType ~= "table" then
        return "\"" .. jsonEscape(tostring(value)) .. "\""
    end

    if isArrayTable(value) then
        local items = {}
        for _, item in ipairs(value) do
            items[#items + 1] = encodeJson(item)
        end
        return "[" .. table.concat(items, ",") .. "]"
    end

    local items = {}
    for key, item in pairs(value) do
        items[#items + 1] = "\"" .. jsonEscape(tostring(key)) .. "\":" .. encodeJson(item)
    end
    table.sort(items)
    return "{" .. table.concat(items, ",") .. "}"
end

local function readDebugServerConfig()
    if debugServerConfig ~= nil then
        return debugServerConfig
    end
    debugServerConfig = {
        url = "",
        sessionId = "frozen-gate-zero-loss",
    }
    local file = io.open(DEBUG_SESSION_FILE, "r")
    if not file then
        return debugServerConfig
    end
    local content = file:read("*a") or ""
    file:close()
    local enabled = content:match("DEBUG_SERVER_ENABLED=([^\r\n]+)")
    local url = content:match("DEBUG_SERVER_URL=([^\r\n]+)")
    local sessionId = content:match("DEBUG_SESSION_ID=([^\r\n]+)")
    if enabled == "1" and url and url ~= "" then
        debugServerConfig.url = url
    end
    if sessionId and sessionId ~= "" then
        debugServerConfig.sessionId = sessionId
    end
    return debugServerConfig
end

local function reportDebugEvent(runId, hypothesisId, location, msg, data)
    local cfg = readDebugServerConfig()
    local payload = {
        sessionId = cfg.sessionId,
        runId = runId or "pre",
        hypothesisId = hypothesisId or "A",
        location = location or "bin/test_roguelike_balance.lua",
        msg = msg or "[DEBUG] event",
        data = data or {},
        ts = math.floor((os.time() or 0) * 1000),
    }
    local body = encodeJson(payload)
    local logFile = io.open(DEBUG_LOCAL_LOG, "a")
    if logFile then
        logFile:write(body)
        logFile:write("\n")
        logFile:close()
    end
    if not cfg or not cfg.url or cfg.url == "" then
        return
    end
    local tmpPath = string.format(
        ".dbg/frozen-gate-zero-loss-%s-%s-%d.json",
        tostring(runId or "pre"):gsub("[^%w%-_]", "_"),
        tostring(hypothesisId or "A"):gsub("[^%w%-_]", "_"),
        math.floor((os.clock() or 0) * 1000000)
    )
    local file = io.open(tmpPath, "w")
    if not file then
        return
    end
    file:write(body)
    file:close()
    local normalizedPath = tmpPath:gsub("/", "\\")
    local command = string.format(
        "powershell -NoProfile -Command \"Invoke-WebRequest -UseBasicParsing -Uri '%s' -Method Post -ContentType 'application/json' -InFile '%s' | Out-Null; Remove-Item '%s' -ErrorAction SilentlyContinue\"",
        cfg.url,
        normalizedPath,
        normalizedPath
    )
    pcall(os.execute, command)
end
-- #endregion

local function parseArgs(argv)
    local config = {
        chapterId = DEFAULT_CONFIG.chapterId,
        route = DEFAULT_CONFIG.route,
        runs = DEFAULT_CONFIG.runs,
        seed = DEFAULT_CONFIG.seed,
        tickMs = DEFAULT_CONFIG.tickMs,
        maxBattleTicks = DEFAULT_CONFIG.maxBattleTicks,
        verbose = DEFAULT_CONFIG.verbose,
        shopPolicy = DEFAULT_CONFIG.shopPolicy,
        starterHeroIds = DEFAULT_CONFIG.starterHeroIds,
        customNodes = nil,
    }

    for _, value in ipairs(argv or {}) do
        if value == "--verbose" then
            config.verbose = true
        elseif value == "--help" or value == "-h" then
            config.help = true
        else
            local key, raw = string.match(value, "^%-%-(.-)=(.*)$")
            if key == "chapter" then
                config.chapterId = tonumber(raw) or config.chapterId
            elseif key == "route" then
                config.route = raw
            elseif key == "runs" then
                config.runs = math.max(1, tonumber(raw) or config.runs)
            elseif key == "seed" then
                config.seed = tonumber(raw) or config.seed
            elseif key == "tick" then
                config.tickMs = math.max(1, tonumber(raw) or config.tickMs)
            elseif key == "max-battle-ticks" then
                config.maxBattleTicks = math.max(1, tonumber(raw) or config.maxBattleTicks)
            elseif key == "nodes" then
                local nodes = parseIntCsv(raw)
                if #nodes > 0 then
                    config.customNodes = nodes
                    config.route = "custom"
                end
            elseif key == "starter" then
                local ids = parseIntCsv(raw)
                if #ids > 0 then
                    config.starterHeroIds = ids
                end
            elseif key == "shop" then
                config.shopPolicy = raw
            end
        end
    end

    return config
end

local function printUsage()
    print("roguelike balance tool")
    print("  --route=all|safe|combat|custom")
    print("  --nodes=battle_normal,recruit,boss,...")
    print("  --runs=10")
    print("  --seed=101")
    print("  --tick=800")
    print("  --max-battle-ticks=1200")
    print("  --starter=900005,900007,900002")
    print("  --shop=basic|leave")
    print("  --verbose")
end

local function buildRoutes(config)
    if config.customNodes and #config.customNodes > 0 then
        return {
            {
                name = "custom",
                nodeTypes = config.customNodes,
            },
        }
    end

    local chapterRoutes = ROUTE_PRESETS[config.chapterId]
    assert(chapterRoutes, "no route presets for chapter " .. tostring(config.chapterId))

    if config.route == "all" then
        return {
            { name = "safe", nodeTypes = chapterRoutes.safe },
            { name = "combat", nodeTypes = chapterRoutes.combat },
        }
    end

    local preset = chapterRoutes[config.route]
    assert(preset, "unknown route preset: " .. tostring(config.route))
    return {
        { name = config.route, nodeTypes = preset },
    }
end

local function getTeamStats(snapshot)
    local totalHp, totalMaxHp, aliveCount = 0, 0, 0
    for _, hero in ipairs(snapshot.team or {}) do
        totalHp = totalHp + (hero.hp or 0)
        totalMaxHp = totalMaxHp + (hero.maxHp or 0)
        if not hero.isDead and (hero.hp or 0) > 0 then
            aliveCount = aliveCount + 1
        end
    end
    return totalHp, totalMaxHp, aliveCount
end

local function getBattleTeamStats(snapshot)
    local totalHp, totalMaxHp, aliveCount = 0, 0, 0
    local battleSnapshot = snapshot and snapshot.battleSnapshot or nil
    for _, hero in ipairs(battleSnapshot and battleSnapshot.leftTeam or {}) do
        totalHp = totalHp + (hero.hp or 0)
        totalMaxHp = totalMaxHp + (hero.maxHp or 0)
        if not hero.isDead and hero.isAlive and (hero.hp or 0) > 0 then
            aliveCount = aliveCount + 1
        end
    end
    return totalHp, totalMaxHp, aliveCount
end

-- #region debug-point B:frozen-gate-battle-state
local function summarizeUnits(units)
    local result = {}
    for _, unit in ipairs(units or {}) do
        result[#result + 1] = {
            id = unit.id,
            name = unit.name,
            team = unit.team,
            position = unit.position,
            hp = unit.hp,
            maxHp = unit.maxHp,
            ac = unit.ac,
            hit = unit.hit,
            spellDC = unit.spellDC,
            saveFort = unit.saveFort,
            saveRef = unit.saveRef,
            saveWill = unit.saveWill,
            isAlive = unit.isAlive,
            buffs = unit.buffs,
        }
    end
    return result
end

local function summarizeInterestingEvent(event)
    if type(event) ~= "table" then
        return nil
    end
    local eventType = tostring(event.type or "")
    local interesting = {
        DAMAGE_DEALT = true,
        HEAL_RECEIVED = true,
        MISS = true,
        DODGE = true,
        BLOCK = true,
        CRIT = true,
        SKILL_CAST_STARTED = true,
        TURN_STARTED = true,
        TURN_ENDED = true,
        CombatLog = true,
        DebugCounterTiming = true,
    }
    if not interesting[eventType] then
        return nil
    end
    return {
        type = eventType,
        payload = event.payload,
    }
end

local function reportFrozenGateSnapshot(runId, hypothesisId, msg, snapshot, extra)
    local battleSnapshot = snapshot and snapshot.battleSnapshot or {}
    reportDebugEvent(runId, hypothesisId, "bin/test_roguelike_balance.lua", msg, {
        phase = snapshot and snapshot.phase or nil,
        round = battleSnapshot.round,
        pendingCommands = battleSnapshot.pendingCommands,
        leftTeam = summarizeUnits(battleSnapshot.leftTeam),
        rightTeam = summarizeUnits(battleSnapshot.rightTeam),
        result = battleSnapshot.result,
        extra = extra,
    })
end
-- #endregion

local function getUltimateSkillForUnit(unitId)
    local hero = BattleFormation.FindHeroByInstanceId and BattleFormation.FindHeroByInstanceId(tonumber(unitId)) or nil
    local instances = hero and hero.skillData and hero.skillData.skillInstances or nil
    if not instances then
        return nil
    end
    for _, skill in pairs(instances) do
        if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then
            return skill
        end
    end
    return nil
end

local function isEnemyOrOutputUltimate(unit)
    if not unit or not unit.id or unit.ultimateReady ~= true then
        return false
    end

    local ult = getUltimateSkillForUnit(unit.id)
    if not ult then
        return false
    end

    local ts = ult.targetsSelections or (ult.config and ult.config.targetsSelections) or nil
    local castTarget = ts and ts.castTarget or ult.castTarget
    if castTarget == E_CAST_TARGET.Enemy or castTarget == E_CAST_TARGET.EnemyPos then
        return true
    end

    local desc = (ult.skillConfig and ult.skillConfig.Description) or ""
    if desc:find("治疗") or desc:find("复活") then
        return false
    end
    if desc:find("伤害骰") or desc:find("%dd%d+") or desc:find("d%d+") then
        return true
    end
    return false
end

local function findReadyHero(snapshot)
    local battleSnapshot = snapshot and snapshot.battleSnapshot or nil
    if not battleSnapshot then
        return nil
    end
    for _, unit in ipairs(battleSnapshot.leftTeam or {}) do
        if isEnemyOrOutputUltimate(unit) then
            return unit.id
        end
    end
    return nil
end

local function getBattleRound(snapshot)
    local battleSnapshot = snapshot and snapshot.battleSnapshot or nil
    return tonumber(battleSnapshot and battleSnapshot.round) or 0
end

local function chooseRewardIndex(snapshot)
    local reward = snapshot.rewardState
    if not reward or not reward.options then
        return nil
    end

    if reward.kind == "node_recruit" then
        local existing = {}
        for _, hero in ipairs(snapshot.team or {}) do
            existing[hero.heroId] = true
        end
        for _, hero in ipairs(snapshot.bench or {}) do
            existing[hero.heroId] = true
        end
        local bestIndex, bestQuality
        for index, option in ipairs(reward.options) do
            local heroId = tonumber(option.refId)
            if heroId and not existing[heroId] then
                local heroInfo = HeroData.GetHeroInfo(heroId) or {}
                local quality = tonumber(heroInfo.BaseQuality or heroInfo.Quality) or 1
                if not bestQuality or quality > bestQuality then
                    bestIndex = index
                    bestQuality = quality
                end
            end
        end
        if bestIndex then
            return bestIndex
        end
    end

    local bestIndex, bestScore
    for index, option in ipairs(reward.options) do
        local score = REWARD_PRIORITY[option.rewardType] or 99
        if not bestScore or score < bestScore then
            bestIndex = index
            bestScore = score
        end
    end
    return bestIndex
end

local function getShopItemKind(goods)
    if goods.goodsType ~= "service" then
        return goods.goodsType
    end
    local item = RunShopGoods.GetGoods(goods.goodsId)
    local effectType = item and item.payload and item.payload.effectType or ""
    if effectType == "team_heal_pct" then
        return "service_heal"
    end
    return "service_other"
end

local function buyFromShop(snapshot, policy)
    if policy == "leave" then
        return
    end

    local purchased = true
    while purchased do
        purchased = false
        snapshot = Run.GetSnapshot()
        local goods = {}
        for _, item in ipairs(snapshot.shopState and snapshot.shopState.goods or {}) do
            if not item.sold and (item.price or 0) <= (snapshot.gold or 0) then
                goods[#goods + 1] = item
            end
        end

        table.sort(goods, function(a, b)
            local pa = SHOP_PRIORITY[getShopItemKind(a)] or 99
            local pb = SHOP_PRIORITY[getShopItemKind(b)] or 99
            if pa ~= pb then
                return pa < pb
            end
            if (a.price or 0) ~= (b.price or 0) then
                return (a.price or 0) < (b.price or 0)
            end
            return (a.goodsId or 0) < (b.goodsId or 0)
        end)

        local item = goods[1]
        if item then
            local ok = Run.ShopBuy(item.goodsId)
            if ok then
                purchased = true
            end
        end
    end
end

local autoPromoteBench

local function chooseRewardsUntilDone()
    local snapshot = Run.GetSnapshot()
    local guard = 0
    while snapshot.phase == "reward" and guard < 4 do
        local rewardIndex = chooseRewardIndex(snapshot)
        if not rewardIndex then
            break
        end
        local rewardOk, rewardReason = Run.ChooseReward(rewardIndex)
        if not rewardOk then
            return false, rewardReason
        end
        autoPromoteBench()
        snapshot = Run.GetSnapshot()
        guard = guard + 1
    end
    return true
end

function autoPromoteBench()
    local snapshot = Run.GetSnapshot()
    while #(snapshot.bench or {}) > 0 and #(snapshot.team or {}) < (snapshot.maxHeroCount or 5) do
        local benchHero = snapshot.bench[1]
        if not benchHero then
            break
        end
        local ok = Run.PromoteBenchHero(benchHero.rosterId)
        if not ok then
            break
        end
        snapshot = Run.GetSnapshot()
    end
end

local function resolveBattle(config, debugBattle)
    local snapshot = Run.GetSnapshot()
    local ticks = 0
    local castedUltimate = false
    local startRound = getBattleRound(snapshot)
    local lastRound = startRound
    local maxRoundSeen = startRound
    local lastBattleHp, lastBattleMaxHp, lastBattleAlive = getBattleTeamStats(snapshot)
    if debugBattle and debugBattle.enabled then
        reportFrozenGateSnapshot(debugBattle.runId, "A", "[DEBUG] Frozen Gate battle start", snapshot, {
            route = debugBattle.routeName,
            nodeId = debugBattle.nodeId,
            title = debugBattle.title,
            battleId = debugBattle.battleId,
            beforeHp = lastBattleHp,
            beforeMaxHp = lastBattleMaxHp,
            beforeAlive = lastBattleAlive,
        })
    end
    while ticks < config.maxBattleTicks do
        ticks = ticks + 1
        local readyHeroId = (config.autoUltimate and not castedUltimate) and findReadyHero(snapshot) or nil
        if readyHeroId and snapshot.battleSnapshot and snapshot.battleSnapshot.pendingCommands == 0 then
            Run.QueueBattleCommand({
                type = "cast_ultimate",
                heroId = readyHeroId,
            })
            castedUltimate = true
        end
        local tickEvents = Run.Tick(config.tickMs) or {}
        snapshot = Run.GetSnapshot()
        if snapshot.phase == "battle" then
            lastRound = getBattleRound(snapshot)
            if lastRound > maxRoundSeen then
                maxRoundSeen = lastRound
            end
            local prevHp = lastBattleHp
            lastBattleHp, lastBattleMaxHp, lastBattleAlive = getBattleTeamStats(snapshot)
            if debugBattle and debugBattle.enabled then
                local interestingEvents = {}
                for _, event in ipairs(tickEvents) do
                    local summarized = summarizeInterestingEvent(event)
                    if summarized then
                        interestingEvents[#interestingEvents + 1] = summarized
                    end
                end
                if #interestingEvents > 0 then
                    reportDebugEvent(debugBattle.runId, "D", "bin/test_roguelike_balance.lua", "[DEBUG] Frozen Gate tick events", {
                        tick = ticks,
                        round = lastRound,
                        events = interestingEvents,
                    })
                end
                if lastRound ~= startRound and (lastRound ~= (debugBattle.lastReportedRound or -1) or lastBattleHp ~= prevHp) then
                    debugBattle.lastReportedRound = lastRound
                    reportFrozenGateSnapshot(debugBattle.runId, "B", "[DEBUG] Frozen Gate battle hp trace", snapshot, {
                        tick = ticks,
                        hp = lastBattleHp,
                        maxHp = lastBattleMaxHp,
                        alive = lastBattleAlive,
                    })
                end
            end
        end
        if snapshot.phase ~= "battle" then
            if debugBattle and debugBattle.enabled then
                reportFrozenGateSnapshot(debugBattle.runId, "E", "[DEBUG] Frozen Gate battle end", snapshot, {
                    tick = ticks,
                    lastBattleHp = lastBattleHp,
                    lastBattleMaxHp = lastBattleMaxHp,
                    lastBattleAlive = lastBattleAlive,
                })
            end
            return snapshot, ticks, false, {
                startRound = startRound,
                endRound = lastRound,
                maxRoundSeen = maxRoundSeen,
                roundsSpent = math.max(0, lastRound - startRound + (lastRound > 0 and 1 or 0)),
                lastBattleHp = lastBattleHp,
                lastBattleMaxHp = lastBattleMaxHp,
                lastBattleAlive = lastBattleAlive,
            }
        end
    end
    return snapshot, ticks, true, {
        startRound = startRound,
        endRound = lastRound,
        maxRoundSeen = maxRoundSeen,
        roundsSpent = math.max(0, lastRound - startRound + (lastRound > 0 and 1 or 0)),
        lastBattleHp = lastBattleHp,
        lastBattleMaxHp = lastBattleMaxHp,
        lastBattleAlive = lastBattleAlive,
    }
end

local function countTableValues(map)
    local total = 0
    for _, value in pairs(map or {}) do
        total = total + value
    end
    return total
end

local function addCount(map, key)
    map[key] = (map[key] or 0) + 1
end

local function ensureNodeStat(routeStats, nodeId, nodeTitle)
    routeStats.nodeStats[nodeId] = routeStats.nodeStats[nodeId] or {
        title = nodeTitle,
        appearances = 0,
        clears = 0,
        totalTicks = 0,
        totalEndRounds = 0,
        totalRoundsSpent = 0,
        totalBeforeHpPct = 0,
        totalAfterHpPct = 0,
        totalBeforeMissingHp = 0,
        totalAfterMissingHp = 0,
        failureReasons = {},
    }
    return routeStats.nodeStats[nodeId]
end

local function runSingleRoute(route, config, runIndex, routeIndex)
    math.randomseed(config.seed + routeIndex * 10000 + runIndex)

    local snapshot = Run.StartRun({
        chapterId = config.chapterId,
        starterHeroIds = config.starterHeroIds,
        seed = config.seed + routeIndex * 10000 + runIndex,
    })

    local runReport = {
        success = false,
        finalPhase = snapshot.phase,
        battles = {},
        terminalReason = nil,
        finalHpPct = 0,
        finalAlive = 0,
    }

    for index, wantedNodeType in ipairs(route.nodeTypes or {}) do
        local selectable = {}
        for _, candidate in ipairs((Run.GetSnapshot().map and Run.GetSnapshot().map.nodes) or {}) do
            if candidate.selectable then
                selectable[#selectable + 1] = candidate
            end
        end
        table.sort(selectable, function(a, b)
            if (a.floor or 0) ~= (b.floor or 0) then
                return (a.floor or 0) < (b.floor or 0)
            end
            return (a.lane or 0) < (b.lane or 0)
        end)

        local actualNode = nil
        for _, candidate in ipairs(selectable) do
            if candidate.nodeType == wantedNodeType then
                actualNode = candidate
                break
            end
        end
        if not actualNode then
            actualNode = selectable[1]
        end

        local actualNodeId = actualNode and actualNode.id or nil
        if not actualNodeId then
            runReport.terminalReason = "no_selectable_node"
            break
        end

        local ok, reason = Run.ChoosePath(actualNodeId)
        if not ok then
            runReport.terminalReason = "choose_path_failed:" .. tostring(reason)
            break
        end
        ok, reason = Run.EnterCurrentNode()
        if not ok then
            runReport.terminalReason = "enter_node_failed:" .. tostring(reason)
            break
        end

        snapshot = Run.GetSnapshot()
        if snapshot.phase == "battle" then
            local beforeHp, beforeMaxHp, beforeAlive = getBattleTeamStats(snapshot)
            local debugBattle = nil
            if actualNode.nodeType == "boss" then
                debugBattle = {
                    enabled = true,
                    runId = string.format("pre-%s-%d", route.name, runIndex),
                    routeName = route.name,
                    nodeId = actualNodeId,
                    title = actualNode.title,
                    battleId = actualNode.battleId,
                }
            end
            local resolved, ticks, timedOut, roundStats = resolveBattle(config, debugBattle)
            local afterHp = roundStats.lastBattleHp or 0
            local afterMaxHp = roundStats.lastBattleMaxHp or 0
            local afterAlive = roundStats.lastBattleAlive or 0
            local battleResult = resolved.battleSnapshot and resolved.battleSnapshot.result or nil
            local battleReason = timedOut and "battle_timeout"
                or (battleResult and battleResult.reason)
                or (resolved.chapterResult and resolved.chapterResult.reason)
                or resolved.phase

            runReport.battles[#runReport.battles + 1] = {
                nodeId = actualNodeId,
                title = actualNode.title,
                plannedType = wantedNodeType,
                routeIndex = index,
                phase = resolved.phase,
                ticks = ticks,
                startRound = roundStats.startRound or 0,
                endRound = roundStats.endRound or 0,
                maxRoundSeen = roundStats.maxRoundSeen or 0,
                roundsSpent = roundStats.roundsSpent or 0,
                reason = battleReason,
                beforeHp = beforeHp,
                beforeMaxHp = beforeMaxHp,
                beforeAlive = beforeAlive,
                afterHp = afterHp,
                afterMaxHp = afterMaxHp,
                afterAlive = afterAlive,
            }

            if timedOut or (resolved.phase ~= "reward" and resolved.phase ~= "map" and resolved.phase ~= "chapter_result") then
                runReport.terminalReason = battleReason
                snapshot = resolved
                break
            end

            if resolved.phase == "reward" then
                local rewardsOk, rewardsReason = chooseRewardsUntilDone()
                if not rewardsOk then
                    runReport.terminalReason = "choose_reward_failed:" .. tostring(rewardsReason)
                    snapshot = Run.GetSnapshot()
                    break
                end
            end
            snapshot = Run.GetSnapshot()
        elseif snapshot.phase == "event" then
            local eventOk, eventReason = Run.ChooseEventOption(1)
            if not eventOk then
                runReport.terminalReason = "choose_event_failed:" .. tostring(eventReason)
                snapshot = Run.GetSnapshot()
                break
            end
            autoPromoteBench()
            snapshot = Run.GetSnapshot()
            if snapshot.phase == "reward" then
                local rewardsOk, rewardsReason = chooseRewardsUntilDone()
                if not rewardsOk then
                    runReport.terminalReason = "choose_reward_failed:" .. tostring(rewardsReason)
                    snapshot = Run.GetSnapshot()
                    break
                end
                snapshot = Run.GetSnapshot()
            end
        elseif snapshot.phase == "shop" then
            buyFromShop(snapshot, config.shopPolicy)
            autoPromoteBench()
            local shopOk, shopReason = Run.ShopLeave()
            if not shopOk then
                runReport.terminalReason = "leave_shop_failed:" .. tostring(shopReason)
                snapshot = Run.GetSnapshot()
                break
            end
            snapshot = Run.GetSnapshot()
        elseif snapshot.phase == "camp" then
            local campActionId = 2
            local campState = snapshot.campState or {}
            local hasBlessingAction = false
            for _, action in ipairs(campState.actions or {}) do
                if tonumber(action.id) == 2 and action.available ~= false then
                    hasBlessingAction = true
                    break
                end
            end
            if not hasBlessingAction then
                campActionId = 1
            end
            local campOk, campReason = Run.CampChoose(campActionId)
            if not campOk then
                runReport.terminalReason = "camp_failed:" .. tostring(campReason)
                snapshot = Run.GetSnapshot()
                break
            end
            snapshot = Run.GetSnapshot()
        elseif snapshot.phase == "reward" then
            local rewardIndex = chooseRewardIndex(snapshot)
            if rewardIndex then
                local rewardOk, rewardReason = Run.ChooseReward(rewardIndex)
                if not rewardOk then
                    runReport.terminalReason = "choose_reward_failed:" .. tostring(rewardReason)
                    snapshot = Run.GetSnapshot()
                    break
                end
            end
            autoPromoteBench()
            snapshot = Run.GetSnapshot()
        end

        if snapshot.phase == "chapter_result" or snapshot.phase == "failed" then
            break
        end
    end

    snapshot = Run.GetSnapshot()
    runReport.finalPhase = snapshot.phase
    runReport.success = snapshot.chapterResult and snapshot.chapterResult.success == true or false
    runReport.terminalReason = runReport.terminalReason
        or (snapshot.chapterResult and snapshot.chapterResult.reason)
        or snapshot.phase

    local finalHp, finalMaxHp, finalAlive = getTeamStats(snapshot)
    runReport.finalHpPct = finalMaxHp > 0 and (finalHp / finalMaxHp) or 0
    runReport.finalAlive = finalAlive
    return runReport
end

local function summarizeRoute(route, runReports)
    local stats = {
        runs = #runReports,
        wins = 0,
        totalFinalHpPct = 0,
        totalBattles = 0,
        nodeStats = {},
        terminalReasons = {},
    }

    for _, report in ipairs(runReports) do
        if report.success then
            stats.wins = stats.wins + 1
        end
        stats.totalFinalHpPct = stats.totalFinalHpPct + report.finalHpPct
        stats.totalBattles = stats.totalBattles + #report.battles
        addCount(stats.terminalReasons, report.terminalReason or "unknown")

        for _, battle in ipairs(report.battles) do
            local nodeStat = ensureNodeStat(stats, battle.nodeId, battle.title)
            nodeStat.appearances = nodeStat.appearances + 1
            nodeStat.totalTicks = nodeStat.totalTicks + (battle.ticks or 0)
            nodeStat.totalEndRounds = nodeStat.totalEndRounds + (battle.endRound or 0)
            nodeStat.totalRoundsSpent = nodeStat.totalRoundsSpent + (battle.roundsSpent or 0)
            nodeStat.totalBeforeHpPct = nodeStat.totalBeforeHpPct + ((battle.beforeMaxHp or 0) > 0 and (battle.beforeHp / battle.beforeMaxHp) or 0)
            nodeStat.totalAfterHpPct = nodeStat.totalAfterHpPct + ((battle.afterMaxHp or 0) > 0 and (battle.afterHp / battle.afterMaxHp) or 0)
            nodeStat.totalBeforeMissingHp = nodeStat.totalBeforeMissingHp + getMissingHp(battle.beforeHp, battle.beforeMaxHp)
            nodeStat.totalAfterMissingHp = nodeStat.totalAfterMissingHp + getMissingHp(battle.afterHp, battle.afterMaxHp)
            if battle.phase == "reward" or battle.phase == "map" or battle.phase == "chapter_result" then
                nodeStat.clears = nodeStat.clears + 1
            else
                addCount(nodeStat.failureReasons, battle.reason or "unknown")
            end
        end
    end

    print("")
    print(string.rep("=", 72))
    print(string.format("Route: %s", route.name))
    print(string.rep("=", 72))
    print(string.format(
        "Runs=%d  Wins=%d  WinRate=%s  AvgFinalHp=%s  AvgBattles=%.2f",
        stats.runs,
        stats.wins,
        formatPct(stats.wins, stats.runs),
        formatPct(stats.totalFinalHpPct, stats.runs),
        stats.runs > 0 and (stats.totalBattles / stats.runs) or 0
    ))
    print("Nodes:")

    local orderedNodeIds = {}
    for nodeId, _ in pairs(stats.nodeStats) do
        orderedNodeIds[#orderedNodeIds + 1] = nodeId
    end
    table.sort(orderedNodeIds)

    for _, nodeId in ipairs(orderedNodeIds) do
        local nodeStat = stats.nodeStats[nodeId]
        if nodeStat then
            local avgTicks = nodeStat.appearances > 0 and (nodeStat.totalTicks / nodeStat.appearances) or 0
            local avgEndRound = nodeStat.appearances > 0 and (nodeStat.totalEndRounds / nodeStat.appearances) or 0
            local avgSpentRounds = nodeStat.appearances > 0 and (nodeStat.totalRoundsSpent / nodeStat.appearances) or 0
            local avgBeforeHp = nodeStat.appearances > 0 and (nodeStat.totalBeforeHpPct / nodeStat.appearances) or 0
            local avgAfterHp = nodeStat.appearances > 0 and (nodeStat.totalAfterHpPct / nodeStat.appearances) or 0
            local avgBeforeMissingHp = nodeStat.appearances > 0 and (nodeStat.totalBeforeMissingHp / nodeStat.appearances) or 0
            local avgAfterMissingHp = nodeStat.appearances > 0 and (nodeStat.totalAfterMissingHp / nodeStat.appearances) or 0
            local failCount = countTableValues(nodeStat.failureReasons)
            print(string.format(
                "  %-18s clear=%s avgTicks=%.1f avgEndRound=%.1f avgSpentRounds=%.1f hp=%s -> %s missing=%s -> %s fail=%d",
                nodeStat.title,
                formatPct(nodeStat.clears, nodeStat.appearances),
                avgTicks,
                avgEndRound,
                avgSpentRounds,
                formatPct(avgBeforeHp, 1),
                formatPct(avgAfterHp, 1),
                formatNumber(avgBeforeMissingHp),
                formatNumber(avgAfterMissingHp),
                failCount
            ))
            if failCount > 0 then
                local reasons = {}
                for reason, count in pairs(nodeStat.failureReasons) do
                    reasons[#reasons + 1] = string.format("%s=%d", reason, count)
                end
                table.sort(reasons)
                print("    failures: " .. table.concat(reasons, ", "))
            end
        end
    end

    local reasons = {}
    for reason, count in pairs(stats.terminalReasons) do
        reasons[#reasons + 1] = string.format("%s=%d", reason, count)
    end
    table.sort(reasons)
    print("Terminal: " .. table.concat(reasons, ", "))
end

local function printVerboseRuns(route, runReports)
    print("")
    print(string.format("Verbose Runs: %s", route.name))
    for index, report in ipairs(runReports) do
        print(string.format(
            "  run %02d success=%s final=%s hp=%s alive=%d reason=%s",
            index,
            tostring(report.success),
            tostring(report.finalPhase),
            formatPct(report.finalHpPct, 1),
            report.finalAlive,
            tostring(report.terminalReason)
        ))
        for _, battle in ipairs(report.battles) do
            print(string.format(
                "    %-18s phase=%s ticks=%d round=%d->%d spent=%d hp=%d/%d -> %d/%d missing=%d -> %d reason=%s",
                battle.title,
                battle.phase,
                battle.ticks,
                battle.startRound,
                battle.endRound,
                battle.roundsSpent,
                battle.beforeHp,
                battle.beforeMaxHp,
                battle.afterHp,
                battle.afterMaxHp,
            getMissingHp(battle.beforeHp, battle.beforeMaxHp),
            getMissingHp(battle.afterHp, battle.afterMaxHp),
                battle.reason
            ))
        end
    end
end

local function printHeader(config, routes)
    local routeNames = {}
    for _, route in ipairs(routes) do
        routeNames[#routeNames + 1] = route.name
    end
    print("Roguelike Balance Test")
    print(string.format(
        "chapter=%d routes=%s runs=%d seed=%d tick=%d maxBattleTicks=%d shop=%s starter=%s",
        config.chapterId,
        table.concat(routeNames, ","),
        config.runs,
        config.seed,
        config.tickMs,
        config.maxBattleTicks,
        config.shopPolicy,
        table.concat(config.starterHeroIds, ",")
    ))
end

local function main(argv)
    local config = parseArgs(argv)
    if config.help then
        printUsage()
        return
    end

    local routes = buildRoutes(config)
    printHeader(config, routes)

    for routeIndex, route in ipairs(routes) do
        local runReports = {}
        for runIndex = 1, config.runs do
            runReports[#runReports + 1] = runSingleRoute(route, config, runIndex, routeIndex)
        end
        summarizeRoute(route, runReports)
        if config.verbose then
            printVerboseRuns(route, runReports)
        end
    end
end

main(arg)
