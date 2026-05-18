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
        spellAttack = 999,
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

-- Test 5: Sorcerer fire bolt (80007001) applies one refreshed burn
do
    local SkillTimeline = require("core.skill_timeline")
    local skillLua = require("config.skill.skill_80007001")
    for tier = 1, 3 do
        local hero = new_unit(3500 + tier, "Fire_T" .. tier)
        local target = new_unit(3600 + tier, "Burn_T" .. tier)
        local skill = { skillId = 80007001, name = "Fire Bolt", level = tier }
        local timeline = skillLua.BuildTimeline(hero, { target }, skill)
        local damageFrame = find_frame(timeline, "damage", 24)
        local expectedDice = ({ "1d10", "1d10+1", "1d10+2" })[tier]
        assert_true(damageFrame and damageFrame.damageDice == expectedDice, "Fire Bolt timeline damage dice scales (" .. tier .. ")")
        local ok = SkillTimeline.Execute(hero, { target }, skill, timeline)
        assert_true(ok, "Fire Bolt execute ok (tier " .. tier .. ")")
        local stacks = BattleBuff.GetBuffStackNumBySubType(target, 870001)
        assert_true(stacks == 1, "Fire Bolt burn remains one stack (tier " .. tier .. ")")
        local burn = require("modules.battle_buff").GetBuff(target, 870001)
        assert_true(burn and burn.duration == 2, "Fire Bolt burn refreshes to 2 turns (tier " .. tier .. ")")
    end
end

-- Test 5b: Sorcerer fire bolt resolves via spell attack instead of save
do
    local SkillTimeline = require("core.skill_timeline")
    local BattleFormula = require("core.battle_formula")
    local skillLua = require("config.skill.skill_80007001")
    local hero = new_unit(3651, "SaveFire")
    local target = new_unit(3652, "SaveDummy")
    local oldRollSave = BattleFormula.RollSave
    local oldRollHit = BattleFormula.RollHit
    local saveCalls = 0
    local hitCalls = 0
    local lastAttackBonus = nil
    hero.hit = 1
    hero.spellAttack = 999

    BattleFormula.RollSave = function(...)
        saveCalls = saveCalls + 1
        return oldRollSave(...)
    end
    BattleFormula.RollHit = function(attacker, defender, params)
        hitCalls = hitCalls + 1
        lastAttackBonus = params and params.attackBonus or nil
        return oldRollHit(attacker, defender, params)
    end

    local skill = { skillId = 80007001, name = "Fire Bolt", level = 1 }
    local ok = SkillTimeline.Execute(hero, { target }, skill, skillLua.BuildTimeline(hero, { target }, skill))
    assert_true(ok, "Fire Bolt attack-based execute ok")
    assert_true(hitCalls == 1, "Fire Bolt resolves via attack roll")
    assert_true(saveCalls == 0, "Fire Bolt no longer resolves via save check")
    assert_true(lastAttackBonus == hero.spellAttack, "Fire Bolt uses spellAttack as attack bonus")

    BattleFormula.RollSave = oldRollSave
    BattleFormula.RollHit = oldRollHit
end

-- Test 5c: Wizard frost ray resolves via spell attack instead of save
do
    local SkillTimeline = require("core.skill_timeline")
    local BattleFormula = require("core.battle_formula")
    local skillLua = require("config.skill.skill_80008001")
    local hero = new_unit(3661, "FrostMage")
    local target = new_unit(3662, "FrostDummy")
    local oldRollSave = BattleFormula.RollSave
    local oldRollHit = BattleFormula.RollHit
    local saveCalls = 0
    local hitCalls = 0
    local lastAttackBonus = nil
    hero.hit = 1
    hero.spellAttack = 999

    BattleFormula.RollSave = function(...)
        saveCalls = saveCalls + 1
        return oldRollSave(...)
    end
    BattleFormula.RollHit = function(attacker, defender, params)
        hitCalls = hitCalls + 1
        lastAttackBonus = params and params.attackBonus or nil
        return oldRollHit(attacker, defender, params)
    end

    local skill = { skillId = 80008001, name = "Frost Ray", level = 1 }
    local ok = SkillTimeline.Execute(hero, { target }, skill, skillLua.BuildTimeline(hero, { target }, skill))
    assert_true(ok, "Frost Ray attack-based execute ok")
    assert_true(hitCalls == 1, "Frost Ray resolves via attack roll")
    assert_true(saveCalls == 0, "Frost Ray no longer resolves via save check")
    assert_true(lastAttackBonus == hero.spellAttack, "Frost Ray uses spellAttack as attack bonus")

    BattleFormula.RollSave = oldRollSave
    BattleFormula.RollHit = oldRollHit
end

-- Test 5d: Warlock eldritch blast resolves via spell attack instead of save
do
    local SkillTimeline = require("core.skill_timeline")
    local BattleFormula = require("core.battle_formula")
    local skillLua = require("config.skill.skill_80009001")
    local hero = new_unit(3671, "Warlock")
    local target = new_unit(3672, "BlastDummy")
    local oldRollSave = BattleFormula.RollSave
    local oldRollHit = BattleFormula.RollHit
    local saveCalls = 0
    local hitCalls = 0
    local lastAttackBonus = nil
    hero.hit = 1
    hero.spellAttack = 999

    BattleFormula.RollSave = function(...)
        saveCalls = saveCalls + 1
        return oldRollSave(...)
    end
    BattleFormula.RollHit = function(attacker, defender, params)
        hitCalls = hitCalls + 1
        lastAttackBonus = params and params.attackBonus or nil
        return oldRollHit(attacker, defender, params)
    end

    local skill = { skillId = 80009001, name = "Eldritch Blast", level = 1 }
    local ok = SkillTimeline.Execute(hero, { target }, skill, skillLua.BuildTimeline(hero, { target }, skill))
    assert_true(ok, "Eldritch Blast attack-based execute ok")
    assert_true(hitCalls == 1, "Eldritch Blast resolves via attack roll")
    assert_true(saveCalls == 0, "Eldritch Blast no longer resolves via save check")
    assert_true(lastAttackBonus == hero.spellAttack, "Eldritch Blast uses spellAttack as attack bonus")

    BattleFormula.RollSave = oldRollSave
    BattleFormula.RollHit = oldRollHit
end

-- Test 5e: Wizard frost ray timeline damage dice scales by tier
do
    local skillLua = require("config.skill.skill_80008001")
    for tier = 1, 3 do
        local hero = new_unit(3680 + tier, "FrostTier_" .. tier)
        local target = new_unit(3690 + tier, "FrostTarget_" .. tier)
        local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80008001, name = "Frost Ray", level = tier })
        local damageFrame = find_frame(timeline, "damage", 24)
        local expectedDice = ({ "1d8", "1d8+1", "1d8+2" })[tier]
        assert_true(damageFrame and damageFrame.damageDice == expectedDice, "Frost Ray timeline damage dice scales (" .. tier .. ")")
    end
end

-- Test 5f: Warlock eldritch blast timeline damage dice scales by tier
do
    local skillLua = require("config.skill.skill_80009001")
    for tier = 1, 3 do
        local hero = new_unit(3695 + tier, "BlastTier_" .. tier)
        local target = new_unit(3705 + tier, "BlastTarget_" .. tier)
        local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80009001, name = "Eldritch Blast", level = tier })
        local damageFrame = find_frame(timeline, "damage", 24)
        local expectedDice = ({ "1d10", "1d10+1", "1d10+2" })[tier]
        assert_true(damageFrame and damageFrame.damageDice == expectedDice, "Eldritch Blast timeline damage dice scales (" .. tier .. ")")
    end
end

-- Test 5g: Cleric basic spell damage scales by tier while ally heal stays flat
do
    local ClericBuildPassives = require("skills.cleric_build_passives")
    local oldResolveScaledDamage = BattleSkill.ResolveScaledDamage
    local capturedDice = nil
    BattleSkill.ResolveScaledDamage = function(attacker, defender, opts)
        capturedDice = opts and opts.damageDice or nil
        return oldResolveScaledDamage(attacker, defender, opts)
    end

    for tier = 1, 3 do
        local hero = new_unit(3710 + tier, "Cleric_" .. tier)
        local enemy = new_unit(3720 + tier, "Enemy_" .. tier)
        hero.isLeft = true
        enemy.isLeft = false
        hero.spellDC = 999
        enemy.saveWill = 0
        capturedDice = nil
        local dealt = ClericBuildPassives.PerformBasicSpellAttack(hero, enemy, {
            skillId = 80006011,
            name = "神圣火花",
            level = tier,
        })
        local expectedDice = ({ "1d8", "1d8+1", "1d8+2" })[tier]
        assert_true(dealt > 0, "Cleric basic spell deals damage (tier " .. tier .. ")")
        assert_true(capturedDice == expectedDice, "Cleric basic spell damage dice scales (" .. tier .. ")")
    end

    local healer = new_unit(3731, "ClericHeal")
    local ally = new_unit(3732, "Ally")
    healer.isLeft = true
    ally.isLeft = true
    ally.hp = 50
    ally.maxHp = 100
    local healed = ClericBuildPassives.PerformBasicSpellAttack(healer, ally, {
        skillId = 80006011,
        name = "神圣火花",
        level = 3,
    })
    assert_true(healed > 0, "Cleric ally basic spell heals successfully")
    assert_true(ally.hp > 50 and ally.hp <= ally.maxHp, "Cleric ally heal remains valid")

    BattleSkill.ResolveScaledDamage = oldResolveScaledDamage
end

-- Test 6: Wizard blizzard (80008004) uses frost settlement
do
    local skillLua = require("config.skill.skill_80008004")
    local hero = new_unit(3701, "Ice")
    local skill = { skillId = 80008004, name = "Blizzard", level = 3 }
    local tl = skillLua.BuildTimeline(hero, {}, skill)
    local f = find_frame(tl, "damage", 42)
    local tags = f and f.tags or {}
    local hasSettlement = false
    for _, tag in ipairs(tags) do
        if tag.tag == "wizard_blizzard_settlement" then
            hasSettlement = true
        end
    end
    assert_true(hasSettlement, "Blizzard uses deterministic frost settlement")
end

-- Test 7: Warlock chain lightning (80009003) hits current target plus one extra target
do
    local skillLua = require("config.skill.skill_80009003")
    local hero = new_unit(3801, "Thunder")
    local targets = {}
    for i = 1, 10 do
        targets[i] = new_unit(3810 + i, "CL_T" .. i)
    end
    local BattleFormation = require("modules.battle_formation")
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    BattleFormation.GetEnemyTeam = function(src)
        if src == hero then
            return targets
        end
        return oldGetEnemyTeam(src)
    end
    local tl = skillLua.BuildTimeline(hero, targets, { skillId = 80009003, name = "Chain Lightning", level = 3 })
    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    local hits = 0
    for _, f in ipairs(tl or {}) do
        if f.op == "chain_damage" then
            hits = hits + 1
        end
    end
    assert_true(hits == 2, "Chain Lightning creates 2 chain_damage frames")
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
