-- 敌人技能由 enemies.json 静态模板提供；CR 控强度，Level 仅作显示。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyData = require("config.enemy_data")
local Exp5e = require("config.roguelike.exp_5e")

local function log(msg)
    print(msg)
end

local function assert_true(cond, name)
    if not cond then
        io.stderr:write("ASSERT FAIL: " .. name .. "\n")
        os.exit(1)
    else
        log("ASSERT OK  : " .. name)
    end
end

local function assert_array_equals(actual, expected, name)
    assert_true(type(actual) == "table", name .. " (actual is table)")
    assert_true(#actual == #expected, name .. " (size)")
    for i = 1, #expected do
        assert_true(tonumber(actual[i]) == tonumber(expected[i]), name .. " (index " .. i .. ")")
    end
end

local function skillIdsFromHeroData(enemyId)
    local hero = EnemyData.ConvertToHeroData(enemyId)
    local ids = {}
    for _, entry in ipairs((hero and hero.skills) or {}) do
        ids[#ids + 1] = tonumber(entry.skillId) or 0
    end
    table.sort(ids)
    return ids
end

local function skillTiersFromHeroData(enemyId)
    local hero = EnemyData.ConvertToHeroData(enemyId)
    local tiers = {}
    for _, entry in ipairs((hero and hero.skills) or {}) do
        tiers[#tiers + 1] = tonumber(entry.level) or 1
    end
    table.sort(tiers)
    return tiers
end

local enemies = {
    { id = 910001, classId = 3, monsterType = 0 },
    { id = 910002, classId = 1, monsterType = 0 },
    { id = 910003, classId = 2, monsterType = 0 },
    { id = 910004, classId = 2, monsterType = 1 },
    { id = 910005, classId = 7, monsterType = 1 },
    { id = 910006, classId = 8, monsterType = 2 },
    { id = 910007, classId = 9, monsterType = 2 },
    { id = 910008, classId = 5, monsterType = 0 },
    { id = 910009, classId = 6, monsterType = 0 },
    { id = 910010, classId = 4, monsterType = 0 },
    { id = 910011, classId = 10, monsterType = 0 },
    { id = 910012, classId = 5, monsterType = 0 },
    { id = 910013, classId = 5, monsterType = 0 },
    { id = 910014, classId = 2, monsterType = 0 },
    { id = 910015, classId = 2, monsterType = 1 },
    { id = 910016, classId = 6, monsterType = 1 },
}

for _, spec in ipairs(enemies) do
    local enemy = EnemyData.GetEnemy(spec.id)
    assert_true(enemy ~= nil, "Enemy exists: " .. tostring(spec.id))
    assert_true(tonumber(enemy.Class) == spec.classId, "Enemy class: " .. tostring(spec.id))
    assert_true(type(enemy.SkillIDs) == "table" and #enemy.SkillIDs > 0, "Enemy has static SkillIDs: " .. tostring(spec.id))
    assert_true(type(enemy.CR) == "string" and enemy.CR ~= "", "Enemy has static CR: " .. tostring(spec.id))
    local expectedTier = Exp5e.GetSkillTierByCr(enemy.CR)
    for _, entry in ipairs(enemy.SkillIDs) do
        assert_true((tonumber(entry.level) or 1) == expectedTier,
            string.format("Enemy %d skill %d tier matches CR %s (expected %d)",
                spec.id, tonumber(entry.skillId) or 0, tostring(enemy.CR), expectedTier))
    end
end

local explicitMetaEnemyIds = { 910008, 910009, 910010, 910011, 910012, 910013, 910014, 910015, 910016 }
for _, enemyId in ipairs(explicitMetaEnemyIds) do
    local meta = EnemyData.GetChallengeMeta(enemyId)
    assert_true(meta.role ~= "unknown", "Enemy has explicit challenge role: " .. tostring(enemyId))
    assert_true((tonumber(meta.xp) or 0) > 0, "Enemy has explicit challenge xp: " .. tostring(enemyId))
end

local HP_BASELINE = {
    [910001] = 11,
    [910002] = 8,
    [910003] = 16,
    [910004] = 17,
    [910005] = 30,
    [910006] = 37,
    [910007] = 47,
    [910008] = 13,
    [910009] = 10,
    [910010] = 17,
    [910011] = 30,
    [910012] = 8,
    [910013] = 12,
    [910014] = 20,
    [910015] = 27,
    [910016] = 22,
}

for enemyId, expectedHp in pairs(HP_BASELINE) do
    local hero = EnemyData.ConvertToHeroData(enemyId)
    assert_true(hero ~= nil, "Enemy hero data exists: " .. tostring(enemyId))
    assert_true(hero.hp == expectedHp, string.format("Enemy %d HP matches baseline (%d)", enemyId, expectedHp))
    assert_true(EnemyData.ConvertToHeroData(enemyId, 5).hp == expectedHp, string.format("Enemy %d HP no longer scales with battle level", enemyId))
end

local goblin = EnemyData.ConvertToHeroData(910002, 2)
assert_true(goblin.ac == 13, "Goblin AC matches current monster baseline")
assert_true(goblin.hit == 5, "Goblin hit includes global pacing bonus")
assert_array_equals(skillIdsFromHeroData(910002), { 80001011, 80001101 }, "Goblin uses static skills")

local skeleton = EnemyData.ConvertToHeroData(910004, 4)
assert_true(skeleton.ac == 12, "Skeleton AC matches current monster baseline")
assert_true(skeleton.hit == 5, "Skeleton elite hit includes global pacing bonus")
assert_array_equals(skillIdsFromHeroData(910004), { 80002001, 80002006, 80002104 }, "Skeleton elite uses trimmed frontliner skills")

local darkMage = EnemyData.ConvertToHeroData(910005, 4)
assert_true(darkMage.ac == 12, "DarkMage AC uses current monster baseline")
assert_true(darkMage.hit == 6, "DarkMage hit includes global pacing bonus")
assert_true(darkMage.spellDC == 13, "DarkMage spell DC includes global pacing bonus")
assert_array_equals(skillIdsFromHeroData(910005), { 80007001, 80007002, 80007003, 80007004 }, "DarkMage uses static skills")
assert_array_equals(skillTiersFromHeroData(910005), { 2, 2, 2, 2 }, "DarkMage skills are CR-1 tier")

local iceDemon = EnemyData.ConvertToHeroData(910006, 4)
assert_true(iceDemon.ac == 11, "IceDemon AC matches monster baseline")
assert_true(iceDemon.hit == 5, "IceDemon hit includes global pacing bonus")
assert_true(iceDemon.spellDC == 12, "IceDemon spell DC includes global pacing bonus")
assert_array_equals(skillIdsFromHeroData(910006), { 80008001, 80008002, 80008003 }, "IceDemon boss uses frost ray + nova kit")
assert_array_equals(skillTiersFromHeroData(910006), { 2, 2, 2 }, "IceDemon skills are CR-1 tier")

local thunderLord = EnemyData.ConvertToHeroData(910007, 7)
assert_true(thunderLord.ac == 12, "ThunderLord AC matches current monster baseline")
assert_true(thunderLord.hit == 6, "ThunderLord hit includes global pacing bonus")
assert_true(thunderLord.spellDC == 13, "ThunderLord spell DC includes global pacing bonus")
assert_array_equals(skillIdsFromHeroData(910007), { 80009001, 80009002, 80009003, 80009004 }, "ThunderLord uses static skills")
assert_array_equals(skillTiersFromHeroData(910007), { 3, 3, 3, 3 }, "ThunderLord skills are CR-2 tier")

assert_array_equals(skillIdsFromHeroData(910012), { 80005011, 80005101 }, "GoblinThrower uses static skills")
assert_array_equals(skillIdsFromHeroData(910013), { 80005011, 80005013 }, "SkeletonArcher uses static skills")
assert_array_equals(skillIdsFromHeroData(910011), { 80010011, 80010013, 80010101 }, "Berserker uses static skills")
assert_array_equals(skillTiersFromHeroData(910011), { 2, 2, 2 }, "Berserker skills are CR-1 tier")
assert_array_equals(skillIdsFromHeroData(910014), { 80002001, 80002005, 80002006, 80002104 }, "OrcFighter adds guard stance over orc kit")
assert_array_equals(skillIdsFromHeroData(910015), { 80002001, 80002005, 80002006, 80002104, 80002105 }, "SkeletonCaptain uses static skills")
assert_array_equals(skillTiersFromHeroData(910015), { 2, 2, 2, 2, 2 }, "SkeletonCaptain skills are CR-1 tier")
assert_array_equals(skillIdsFromHeroData(910016), { 80006011, 80006012, 80006015, 80006103 }, "ShadowPriest uses static skills")

log("Enemy skill alignment tests passed.")
