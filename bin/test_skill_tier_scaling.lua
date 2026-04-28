-- Tier (skill.level) assertions for recently tiered skills across classes.
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local function log(msg) print(msg) end
local function assert_true(cond, name)
    if not cond then
        io.stderr:write("ASSERT FAIL: " .. name .. "\n")
        os.exit(1)
    else
        log("ASSERT OK  : " .. name)
    end
end

local BattleEvent = require("core.battle_event")
local BattleBuff = require("modules.battle_buff")
local BattleSkill = require("modules.battle_skill")

BattleEvent.Init()
BattleBuff.Init()
BattleSkill.InitModule()

local function new_unit(id, name)
    return {
        id = id, instanceId = id, name = name,
        hp = 10000, maxHp = 10000,
        atk = 200, def = 0,
        hit = 999, ac = 1,
        spellDC = 999,
        saveFort = 0, saveRef = 0, saveWill = 0,
        __ignoreNatRules = true,
        isDead = false, isAlive = true,
        attributes = { final = {} },
    }
end

local function find_frame(timeline, op, frame)
    local frames = {}
    if type(timeline) == "table" then
        frames = timeline.frames or timeline
    end
    for _, f in ipairs(frames or {}) do
        if f and f.op == op and (frame == nil or f.frame == frame) then
            return f
        end
    end
    return nil
end

-- Test 1: Monk self-heal (80003003) heal dice changes by tier
do
    local skillLua = require("config.skill.skill_80003003")
    local hero = new_unit(3001, "Monk")
    local t1 = skillLua.BuildTimeline(hero, { hero }, { skillId = 80003003, name = "调息", level = 1 })
    local t2 = skillLua.BuildTimeline(hero, { hero }, { skillId = 80003003, name = "调息", level = 2 })
    local t3 = skillLua.BuildTimeline(hero, { hero }, { skillId = 80003003, name = "调息", level = 3 })
    assert_true(find_frame(t1, "heal", 24).healDice == "1d8+3", "Monk heal tier1 dice == 1d8+3")
    assert_true(find_frame(t2, "heal", 24).healDice == "2d8+3", "Monk heal tier2 dice == 2d8+3")
    assert_true(find_frame(t3, "heal", 24).healDice == "2d8+6", "Monk heal tier3 dice == 2d8+6")
end

-- Test 2: Ranger poison strike (80005001) poison layers scale 1/2/3
do
    local SkillTimeline = require("core.skill_timeline")
    local skillLua = require("config.skill.skill_80005001")
    for tier = 1, 3 do
        local hero = new_unit(3100 + tier, "Ranger_T" .. tier)
        local target = new_unit(3200 + tier, "Target_T" .. tier)
        local skill = { skillId = 80005001, name = "Poisoned Blade", level = tier }
        local ok = SkillTimeline.Execute(hero, { target }, skill, skillLua.BuildTimeline(hero, { target }, skill))
        assert_true(ok, "Ranger poison strike execute ok (tier " .. tier .. ")")
        assert_true(BattleBuff.GetBuffStackNumBySubType(target, 850001) == tier, "Poisoned Blade applies poison layers == tier (" .. tier .. ")")
    end
end

-- Test 3: Ranger poison mist (80005003) tag params reflect tier
do
    local skillLua = require("config.skill.skill_80005003")
    for tier = 1, 3 do
        local hero = new_unit(3300 + tier, "RangerMist_T" .. tier)
        local skill = { skillId = 80005003, name = "Poison Mist", level = tier }
        local tl = skillLua.BuildTimeline(hero, {}, skill)
        local f = find_frame(tl, "damage", 30)
        local tags = f and f.tags or {}
        local count = nil
        local layers = nil
        for _, tag in ipairs(tags) do
            if tag.tag == "select_random_enemies" then
                count = tag.param and tag.param.count
            elseif tag.tag == "apply_poison" then
                layers = tag.param and tag.param.layers
            end
        end
        assert_true(count == (3 + math.max(0, tier - 1)), "Poison Mist target count scales (tier " .. tier .. ")")
        local expectLayers = (tier >= 3) and 3 or 2
        assert_true(layers == expectLayers, "Poison Mist poison layers scales (tier " .. tier .. ")")
    end
end

-- Test 4: Ranger poison burst (80005004) tier2+ includes set_targets_all_alive_enemies
do
    local skillLua = require("config.skill.skill_80005004")
    local hero = new_unit(3401, "RangerBurst")
    local tl1 = skillLua.BuildTimeline(hero, {}, { skillId = 80005004, name = "Poison Burst", level = 1 })
    local tl2 = skillLua.BuildTimeline(hero, {}, { skillId = 80005004, name = "Poison Burst", level = 2 })
    local tags1 = (find_frame(tl1, "effect", 42) or {}).tags or {}
    local tags2 = (find_frame(tl2, "effect", 42) or {}).tags or {}
    local hasAll1 = false
    local hasAll2 = false
    for _, tag in ipairs(tags1) do if tag.tag == "set_targets_all_alive_enemies" then hasAll1 = true end end
    for _, tag in ipairs(tags2) do if tag.tag == "set_targets_all_alive_enemies" then hasAll2 = true end end
    assert_true(not hasAll1, "Poison Burst tier1 does not auto-target all enemies")
    assert_true(hasAll2, "Poison Burst tier2 targets all alive enemies")
end

-- Test 5: Sorcerer fire bolt (80007001) burn stacks/turns scale by tier
do
    local SkillTimeline = require("core.skill_timeline")
    local skillLua = require("config.skill.skill_80007001")
    for tier = 1, 3 do
        local hero = new_unit(3500 + tier, "Fire_T" .. tier)
        local target = new_unit(3600 + tier, "Burn_T" .. tier)
        local skill = { skillId = 80007001, name = "Fire Bolt", level = tier }
        local ok = SkillTimeline.Execute(hero, { target }, skill, skillLua.BuildTimeline(hero, { target }, skill))
        assert_true(ok, "Fire Bolt execute ok (tier " .. tier .. ")")
        local stacks = BattleBuff.GetBuffStackNumBySubType(target, 870001)
        assert_true(stacks == ((tier >= 2) and 2 or 1), "Fire Bolt burn stacks scale (tier " .. tier .. ")")
        local burn = require("modules.battle_buff").GetBuff(target, 870001)
        local expectTurns = (tier >= 3) and 3 or 2
        assert_true(burn and burn.duration == expectTurns, "Fire Bolt burn duration scale (tier " .. tier .. ")")
    end
end

-- Test 6: Wizard blizzard (80008004) freeze chance baseChance scales by tier
do
    local skillLua = require("config.skill.skill_80008004")
    local hero = new_unit(3701, "Ice")
    local skill = { skillId = 80008004, name = "Blizzard", level = 3 }
    local tl = skillLua.BuildTimeline(hero, {}, skill)
    local f = find_frame(tl, "damage", 42)
    local tags = f and f.tags or {}
    local baseChance = nil
    for _, tag in ipairs(tags) do
        if tag.tag == "chance_apply_freeze" then
            baseChance = tag.param and tag.param.baseChance
        end
    end
    assert_true(baseChance == 5500, "Blizzard tier3 freeze baseChance == 5500")
end

-- Test 7: Warlock chain lightning (80009003) arc count scales by tier
do
    local skillLua = require("config.skill.skill_80009003")
    local hero = new_unit(3801, "Thunder")
    local targets = {}
    for i = 1, 10 do
        targets[i] = new_unit(3810 + i, "CL_T" .. i)
    end
    local old = BattleSkill.GetChainTargets
    BattleSkill.GetChainTargets = function(_, _, count)
        local out = {}
        for i = 1, count do
            out[i] = targets[i]
        end
        return out
    end
    local tl = skillLua.BuildTimeline(hero, targets, { skillId = 80009003, name = "Chain Lightning", level = 3 })
    BattleSkill.GetChainTargets = old
    local hits = 0
    for _, f in ipairs(tl or {}) do
        if f.op == "chain_damage" then
            hits = hits + 1
        end
    end
    assert_true(hits == 6, "Chain Lightning tier3 creates 6 chain_damage frames")
end

-- Test 8: Paladin aura (80004003) buff duration scales by tier via battle_intent_buff handler
do
    local SkillTimeline = require("core.skill_timeline")
    local BattleFormation = require("modules.battle_formation")
    local skillLua = require("config.skill.skill_80004003")
    local hero = new_unit(3901, "Paladin")
    hero.isLeft = true
    local ally = new_unit(3902, "Ally")
    ally.isLeft = true
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function(src)
        if src == hero then
            return { hero, ally }
        end
        return oldGetFriendTeam(src)
    end
    local skill = { skillId = 80004003, name = "Blessed Charge", level = 3 }
    local ok = SkillTimeline.Execute(hero, { ally }, skill, skillLua.BuildTimeline(hero, { ally }, skill))
    BattleFormation.GetFriendTeam = oldGetFriendTeam
    assert_true(ok, "Paladin aura execute ok")
    local buff = require("modules.battle_buff").GetBuff(ally, 840002)
    assert_true(buff and buff.duration == 4, "Paladin aura duration == 2 + (tier-1) == 4 at tier3")
end

-- Test 9: Cleric strike gains radiant rider from tier2+ (80006001)
do
    local SkillTimeline = require("core.skill_timeline")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local skillLua = require("config.skill.skill_80006001")
    local hero = new_unit(4001, "Cleric")
    local target = new_unit(4002, "Undead")
    local oldApplyDamage = BattleDmgHeal.ApplyDamage
    local spellHits = 0
    BattleDmgHeal.ApplyDamage = function(dst, damage, src, opts)
        if opts and opts.damageKind == "spell" then
            spellHits = spellHits + 1
        end
        return oldApplyDamage(dst, damage, src, opts)
    end
    local skill = { skillId = 80006001, name = "Mace Strike", level = 2 }
    local ok = SkillTimeline.Execute(hero, { target }, skill, skillLua.BuildTimeline(hero, { target }, skill))
    BattleDmgHeal.ApplyDamage = oldApplyDamage
    assert_true(ok, "Cleric strike execute ok")
    assert_true(spellHits == 1, "Cleric strike tier2 adds one radiant rider hit")
end

-- Test 10: Revivify tiers reduce penalty and raise revive hp (80006004)
do
    local SkillTimeline = require("core.skill_timeline")
    local BattleAttribute = require("modules.battle_attribute")
    local BattleFormation = require("modules.battle_formation")
    local skillLua = require("config.skill.skill_80006004")
    local hero = new_unit(4101, "ClericRevive")
    hero.isLeft = true
    local ally = new_unit(4102, "Fallen")
    ally.isLeft = true
    BattleAttribute.SetHpByVal(ally, 0)
    ally.maxHp = 10000
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function(src)
        if src == hero then
            return { hero, ally }
        end
        return oldGetFriendTeam(src)
    end
    local skill = { skillId = 80006004, name = "Revivify", level = 3 }
    local ok = SkillTimeline.Execute(hero, { ally }, skill, skillLua.BuildTimeline(hero, { ally }, skill))
    BattleFormation.GetFriendTeam = oldGetFriendTeam
    assert_true(ok, "Revivify tier3 execute ok")
    assert_true(ally.hp == 3000, "Revivify tier3 restores 30% max hp")
    assert_true(ally.__revivePenalty and ally.__revivePenalty.remainingTurns == 1, "Revivify tier3 penalty lasts 1 turn")
    assert_true(math.abs((ally.__revivePenalty and ally.__revivePenalty.atkMul or 0) - 0.90) < 0.001, "Revivify tier3 atk penalty eased to 0.90")
end

log("All tier scaling assertions passed.")
