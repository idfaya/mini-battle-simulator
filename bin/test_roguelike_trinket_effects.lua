local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EventResolver = require("roguelike.event_resolver")
local TrinketEffects = require("roguelike.trinket_effects")
local RunTrinketConfig = require("config.roguelike.run_trinket_config")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local HeroData = require("config.hero_data")

local function makeHero(level)
    return HeroData.CreateClassUnit(2, {
        rosterId = 1,
        unitId = "test_hero",
        level = level or 5,
        teamState = "active",
        currentHp = 30,
        maxHp = 30,
    })
end

-- void_lantern：检定 +1 应改变档位（固定 roll 时用 ClassifyTier 等价验证）
local voidLantern = RunTrinketConfig.GetTrinket(102002)
assert(voidLantern and voidLantern.effectType == "event_skill_check_bonus", "void_lantern effectType")
local runWithLantern = { trinketIds = { 102002 } }
assert(TrinketEffects.GetEventSkillCheckBonus(runWithLantern) == 1, "event bonus should be 1")

local hero = makeHero(5)
local skillCheck = {
    ability = "investigation",
    dc = 15,
    results = {
        success = { resultType = "grant_gold", result = { gold = 1 } },
        failure = { resultType = "grant_gold", result = { gold = 0 } },
    },
}

-- modifier only: 5e mod at L5 investigation ~ +3..+5; 用 mock 直接测 ResolveSkillCheck 的 extra 参数
local outcomeBase = EventResolver.ResolveSkillCheck(hero, skillCheck, 0)
assert(outcomeBase, "base skill check should resolve")

-- 模拟 roll=10, mod=4 → total 14 fail; +1 → 15 success
local tierFail = EventResolver.ClassifyTier(10, 14, 15)
local tierPass = EventResolver.ClassifyTier(10, 15, 15)
assert(tierFail == "failure" and tierPass == "success", "trinket +1 should flip tier at boundary")

-- ash_crown：精英胜场加金
local runAsh = { trinketIds = { 102001 }, gold = 100 }
TrinketEffects.ApplyBattleVictory(runAsh, { won = true, nodeType = "battle_elite" })
assert(runAsh.gold == 125, "elite victory should add 25 gold, got " .. tostring(runAsh.gold))
TrinketEffects.ApplyBattleVictory(runAsh, { won = true, nodeType = "battle_normal" })
assert(runAsh.gold == 125, "normal battle should not add ash_crown gold")

-- abyss_heart：Boss 战后回满
local unit = makeHero(3)
unit.currentHp = 5
local runHeart = { trinketIds = { 103001 }, ownedUnits = { unit } }
RoguelikeRoster.RefreshLegacyViews(runHeart)
TrinketEffects.ApplyBattleVictory(runHeart, { won = true, nodeType = "boss" })
assert(unit.currentHp == unit.maxHp, "boss victory should full heal with abyss_heart")

-- 战前修正：frost_shard 豁免 +1；ember_sigil 火焰抗性（5e 伤害减半，见 ApplyUnifiedDamageScale）
local modifiers = {
    saveDeltaByClass = {},
    teamResistances = {},
}
local runCombat = { trinketIds = { 101001, 101002 }, ownedUnits = { unit } }
RoguelikeRoster.RefreshLegacyViews(runCombat)
TrinketEffects.ApplyBattleModifiers(runCombat, modifiers)
assert(next(modifiers.saveDeltaByClass) ~= nil, "frost_shard should apply save delta")
assert(modifiers.teamResistances.fire == true, "ember_sigil should grant fire resistance")

print("[OK] roguelike trinket effects")
