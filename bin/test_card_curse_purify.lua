local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local CardBattle = require("roguelike.card_battle")
local RoguelikeShop = require("roguelike.roguelike_shop")
local RoguelikeCamp = require("roguelike.roguelike_camp")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local function makeRunState()
    return {
        chapterId = 101,
        gold = 100,
        teamRoster = {
            {
                rosterId = 1,
                heroId = 1001,
                unitId = "hero_1",
                name = "测试英雄",
                classId = 2,
                teamState = "active",
                currentHp = 20,
                maxHp = 20,
                isDead = false,
                feats = {},
            },
        },
        ownedUnits = {},
        cardLibrary = {
            version = 1,
            nextSequence = 1,
            cards = {},
        },
        shopSoldMap = {},
    }
end

local state = makeRunState()
local ok, result = CardBattle.AddCurseCard(state, "doubt")
assert_true(ok, "add curse failed: " .. tostring(result))
assert_true(#CardBattle.GetCurseCards(state) == 1, "curse should be active")

ok, result = RoguelikeShop.Buy(state, 101001, 101011)
assert_true(ok, "shop purify failed: " .. tostring(result))
assert_true(#CardBattle.GetCurseCards(state) == 0, "shop purify should remove active curse")
assert_true(state.gold == 64, "shop purify should charge 36 gold")

local cleanState = makeRunState()
ok, result = RoguelikeShop.Buy(cleanState, 101001, 101011)
assert_true(ok == false and result == "no_curse", "shop purify should require curse")
assert_true(cleanState.gold == 100, "failed shop purify should not charge gold")

local campState = makeRunState()
local builtCamp = RoguelikeCamp.BuildCampState(101001, campState)
local purifyAction = nil
for _, action in ipairs(builtCamp.actions or {}) do
    if action.id == 2 then
        purifyAction = action
        break
    end
end
assert_true(purifyAction and purifyAction.available == false, "camp purify should be unavailable without curse")

ok, result = CardBattle.AddCurseCard(campState, "doubt")
assert_true(ok, "add camp curse failed: " .. tostring(result))
builtCamp = RoguelikeCamp.BuildCampState(101001, campState)
purifyAction = nil
for _, action in ipairs(builtCamp.actions or {}) do
    if action.id == 2 then
        purifyAction = action
        break
    end
end
assert_true(purifyAction and purifyAction.available == true, "camp purify should be available with curse")

ok, result = RoguelikeCamp.ApplyAction(campState, 101001, 2)
assert_true(ok, "camp purify failed: " .. tostring(result))
assert_true(#CardBattle.GetCurseCards(campState) == 0, "camp purify should remove active curse")

print("test_card_curse_purify: ok")
