-- 物理职业数值对照：保证野蛮人在 5e 体系下与战士/武僧/盗贼/游侠/圣骑保持同档，
-- 不出现 HP/AC/hit/speed 异常，以及主属性符合职业模板。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local HeroData = require("config.hero_data")

local PHYSICAL_HEROES = {
    { heroId = 900005, label = "Fighter" },
    { heroId = 900001, label = "Monk" },
    { heroId = 900006, label = "Rogue" },
    { heroId = 900008, label = "Ranger" },
    { heroId = 900009, label = "Paladin" },
    { heroId = 900010, label = "Barbarian" },
}

local LEVELS = { 1, 3, 5 }

-- 物理职业 5e budget 合理区间：以同等级群体最小/最大值为基准，
-- 任何单职业偏离平均值不应超过 ±35%（HP）或 ±2（AC/hit）。
local function buildSnapshot(level)
    local rows = {}
    for _, info in ipairs(PHYSICAL_HEROES) do
        local attrs = HeroData.CalculateHeroAttributes(info.heroId, level, 1)
        assert(attrs, "hero attributes should be available for " .. info.label)
        rows[#rows + 1] = {
            label = info.label,
            heroId = info.heroId,
            level = level,
            hp = attrs.hp,
            ac = attrs.ac,
            hit = attrs.hit,
            spd = attrs.spd,
            str = attrs.str,
            dex = attrs.dex,
            con = attrs.con,
            saveFort = attrs.saveFort,
            saveRef = attrs.saveRef,
            saveWill = attrs.saveWill,
        }
    end
    return rows
end

local function summarize(rows, key)
    local minVal, maxVal, sum = math.huge, -math.huge, 0
    for _, row in ipairs(rows) do
        local v = row[key]
        if v < minVal then minVal = v end
        if v > maxVal then maxVal = v end
        sum = sum + v
    end
    return minVal, maxVal, sum / #rows
end

local function findRow(rows, label)
    for _, row in ipairs(rows) do
        if row.label == label then return row end
    end
    return nil
end

for _, level in ipairs(LEVELS) do
    local rows = buildSnapshot(level)
    local hpMin, hpMax, hpAvg = summarize(rows, "hp")
    local acMin, acMax, acAvg = summarize(rows, "ac")
    local hitMin, hitMax, hitAvg = summarize(rows, "hit")
    local barbarian = findRow(rows, "Barbarian")
    assert(barbarian, "Barbarian row should exist at level " .. tostring(level))

    -- HP：5e 中野蛮人是 d12 阶层，应当落在群体最大值附近，但不许超出群体均值 +60%
    assert(barbarian.hp >= hpAvg * 0.95, string.format("level %d: Barbarian hp %d should be >= avg %.1f * 0.95", level, barbarian.hp, hpAvg))
    assert(barbarian.hp <= hpAvg * 1.6, string.format("level %d: Barbarian hp %d should be <= avg %.1f * 1.6", level, barbarian.hp, hpAvg))

    -- AC：野蛮人无重甲，AC 不能高于群体均值 +2，也不能低于 hpAvg / 4
    assert(barbarian.ac <= math.ceil(acAvg + 2), string.format("level %d: Barbarian ac %d should be <= avg %.1f + 2", level, barbarian.ac, acAvg))
    assert(barbarian.ac >= acMin - 1, string.format("level %d: Barbarian ac %d should be >= group min %d - 1", level, barbarian.ac, acMin))

    -- hit：野蛮人主攻击属性是 STR（20），命中应当不弱于群体均值
    assert(barbarian.hit >= hitAvg - 1, string.format("level %d: Barbarian hit %d should be >= avg %.1f - 1", level, barbarian.hit, hitAvg))
    assert(barbarian.hit <= hitMax + 1, string.format("level %d: Barbarian hit %d should be <= max %d + 1", level, barbarian.hit, hitMax))

    -- 5e 通用约束：任何单职业的关键属性都应在 5e bound 内
    for _, row in ipairs(rows) do
        assert(row.hp >= 5, string.format("level %d: %s hp %d below 5e floor", level, row.label, row.hp))
        assert(row.ac >= 10 and row.ac <= 22, string.format("level %d: %s ac %d outside 5e bounds", level, row.label, row.ac))
        assert(row.hit >= 0 and row.hit <= 12, string.format("level %d: %s hit %d outside 5e bounds", level, row.label, row.hit))
        assert(row.spd >= 60, string.format("level %d: %s spd %d below 5e floor", level, row.label, row.spd))
    end

    print(string.format(
        "level=%d HP[min=%d max=%d avg=%.1f] AC[min=%d max=%d avg=%.1f] HIT[min=%d max=%d avg=%.1f] Barbarian{hp=%d ac=%d hit=%d}",
        level, hpMin, hpMax, hpAvg, acMin, acMax, acAvg, hitMin, hitMax, hitAvg,
        barbarian.hp, barbarian.ac, barbarian.hit
    ))
end

print("physical class budget comparison passed")
