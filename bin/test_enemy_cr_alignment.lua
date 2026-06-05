-- 校验 enemies.json：XP 对齐 5e CR 表；同 CR 带内不应出现大幅 combat score 倒挂；CR 1/2 档避免职责堆叠。
local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyData = require("config.enemy_data")
local Exp5e = require("config.roguelike.exp_5e")

local function crNum(cr)
    local a, b = tostring(cr):match("^(%d+)%/(%d+)$")
    if a then
        return tonumber(a) / tonumber(b)
    end
    return tonumber(cr) or 0
end

local function combatScore(hero)
    return (hero.hit or 0) * 2 + (hero.hp or 0) + (hero.ac or 0) + (hero.spellDC or 0) + #(hero.skills or {}) * 2
end

local rows = {}
for _, enemy in ipairs(EnemyData.GetAllEnemies()) do
    local hero = EnemyData.ConvertToHeroData(enemy.ID)
    local expectedXp = Exp5e.GetMonsterXpByCr(enemy.CR)
    assert((enemy.XP or 0) == expectedXp,
        string.format("%s XP=%s expected %s for CR=%s", enemy.EnemyName, tostring(enemy.XP), tostring(expectedXp), enemy.CR))
    local expectedLevel = Exp5e.GetDisplayLevelByCr(enemy.CR)
    assert((enemy.Level or 0) == expectedLevel,
        string.format("%s Level=%s expected %s for CR=%s (see exp_5e.MONSTER_DISPLAY_LEVEL_BY_CR)",
            enemy.EnemyName, tostring(enemy.Level), tostring(expectedLevel), enemy.CR))
    assert(hero.level == EnemyData.GetDisplayLevel(enemy.ID),
        string.format("%s display level drift", enemy.EnemyName))
    rows[#rows + 1] = {
        id = enemy.ID,
        name = enemy.EnemyName,
        role = enemy.Role or "unknown",
        cr = enemy.CR,
        crValue = crNum(enemy.CR),
        score = combatScore(hero),
    }
end

local CR_TIER_MIN_ENEMIES = {
    ["1/8"] = 1,
    ["1/4"] = 1,
    ["1/2"] = 1,
    ["1"] = 1,
}

local halfCrRoles = {}
local tierCounts = {}
for _, row in ipairs(rows) do
    tierCounts[row.cr] = (tierCounts[row.cr] or 0) + 1
    if row.cr == "1/2" then
        halfCrRoles[row.role] = (halfCrRoles[row.role] or 0) + 1
        assert(halfCrRoles[row.role] <= 1,
            string.format("CR 1/2 role overlap: %s shares role %s on 1/2 tier", row.name, row.role))
    end
end

for cr, minCount in pairs(CR_TIER_MIN_ENEMIES) do
    local actual = tierCounts[cr] or 0
    assert(actual >= minCount,
        string.format("CR tier %s: expected at least %d enemies, got %d", cr, minCount, actual))
end

for i = 1, #rows do
    for j = i + 1, #rows do
        local low, high = rows[i], rows[j]
        if low.crValue > high.crValue then
            low, high = high, low
        end
        if high.crValue - low.crValue >= 0.24 and low.score > high.score + 12 then
            error(string.format(
                "CR/score inversion: %s (CR %s, score %d) stronger than %s (CR %s, score %d)",
                low.name, low.cr, low.score, high.name, high.cr, high.score))
        end
    end
end

print("[OK] enemy CR / XP / display level alignment")
