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

local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local HeroData = require("config.hero_data")

-- §5 单轨：直接用 GetCanonicalFeatChain 拓扑链路。
local function canonicalSelections(classId, toLevel)
    local lv1Set = {}
    for _, fid in ipairs(ClassBuildProgression.GetLv1FeatIds(classId)) do
        lv1Set[tonumber(fid) or 0] = true
    end
    local selections = {}
    for _, fid in ipairs(ClassBuildProgression.GetCanonicalFeatChain(classId, toLevel)) do
        if not lv1Set[tonumber(fid) or 0] then
            selections[#selections + 1] = fid
        end
    end
    return selections
end
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleMain = require("modules.battle_main")
local MonkBuildPassives = require("skills.monk_build_passives")
local PaladinBuildPassives = require("skills.paladin_build_passives")
local BarbarianBuildPassives = require("skills.barbarian_build_passives")
local RangerBuildPassives = require("skills.ranger_build_passives")
local BuildPassiveCommon = require("skills.build_passive_common")

local function hasSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

local function findSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return entry
        end
    end
    return nil
end

local function new_unit(id, name)
    return {
        id = id,
        instanceId = id,
        name = name,
        hp = 100,
        maxHp = 100,
        isDead = false,
        isAlive = true,
        isLeft = true,
        skills = {},
        skillsConfig = {},
        skillData = nil,
        wpType = 4,
        class = 3,
        classId = 3,
    }
end

do
    local sel = canonicalSelections(3, 5)
    local build = HeroBuild.CompileBuild(3, 5, sel)
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_open_hand), "Monk Lv5 keeps open hand")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_harmonize), "Monk Lv5 grants still mind")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.monk_martial_arts), "Monk Lv5 keeps combo")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk runtime exports basic attack")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_open_hand), "Monk runtime exports mid-tier active skill")
    assert_true((findSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_harmonize) or {}).skillType == 3,
        "Monk runtime exports harmonize as LIMITED")
end

do
    local lv1Build = HeroBuild.CompileBuild(4, 1, {})
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.paladin_basic_attack), "Paladin Lv1 grants basic attack")
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.paladin_lay_on_hands), "Paladin Lv1 grants lay on hands as root skill")
    assert_true(not hasSkill(lv1Build.passiveSkills, SkillRuntimeConfig.Ids.paladin_shelter_prayer), "Paladin Lv1 no longer starts with holy shelter")

    local lv2Build = HeroBuild.CompileBuild(4, 2, canonicalSelections(4, 2))
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).cleanseDebuffs) == true,
        "Paladin Lv2 first child enables lay on hands cleanse")
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).cooldownDelta) == nil,
        "Paladin Lv2 lay on hands mastery does not reduce cooldown on a per-battle limited skill")

    local comboBuild = HeroBuild.CompileBuild(4, 2, { FeatBuildConfig.Ids.b_paladin_combo_basic })
    assert_true(hasSkill(comboBuild.passiveSkills, SkillRuntimeConfig.Ids.paladin_extra_attack),
        "Paladin combo basic grants extra attack passive")
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).bonusHealDice) == nil,
        "Paladin Lv2 first child no longer adds extra heal dice")
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).postHealShield) == nil,
        "Paladin Lv2 first child no longer grants post-heal shield")

    local lv3Build = HeroBuild.CompileBuild(4, 3, canonicalSelections(4, 3))
    assert_true(hasSkill(lv3Build.activeSkills, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "Paladin Lv3 grants smite evil as T1")

    local lv4Build = HeroBuild.CompileBuild(4, 4, canonicalSelections(4, 4))
    assert_true(((lv4Build.skillMods[SkillRuntimeConfig.Ids.paladin_vengeance_smite] or {}).bonusDamageDice) == "1d8",
        "Paladin Lv4 first post-T1 child upgrades smite evil")

    local sel = canonicalSelections(4, 5)
    local build = HeroBuild.CompileBuild(4, 5, sel)
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_basic_attack), "Paladin Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "Paladin Lv5 keeps smite evil")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_lay_on_hands), "Paladin Lv5 grants lay on hands")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.paladin_shelter_prayer), "Paladin Lv5 grants holy shelter as T2")
    assert_true(not hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_guardian_aura), "Paladin Lv5 does not auto-grant guardian aura active")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true((findSkill(runtimeSkills, SkillRuntimeConfig.Ids.paladin_lay_on_hands) or {}).skillType == 3,
        "Paladin runtime exports lay on hands as LIMITED")
end

do
    local paladin = new_unit(9051, "AuraPaladin")
    local ally = new_unit(9052, "AuraAlly")
    paladin.class = 4
    ally.class = 2
    paladin.buildState = { skillMods = {}, classMods = { paladinAuraSaveBonus = 1 } }
    paladin.skills = {
        { skillId = SkillRuntimeConfig.Ids.paladin_shelter_prayer },
    }
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function()
        return { paladin, ally }
    end
    assert_true(PaladinBuildPassives.GetAuraAcBonus(ally, nil) >= 1, "paladin aura grants AC bonus to ally")
    assert_true(PaladinBuildPassives.GetAuraSaveBonus(ally, "will") >= 1, "paladin aura grants saving throw bonus after aura mastery mods")
    BattleFormation.GetFriendTeam = oldGetFriendTeam
end

do
    local recoveryBuild = HeroBuild.CompileBuild(10, 2, { FeatBuildConfig.Ids.b_barbarian_rage_recovery })
    assert_true(((recoveryBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_rage] or {}).onRageEnterHealDice) == "1d6",
        "Barbarian rage recovery heals on berserk entry")
    assert_true(((recoveryBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_rage] or {}).onRageEnterTempHpDice) == nil,
        "Barbarian rage recovery no longer grants temp hp")

    local cleaveSel = canonicalSelections(10, 6)
    cleaveSel[#cleaveSel + 1] = FeatBuildConfig.Ids.j_barbarian_heavy_master
    local cleaveBuild = HeroBuild.CompileBuild(10, 7, cleaveSel)
    assert_true(((cleaveBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_heavy_strike] or {}).acPenaltyDelta) == -1,
        "Barbarian heavy mastery reduces self ac penalty")
    assert_true(((cleaveBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_heavy_strike] or {}).frontRowSplitTargets) == 2,
        "Barbarian cleave enables front-row split")

    local capstoneSel = canonicalSelections(10, 6)
    capstoneSel[#capstoneSel + 1] = FeatBuildConfig.Ids.b_barbarian_heavy_echo
    capstoneSel[#capstoneSel + 1] = FeatBuildConfig.Ids.j_barbarian_heavy_master
    capstoneSel[#capstoneSel + 1] = FeatBuildConfig.Ids.c_barbarian_strike_master
    local capstoneBuild = HeroBuild.CompileBuild(10, 10, capstoneSel)
    assert_true(((capstoneBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_heavy_strike] or {}).frontRowSplitDelta) == 1,
        "Barbarian cleave capstone adds one more split target")
    assert_true(not FeatBuildConfig.GetFeat(FeatBuildConfig.Ids.c_barbarian_rage_master),
        "Barbarian rage capstone removed from feat table")

    local hero = { id = 9401, instanceId = 9401, name = "RageRecoveryHero", hp = 20, maxHp = 40, isDead = false, isAlive = true,
        buildState = recoveryBuild, passiveRuntime = {}, skills = { { skillId = SkillRuntimeConfig.Ids.barbarian_rage } },
        skillData = { skillInstances = { [SkillRuntimeConfig.Ids.barbarian_rage] = true } } }
    local oldRollDice = BuildPassiveCommon.RollDice
    local healed = 0
    BuildPassiveCommon.RollDice = function(expr)
        if expr == "1d6" then
            return 4
        end
        return oldRollDice(expr)
    end
    BuildPassiveCommon.ApplyHeal = function(unit, amount)
        unit.hp = math.min(unit.maxHp, (tonumber(unit.hp) or 0) + amount)
        healed = amount
    end
    assert_true(BarbarianBuildPassives.TryActivateBerserk(hero), "Barbarian rage recovery triggers berserk")
    assert_true(healed == 4, "Barbarian rage recovery heals on berserk entry")
    BuildPassiveCommon.RollDice = oldRollDice
end

do
    local sel = canonicalSelections(5, 5)
    local build = HeroBuild.CompileBuild(5, 5, sel)
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_basic_attack), "Ranger Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_hunter_shot), "Ranger Lv5 grants hunting guide")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_hunter_mastery), "Ranger Lv5 grants arrow rain active")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_hunter_mark), "Ranger Lv5 keeps hunter mark")
end

do
    local monkHero = HeroData.ConvertToHeroData(900001, 5, 1, {
        buildFeatIds = canonicalSelections(3, 5),
    })
    assert_true(monkHero and monkHero.buildState ~= nil, "HeroData generic build compile works for monk")
    assert_true(hasSkill(monkHero.skillsConfig, SkillRuntimeConfig.Ids.monk_basic_attack), "HeroData exports monk build basic attack")

    local paladinHero = HeroData.ConvertToHeroData(900009, 5, 1, {
        buildFeatIds = canonicalSelections(4, 5),
    })
    assert_true(paladinHero and paladinHero.buildState ~= nil, "HeroData generic build compile works for paladin")
    assert_true(hasSkill(paladinHero.skillsConfig, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "HeroData exports paladin mid-tier active")

    local rangerHero = HeroData.ConvertToHeroData(900008, 5, 1, {
        buildFeatIds = canonicalSelections(5, 5),
    })
    assert_true(rangerHero and rangerHero.buildState ~= nil, "HeroData generic build compile works for ranger")
    assert_true(hasSkill(rangerHero.skillsConfig, SkillRuntimeConfig.Ids.ranger_hunter_shot), "HeroData exports ranger build active")
    BattleFormation.OnFinal()
    local rangerEnemy = new_unit(9402, "RangerEnemy")
    rangerEnemy.class = 8
    rangerEnemy.classId = 8
    rangerEnemy.wpType = 4
    rangerEnemy.isLeft = false
    BattleFormation.Init({
        teamLeft = { rangerHero },
        teamRight = { rangerEnemy },
    })
    local teamLeft = BattleFormation.GetTeams()
    local battleRanger = teamLeft[1]
    BattleSkill.Init(battleRanger, battleRanger.skillsConfig)
    local rangerSelectedSkill = BattleMain.DebugSelectAvailableSkill(battleRanger)
    assert_true(rangerSelectedSkill ~= nil, "Ranger has an auto-selected action")
    assert_true(rangerSelectedSkill.skillId ~= SkillRuntimeConfig.Ids.ranger_hunter_mark,
        "Ranger auto action does not select passive hunter mark")
    BattleFormation.OnFinal()
end

do
    BattleFormation.OnFinal()

    local fighter = new_unit(9101, "DecisionFighter")
    local enemy = new_unit(9102, "FighterEnemy")
    fighter.class = 2
    fighter.classId = 2
    fighter.wpType = 1
    enemy.class = 2
    enemy.classId = 2
    enemy.wpType = 1
    enemy.isLeft = false
    fighter.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(2, 5, canonicalSelections(2, 5)))

    BattleFormation.Init({
        teamLeft = { fighter },
        teamRight = { enemy },
    })

    local battleFighter = BattleFormation.GetTeams()[1]
    BattleSkill.Init(battleFighter, battleFighter.skillsConfig)
    battleFighter.hp = 50
    battleFighter.maxHp = 100
    local injuredFighterSkill = BattleMain.DebugSelectAvailableSkill(battleFighter)
    assert_true(injuredFighterSkill and injuredFighterSkill.skillId == SkillRuntimeConfig.Ids.fighter_second_wind_action,
        "Fighter uses second wind automatically at half HP")

    battleFighter.hp = 100
    assert_true(BattleMain.QueueUltimate(battleFighter.instanceId), "Fighter can queue limited skill manually")
    local queuedAtFullHp = BattleMain.DebugSelectAvailableSkill(battleFighter)
    assert_true(queuedAtFullHp and queuedAtFullHp.skillId ~= SkillRuntimeConfig.Ids.fighter_second_wind_action,
        "Queued limited skill is not consumed when fighter still fails self-heal gate")
    assert_true(BattleMain.HasQueuedUltimate(battleFighter.instanceId),
        "Queued limited skill is preserved when no valid limited candidate exists")
    battleFighter.hp = 50
    local queuedAtHalfHp = BattleMain.DebugSelectAvailableSkill(battleFighter)
    assert_true(queuedAtHalfHp and queuedAtHalfHp.skillId == SkillRuntimeConfig.Ids.fighter_second_wind_action,
        "Queued limited skill fires once fighter becomes eligible")
    assert_true(not BattleMain.HasQueuedUltimate(battleFighter.instanceId),
        "Queued limited skill clears only after a valid limited candidate is selected")

    BattleFormation.OnFinal()

    local monk = new_unit(9201, "DecisionMonk")
    local ally = new_unit(9202, "MonkAlly")
    local enemy = new_unit(9203, "EnemyTarget")
    ally.class = 2
    ally.classId = 2
    ally.wpType = 1
    enemy.class = 2
    enemy.classId = 2
    enemy.wpType = 1
    enemy.isLeft = false
    monk.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(3, 5, canonicalSelections(3, 5)))

    BattleFormation.Init({
        teamLeft = { monk, ally },
        teamRight = { enemy },
    })

    local battleMonk = BattleFormation.FindHeroByCampAndPos(true, 4)
    BattleSkill.Init(battleMonk, battleMonk.skillsConfig)

    battleMonk.hp = 100
    battleMonk.maxHp = 100
    local fullHpSkill = BattleMain.DebugSelectAvailableSkill(battleMonk)
    assert_true(fullHpSkill and fullHpSkill.skillId == SkillRuntimeConfig.Ids.monk_open_hand,
        "Monk does not spend harmonize at full HP")

    battleMonk.hp = 50
    local injuredSkill = BattleMain.DebugSelectAvailableSkill(battleMonk)
    assert_true(injuredSkill and injuredSkill.skillId == SkillRuntimeConfig.Ids.monk_harmonize,
        "Monk uses harmonize automatically at half HP")

    BattleFormation.OnFinal()
end

do
    BattleFormation.OnFinal()

    local paladin = new_unit(9301, "DecisionPaladin")
    local ally = new_unit(9302, "PaladinAlly")
    local enemy = new_unit(9303, "PaladinEnemy")
    paladin.class = 4
    paladin.classId = 4
    paladin.wpType = 1
    ally.class = 2
    ally.classId = 2
    ally.wpType = 1
    enemy.class = 2
    enemy.classId = 2
    enemy.wpType = 1
    enemy.isLeft = false
    paladin.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(4, 5, canonicalSelections(4, 5)))

    BattleFormation.Init({
        teamLeft = { paladin, ally },
        teamRight = { enemy },
    })

    local teamLeft = BattleFormation.GetTeams()
    local battlePaladin = teamLeft[1]
    local battleAlly = teamLeft[2]
    BattleSkill.Init(battlePaladin, battlePaladin.skillsConfig)
    battlePaladin.hp = 99
    battlePaladin.maxHp = 100
    battleAlly.hp = 100
    battleAlly.maxHp = 100
    local minorInjurySkill = BattleMain.DebugSelectAvailableSkill(battlePaladin)
    assert_true(minorInjurySkill and minorInjurySkill.skillId ~= SkillRuntimeConfig.Ids.paladin_lay_on_hands,
        "Paladin does not spend lay on hands when only 1 HP is missing")

    battlePaladin.hp = 51
    battlePaladin.maxHp = 100
    battleAlly.hp = 100
    battleAlly.maxHp = 100
    local aboveHalfSkill = BattleMain.DebugSelectAvailableSkill(battlePaladin)
    assert_true(aboveHalfSkill and aboveHalfSkill.skillId ~= SkillRuntimeConfig.Ids.paladin_lay_on_hands,
        "Paladin does not spend lay on hands above half HP")

    battlePaladin.hp = 50
    battlePaladin.maxHp = 100
    battleAlly.hp = 28
    battleAlly.maxHp = 100
    local emergencySkill, emergencyTargets = BattleMain.DebugSelectAvailableSkill(battlePaladin)
    assert_true(emergencySkill and emergencySkill.skillId == SkillRuntimeConfig.Ids.paladin_lay_on_hands,
        "Paladin uses lay on hands automatically at half HP")
    assert_true(#(emergencyTargets or {}) == 1 and emergencyTargets[1] == battlePaladin,
        "Paladin targets self with lay on hands when self is at half HP")

    BattleFormation.OnFinal()
end

do
    local dualLimitedHero = new_unit(9351, "DualLimitedHero")
    local fighterRuntime = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(2, 5, canonicalSelections(2, 5)))
    local paladinRuntime = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(4, 5, canonicalSelections(4, 5)))
    dualLimitedHero.skillsConfig = {
        findSkill(fighterRuntime, SkillRuntimeConfig.Ids.fighter_second_wind_action),
        findSkill(paladinRuntime, SkillRuntimeConfig.Ids.paladin_lay_on_hands),
    }
    BattleSkill.Init(dualLimitedHero, dualLimitedHero.skillsConfig)
    local fighterCharges, fighterMax = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.fighter_second_wind_action)
    local paladinCharges, paladinMax = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.paladin_lay_on_hands)
    assert_true(fighterCharges == 1 and fighterMax == 1, "fighter limited skill starts with its own charge")
    assert_true(paladinCharges == 1 and paladinMax == 1, "paladin limited skill starts with its own charge")
    assert_true(BattleSkill.ConsumeLimitedSkillCharge(dualLimitedHero, SkillRuntimeConfig.Ids.fighter_second_wind_action),
        "Consuming one limited skill charge succeeds")
    fighterCharges = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.fighter_second_wind_action)
    paladinCharges = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.paladin_lay_on_hands)
    assert_true(fighterCharges == 0, "Consumed limited skill charge is tracked per skill")
    assert_true(paladinCharges == 1, "Other limited skill keeps its own remaining charge")
end

do
    -- 构建链顺序稳定性：合法 selectedFeatIds 反序输入也应稳定通过。
    local sel = canonicalSelections(3, 5)
    local reversed = {}
    for i = #sel, 1, -1 do
        reversed[#reversed + 1] = sel[i]
    end
    local ok = pcall(HeroBuild.CompileBuild, 3, 5, reversed)
    assert_true(ok, "CompileBuild stable when selectedFeatIds reversed")
end

do
    -- 多父 capstone AND 语义：基于 canonical chain (lv10) 校验
    -- requireAllPrerequisites=true 的 capstone 在缺任一父节点时必须被拒绝。
    local andCapstoneCases = {
        -- (class, expectedParentCount) — 用 canonical lv10 链路覆盖完整选包；
        -- 仅纳入 capstone.requireAllPrerequisites=true 的职业。
        { class = 1,  parents = 4 }, -- c_rogue_deadly_sneak
        { class = 3,  parents = 2 }, -- c_monk_combo_grandmaster
        { class = 5,  parents = 3 }, -- c_ranger_mark_master
        { class = 9,  parents = 3 }, -- c_warlock_chain_grandmaster
        { class = 10, parents = 3 }, -- c_barbarian_strike_master
    }
    for _, case in ipairs(andCapstoneCases) do
        local fullSel = canonicalSelections(case.class, 10)
        -- canonical 链尾节点必须是 isCapstone=true 且 requireAllPrerequisites=true。
        local capstoneId = fullSel[#fullSel]
        local capstone = FeatBuildConfig.GetFeat(capstoneId)
        assert_true(capstone and capstone.isCapstone == true,
            string.format("class %d canonical chain ends with capstone", case.class))
        assert_true(capstone.requireAllPrerequisites == true,
            string.format("class %d capstone %s marked requireAllPrerequisites",
                case.class, tostring(capstoneId)))
        local parents = capstone.prerequisites or {}
        assert_true(#parents == case.parents,
            string.format("class %d capstone has %d parents", case.class, case.parents))
        -- 完整 canonical 选包应通过。
        local okFull = pcall(HeroBuild.CompileBuild, case.class, 10, fullSel)
        assert_true(okFull,
            string.format("class %d canonical chain accepts capstone", case.class))
        -- 去掉任一可选父节点应拒绝（轮询所有父节点，逐个剔除验证 AND 语义）。
        -- Lv1 fixed feat 由 classes.json 自动注入，不能通过剔除 selectedFeatIds 移除，跳过。
        local lv1Set = {}
        for _, fid in ipairs(ClassBuildProgression.GetLv1FeatIds(case.class)) do
            lv1Set[tonumber(fid) or 0] = true
        end
        local prunableCount = 0
        for _, parentId in ipairs(parents) do
            if not lv1Set[tonumber(parentId) or 0] then
                prunableCount = prunableCount + 1
                local pruned = {}
                for _, fid in ipairs(fullSel) do
                    if tonumber(fid) ~= tonumber(parentId) then
                        pruned[#pruned + 1] = fid
                    end
                end
                local okMissing = pcall(HeroBuild.CompileBuild, case.class, 10, pruned)
                assert_true(not okMissing,
                    string.format("class %d capstone rejects build missing parent %s",
                        case.class, tostring(parentId)))
            end
        end
        assert_true(prunableCount > 0,
            string.format("class %d capstone has at least one non-Lv1 parent", case.class))
    end
end

log("Three-class build pipeline tests passed.")
