-- 敌人技能由 enemies.json 静态模板提供；CR 控强度，Level 仅作显示。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyData = require("config.enemy_data")

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
end

local explicitMetaEnemyIds = { 910008, 910009, 910010, 910011, 910012, 910013, 910014, 910015, 910016 }
for _, enemyId in ipairs(explicitMetaEnemyIds) do
    local meta = EnemyData.GetChallengeMeta(enemyId)
    assert_true(meta.role ~= "unknown", "Enemy has explicit challenge role: " .. tostring(enemyId))
    assert_true((tonumber(meta.xp) or 0) > 0, "Enemy has explicit challenge xp: " .. tostring(enemyId))
end

local goblin = EnemyData.ConvertToHeroData(910002, 2)
assert_true(goblin.hp == 7, "Goblin HP matches 5e baseline")
assert_true(goblin.ac == 15, "Goblin AC matches 5e baseline")
assert_true(goblin.hit == 4, "Goblin hit matches 5e baseline")
assert_true(EnemyData.ConvertToHeroData(910002, 5).hp == goblin.hp, "Goblin HP no longer scales with battle level")
assert_array_equals(skillIdsFromHeroData(910002), { 80001011, 80001101 }, "Goblin uses static skills")

local skeleton = EnemyData.ConvertToHeroData(910004, 4)
assert_true(skeleton.hp == 13, "Skeleton HP matches 5e baseline")
assert_true(skeleton.ac == 13, "Skeleton AC matches 5e baseline")
assert_true(skeleton.hit == 3, "Skeleton elite hit stays in CR lane")
assert_array_equals(skillIdsFromHeroData(910004), { 80002001, 80002005, 80002006, 80002104, 80002105 }, "Skeleton uses static skills")

local darkMage = EnemyData.ConvertToHeroData(910005, 4)
assert_true(darkMage.hp == 33, "DarkMage HP uses monster baseline")
assert_true(darkMage.ac == 13, "DarkMage AC no longer bottoms out")
assert_true(darkMage.hit == 4, "DarkMage hit no longer uses player-level scaling")
assert_true(darkMage.spellDC == 12, "DarkMage spell DC uses CR proficiency")
assert_true(EnemyData.ConvertToHeroData(910005, 1).hp == darkMage.hp, "DarkMage HP no longer scales with battle level")
assert_array_equals(skillIdsFromHeroData(910005), { 80007001, 80007002, 80007003, 80007004 }, "DarkMage uses static skills")

local thunderLord = EnemyData.ConvertToHeroData(910007, 7)
assert_true(thunderLord.hp == 67, "ThunderLord HP uses monster baseline")
assert_true(thunderLord.ac == 14, "ThunderLord AC matches monster baseline")
assert_true(thunderLord.hit == 5, "ThunderLord hit no longer spikes with battle level")
assert_true(thunderLord.spellDC == 13, "ThunderLord spell DC stays in CR lane")
assert_array_equals(skillIdsFromHeroData(910007), { 80009001, 80009002, 80009003, 80009004 }, "ThunderLord uses static skills")

assert_array_equals(skillIdsFromHeroData(910012), { 80005011, 80005014 }, "GoblinThrower uses static skills")
assert_array_equals(skillIdsFromHeroData(910013), { 80005011, 80005013 }, "SkeletonArcher uses static skills")
assert_array_equals(skillIdsFromHeroData(910014), { 80002001, 80002006, 80002104 }, "OrcFighter uses static skills")
assert_array_equals(skillIdsFromHeroData(910015), { 80002001, 80002005, 80002006, 80002104, 80002105 }, "SkeletonCaptain uses static skills")
assert_array_equals(skillIdsFromHeroData(910016), { 80006011, 80006012, 80006015, 80006103 }, "ShadowPriest uses static skills")

log("Enemy skill alignment tests passed.")
