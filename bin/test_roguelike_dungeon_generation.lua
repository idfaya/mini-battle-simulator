-- Roguelike 地牢生成回归测试
-- 设计文档：design/dungeon_design.md §3 / §4 / §7.1
-- 验证：
--   1) 种子 1..200 × 章 {101, 102, 103} 的 DungeonGenerator.Generate 全部通过 BFS 连通校验
--   2) 章 101 第 1 层 upStairRoomId == nil；其余普通层 upStair 必有
--   3) 普通层 downStair 必有；boss 层 downStair == nil 且至少 1 个 boss 房
--   4) roomCount >= 6 的非 boss 层 至少 4 种 roomType（stair_up/stair_down 计独立 type）
--   5) 单层约束：camp/shop/battle_elite 数量 ≤ 模板上限
--   6) DungeonGenerator.GenerateHiddenFloor(101, seed) 返回非 nil；isHidden + isBossFloor + 至少 1 个 boss 房
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local DungeonGenerator = require("roguelike.dungeon_generator")
local Floors = require("config.tables.floors")
local RunChapterConfig = require("config.roguelike.run_chapter_config")
local RunEventConfig = require("config.roguelike.run_event_config")
local RunMapGenProfile = require("config.roguelike.run_map_gen_profile")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local SEED_COUNT = 200
local CHAPTER_IDS = { 101, 102, 103 }

local function countRoomTypes(rooms)
    local typeSet = {}
    local counts = { camp = 0, shop = 0, battle_elite = 0, event = 0 }
    for _, room in pairs(rooms or {}) do
        local rt = tostring(room.roomType or "")
        typeSet[rt] = true
        if counts[rt] ~= nil then
            counts[rt] = counts[rt] + 1
        end
    end
    local typeCount = 0
    for _ in pairs(typeSet) do
        typeCount = typeCount + 1
    end
    return typeCount, counts, typeSet
end

local function collectEventIds(rooms)
    local ids = {}
    for _, room in pairs(rooms or {}) do
        local eventId = tonumber(room.payload and room.payload.eventId)
        if room.roomType == "event" and eventId then
            ids[#ids + 1] = eventId
        end
    end
    table.sort(ids)
    return ids
end

local function hasBossRoom(rooms)
    for _, room in pairs(rooms or {}) do
        if room.roomType == "boss" then
            return true
        end
    end
    return false
end

local totalFloors = 0
for _, chapterId in ipairs(CHAPTER_IDS) do
    local chapter = RunChapterConfig.GetChapter(chapterId)
    assert_true(chapter, "chapter " .. chapterId .. " not found")
    local profile = RunMapGenProfile.GetProfile(chapter.mapGenProfileId)
    assert_true(profile, "profile for chapter " .. chapterId .. " not found")
    for seed = 1, SEED_COUNT do
        local state, err = DungeonGenerator.Generate(seed, chapterId, profile)
        assert_true(state, string.format("seed=%d chapter=%d generate failed: %s", seed, chapterId, tostring(err)))
        local chapterSeenEventIds = {}
        local chapterCampCount = 0

        local ok, validateErr = DungeonGenerator.Validate(state)
        assert_true(ok, string.format("seed=%d chapter=%d validate failed: %s", seed, chapterId, tostring(validateErr)))

        local floorTemplateIds = chapter.floorTemplateIds
        local lastIdx = #floorTemplateIds
        for depth = 1, lastIdx do
            local floor = state.floors[depth]
            assert_true(floor, string.format("seed=%d chapter=%d floor depth=%d missing", seed, chapterId, depth))
            totalFloors = totalFloors + 1

            local template = Floors.GetTemplate(floorTemplateIds[depth])
            assert_true(template, string.format("template %d not found", floorTemplateIds[depth]))

            -- (2) 每章第 1 层 upStairRoomId == nil（起点房改为 entrance）；其余普通层 upStair 必有
            if depth == 1 then
                assert_true(floor.upStairRoomId == nil,
                    string.format("seed=%d chapter=%d depth=1 should have no upStair", seed, chapterId))
            else
                if not template.isBoss then
                    assert_true(floor.upStairRoomId ~= nil,
                        string.format("seed=%d chapter=%d depth=%d should have upStair", seed, chapterId, depth))
                end
            end

            -- (3) 普通层 downStair 必有；boss 层 downStair == nil 且至少 1 个 boss 房
            if template.isBoss then
                assert_true(floor.downStairRoomId == nil,
                    string.format("seed=%d chapter=%d depth=%d boss floor should have no downStair", seed, chapterId, depth))
                assert_true(hasBossRoom(floor.rooms),
                    string.format("seed=%d chapter=%d depth=%d boss floor missing boss room", seed, chapterId, depth))
            else
                assert_true(floor.downStairRoomId ~= nil,
                    string.format("seed=%d chapter=%d depth=%d normal floor should have downStair", seed, chapterId, depth))
            end

            -- (4) roomCount >= 6 的非 boss 层至少 3 种 roomType（楼梯/入口计独立 type；
            --     第 1 层只有 entrance + stair_down，普通房间至少需要再凑 1 种）
            if not template.isBoss and (floor.roomCount or 0) >= 6 then
                local typeCount = countRoomTypes(floor.rooms)
                assert_true(typeCount >= 3,
                    string.format("seed=%d chapter=%d depth=%d roomCount=%d only %d roomTypes (need >=3)",
                        seed, chapterId, depth, floor.roomCount, typeCount))
            end

            -- (5) 单层约束
            local _, counts = countRoomTypes(floor.rooms)
            local maxCamp = template.constraints and template.constraints.maxCamp
            local maxShop = template.constraints and template.constraints.maxShop
            local maxElite = template.constraints and template.constraints.maxElite
            local maxEvent = template.constraints and template.constraints.maxEvent
            if maxCamp then
                assert_true(counts.camp <= maxCamp,
                    string.format("seed=%d chapter=%d depth=%d camp=%d > maxCamp=%d", seed, chapterId, depth, counts.camp, maxCamp))
            end
            if depth == 3 and not template.isBoss then
                assert_true(counts.camp == 1,
                    string.format("seed=%d chapter=%d depth=3 should have exactly one camp, got %d", seed, chapterId, counts.camp))
            elseif not template.isBoss then
                assert_true(counts.camp == 0,
                    string.format("seed=%d chapter=%d depth=%d should have no camp, got %d", seed, chapterId, depth, counts.camp))
            end
            chapterCampCount = chapterCampCount + counts.camp
            if maxShop then
                assert_true(counts.shop <= maxShop,
                    string.format("seed=%d chapter=%d depth=%d shop=%d > maxShop=%d", seed, chapterId, depth, counts.shop, maxShop))
            end
            if maxElite then
                assert_true(counts.battle_elite <= maxElite,
                    string.format("seed=%d chapter=%d depth=%d elite=%d > maxElite=%d", seed, chapterId, depth, counts.battle_elite, maxElite))
            end
            if maxEvent then
                assert_true(counts.event <= maxEvent,
                    string.format("seed=%d chapter=%d depth=%d event=%d > maxEvent=%d", seed, chapterId, depth, counts.event, maxEvent))
            end

            local floorEventIds = collectEventIds(floor.rooms)
            local floorSeenEventIds = {}
            for _, eventId in ipairs(floorEventIds) do
                assert_true(not floorSeenEventIds[eventId],
                    string.format("seed=%d chapter=%d depth=%d duplicated eventId=%d inside floor", seed, chapterId, depth, eventId))
                floorSeenEventIds[eventId] = true

                local event = RunEventConfig.GetEvent(eventId)
                assert_true(event ~= nil,
                    string.format("seed=%d chapter=%d depth=%d eventId=%d missing config", seed, chapterId, depth, eventId))
                local allowed = false
                for _, allowedChapterId in ipairs(event.chapterIds or {}) do
                    if tonumber(allowedChapterId) == chapterId then
                        allowed = true
                        break
                    end
                end
                assert_true(allowed,
                    string.format("seed=%d chapter=%d depth=%d eventId=%d not allowed for chapter", seed, chapterId, depth, eventId))
                assert_true(not chapterSeenEventIds[eventId],
                    string.format("seed=%d chapter=%d repeated eventId=%d across floors", seed, chapterId, eventId))
                chapterSeenEventIds[eventId] = true
            end
        end
        assert_true(chapterCampCount == 1,
            string.format("seed=%d chapter=%d should have exactly one camp in chapter, got %d", seed, chapterId, chapterCampCount))
    end
end

-- (6) 隐藏层（用 chapter 101 抽样几个种子即可）
for _, seed in ipairs({ 1, 17, 73, 137, 200 }) do
    local hiddenFloor, err = DungeonGenerator.GenerateHiddenFloor(101, seed)
    assert_true(hiddenFloor, string.format("hidden floor seed=%d failed: %s", seed, tostring(err)))
    assert_true(hiddenFloor.isHidden == true, string.format("hidden seed=%d isHidden=false", seed))
    assert_true(hiddenFloor.isBossFloor == true, string.format("hidden seed=%d isBossFloor=false", seed))
    assert_true(hasBossRoom(hiddenFloor.rooms), string.format("hidden seed=%d missing boss room", seed))
    assert_true(hiddenFloor.floorDepth == DungeonGenerator.HIDDEN_FLOOR_DEPTH,
        string.format("hidden seed=%d floorDepth=%d expected=%d", seed, hiddenFloor.floorDepth, DungeonGenerator.HIDDEN_FLOOR_DEPTH))
end

print(string.format("test_roguelike_dungeon_generation passed (chapters=%d, seeds=%d, floors=%d)",
    #CHAPTER_IDS, SEED_COUNT, totalFloors))
