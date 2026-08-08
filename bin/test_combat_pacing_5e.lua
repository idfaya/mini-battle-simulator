local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")

local function assert_eq(actual, expected, name)
    if actual ~= expected then
        io.stderr:write(string.format("ASSERT FAIL: %s expected=%s actual=%s\n", name, tostring(expected), tostring(actual)))
        os.exit(1)
    end
    print("ASSERT OK  : " .. name)
end

local fighter = HeroData.CalculateHeroAttributes(900005, 1, 1)
assert_eq(fighter.hp, 15, "player HP includes global pacing multiplier")
assert_eq(fighter.hit, 7, "player physical hit includes global pacing bonus")

local wizard = HeroData.CalculateHeroAttributes(900003, 1, 1)
assert_eq(wizard.spellAttack, 7, "player spell attack includes global pacing bonus")
assert_eq(wizard.spellDC, 14, "player spell DC includes global pacing bonus")

local goblin = EnemyData.ConvertToHeroData(910002)
assert_eq(goblin.hp, 8, "enemy HP includes global pacing multiplier")
assert_eq(goblin.hit, 5, "enemy hit includes global pacing bonus")
assert_eq(goblin.ac, 13, "enemy AC baseline unchanged")

local darkMage = EnemyData.ConvertToHeroData(910005)
assert_eq(darkMage.spellDC, 13, "enemy spell DC includes global pacing bonus")

print("[OK] combat pacing 5e")
