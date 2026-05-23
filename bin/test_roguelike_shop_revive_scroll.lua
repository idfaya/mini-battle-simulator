-- D2-T5：商店复活卷轴（50% HP 复活 + AD-OVR-5 动态定价）
local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local RoguelikeShop = require("roguelike.roguelike_shop")
local RunShopGoods = require("config.roguelike.run_shop_goods")
local HeroData = require("config.hero_data")

local SHOP_ID = 101001
local GOODS_ID = 101010

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", msg or "assert_eq", tostring(expected), tostring(actual)))
    end
end

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

-- AD-OVR-5：68 ×3 = 204；章末 103 ×4 = 272
assert_eq(RunShopGoods.GetReviveScrollPrice(101, SHOP_ID), 204, "chapter 101 revive scroll price")
assert_eq(RunShopGoods.GetReviveScrollPrice(102, SHOP_ID), 204, "chapter 102 revive scroll price")
assert_eq(RunShopGoods.GetReviveScrollPrice(103, SHOP_ID), 272, "chapter 103 revive scroll price")

local scroll = RunShopGoods.GetGoods(GOODS_ID)
assert_true(scroll and scroll.code == "revive_scroll", "goods 101010 should be revive_scroll")
assert_true(math.abs((scroll.payload.healPct or 0) - 0.5) < 0.001, "revive scroll healPct should be 0.5")

-- 单元：购买复活 / 无阵亡不可买且不扣金
do
    local alive = HeroData.CreateClassUnit(2, { level = 3, rosterId = 1 })
    local dead = HeroData.CreateClassUnit(5, { level = 3, rosterId = 2 })
    alive.teamState = "active"
    dead.teamState = "active"
    dead.isDead = true
    dead.currentHp = 0
    alive.currentHp = math.floor((alive.maxHp or 1) * 0.5)

    local runState = {
        chapterId = 101,
        gold = 500,
        shopSoldMap = {},
        ownedUnits = { alive, dead },
    }

    local shopState = RoguelikeShop.BuildShopState(runState, SHOP_ID)
    local scrollItem
    for _, item in ipairs(shopState.goods or {}) do
        if item.goodsId == GOODS_ID then
            scrollItem = item
            break
        end
    end
    assert_true(scrollItem, "shop stock should include revive scroll")
    assert_eq(scrollItem.price, 204, "display price should match AD-OVR-5")

    local goldBefore = runState.gold
    local ok, reason = RoguelikeShop.Buy(runState, SHOP_ID, GOODS_ID)
    assert_true(ok, "buy revive scroll: " .. tostring(reason))
    assert_eq(runState.gold, goldBefore - 204, "gold should be deducted")
    assert_true(dead.isDead == false, "dead hero should be revived")
    assert_eq(dead.currentHp, math.floor((dead.maxHp or 0) * 0.5), "revived hero at 50% max hp")

    runState.gold = 500
    runState.shopSoldMap = {}
    ok, reason = RoguelikeShop.Buy(runState, SHOP_ID, GOODS_ID)
    assert_true(not ok and reason == "no_dead_hero", "should reject when no dead hero")
    assert_eq(runState.gold, 500, "gold should not be deducted on failed revive buy")
end

print("[OK] roguelike shop revive scroll")
