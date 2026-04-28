-- Class 关键等级固有解锁（5e Class Table 风味）。
-- 每次升级固有效果（属性曲线）已由 hero_data.lua 的 HERO_ROLE_TEMPLATES 驱动，
-- 这里只描述"仪式感等级"的额外固有解锁：例如 Lv5 学会流派主动技能、Lv10 解锁大招进阶。
-- 固有解锁不占用 3 选 1 名额，自动生效；feat 选择仍在其上叠加。

---@class ClassLevelGrantEntry
---@field unlockSkills integer[]|nil
---@field upgradeSkills table<integer, integer>|nil  -- skillId -> skillLevel
---@field statBonus table<string, integer>|nil

---@alias ClassLevelGrantTable table<integer, ClassLevelGrantEntry>

local ClassLevelGrants = {}

---@type table<integer, ClassLevelGrantTable>
local GRANTS = {
    -- Class 2 战士/Tank：Lv5 解锁主动进阶，Lv10 解锁大招。
    [2] = {
        [5] = {
            unlockSkills = { 80002003 },
            statBonus = { hit = 1 },
        },
        [10] = {
            upgradeSkills = { [80002004] = 3 },
            statBonus = { maxHp = 10, ac = 1 },
        },
    },
    -- 其他 Class 待填，先走默认（无固有解锁）。
}

---@param classId integer
---@param level integer
---@return ClassLevelGrantEntry|nil
function ClassLevelGrants.GetGrant(classId, level)
    local classTable = GRANTS[tonumber(classId) or 0]
    if not classTable then
        return nil
    end
    return classTable[tonumber(level) or 0]
end

---@param classId integer
---@param fromLevel integer
---@param toLevel integer
---@return ClassLevelGrantEntry[]
function ClassLevelGrants.GetGrantsInRange(classId, fromLevel, toLevel)
    local classTable = GRANTS[tonumber(classId) or 0]
    if not classTable then
        return {}
    end
    local lo = math.max(1, tonumber(fromLevel) or 1)
    local hi = math.max(lo, tonumber(toLevel) or lo)
    local result = {}
    for lv = lo, hi do
        local grant = classTable[lv]
        if grant then
            result[#result + 1] = grant
        end
    end
    return result
end

return ClassLevelGrants
