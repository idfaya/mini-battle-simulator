-- 敌人技能由 Class + 实战等级经 HeroBuild 生成，不再读 enemies.json 的 SkillIDs。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyData = require("config.enemy_data")
local HeroBuild = require("modules.hero_build")

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

local function skillIdsFromBuild(classId, buildLevel)
    local build = HeroBuild.TryCompileBuild(classId, buildLevel, {})
    local ids = {}
    if not build then
        return ids
    end
    for _, entry in ipairs(build.activeSkills or {}) do
        ids[#ids + 1] = tonumber(entry.id) or 0
    end
    for _, entry in ipairs(build.passiveSkills or {}) do
        ids[#ids + 1] = tonumber(entry.id) or 0
    end
    table.sort(ids)
    return ids
end

local function skillIdsFromHeroData(enemyId, battleLevel)
    local hero = EnemyData.ConvertToHeroData(enemyId, battleLevel)
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
}

for _, spec in ipairs(enemies) do
    local enemy = EnemyData.GetEnemy(spec.id)
    assert_true(enemy ~= nil, "Enemy exists: " .. tostring(spec.id))
    assert_true(tonumber(enemy.Class) == spec.classId, "Enemy class: " .. tostring(spec.id))
    assert_true(enemy.SkillIDs == nil, "Enemy has no static SkillIDs: " .. tostring(spec.id))
end

-- 普通怪 Lv1 实战 = Build Lv1
assert_array_equals(skillIdsFromHeroData(910002, 1), skillIdsFromBuild(1, 1), "Goblin Lv1 battle")
assert_array_equals(skillIdsFromHeroData(910001, 1), skillIdsFromBuild(3, 1), "Slime Lv1 battle")

-- 精英 Lv1 实战 = Build Lv2（+1）
assert_array_equals(skillIdsFromHeroData(910004, 1), skillIdsFromBuild(2, 2), "Skeleton elite Lv1 battle")
assert_array_equals(skillIdsFromHeroData(910005, 1), skillIdsFromBuild(7, 2), "DarkMage elite Lv1 battle")

-- Lv1 实战不应出现 Build Lv3 技能（如护卫架势 / 灰烬爆燃）
local skeletonL1 = skillIdsFromHeroData(910004, 1)
for _, skillId in ipairs(skeletonL1) do
    assert_true(skillId ~= 80002005 and skillId ~= 80002105, "Skeleton Lv1 lacks Lv3 guard kit")
end
local darkMageL1 = skillIdsFromHeroData(910005, 1)
for _, skillId in ipairs(darkMageL1) do
    assert_true(skillId ~= 80007003, "DarkMage Lv1 lacks Lv3 ash burst")
end

-- Lv3 普通战可解锁中阶技能
assert_array_equals(skillIdsFromHeroData(910005, 3), skillIdsFromBuild(7, 3), "DarkMage Lv3 battle")

log("Enemy skill alignment tests passed.")
