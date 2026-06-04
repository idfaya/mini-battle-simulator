-- Feat 树基础设施 mod 字段统一读取入口。
-- 设计文档：design/roguelike_feat_skill_fill_sheet.md §6
--
-- 字段读取来源：
--   * hero.buildState.skillMods[skillId][key] —— 技能级 mod（cooldownDelta/bonusHit 等多数字段）。
--   * hero.buildState.classMods[key]          —— 职业级 mod（如 markSlotMax）。
--
-- 容错约定：
--   * hero / buildState / skillMods / classMods 任一缺失，按 default 返回。
--   * 数值字段 default 为 nil 时返回 0；若调用方传了 default 则用调用方的值。
--   * 布尔字段使用严格相等 == true 判断。
local FeatModHelper = {}

local function getBuildState(hero)
    if type(hero) ~= "table" then
        return nil
    end
    local buildState = hero.buildState
    if type(buildState) ~= "table" then
        return nil
    end
    return buildState
end

local function resolveNumericDefault(default)
    if default == nil then
        return 0
    end
    return default
end

---@param hero table|nil
---@param skillId integer|string|nil
---@param key string
---@param default any|nil
---@return any
function FeatModHelper.GetSkillMod(hero, skillId, key, default)
    local fallback = resolveNumericDefault(default)
    local buildState = getBuildState(hero)
    if not buildState then
        return fallback
    end
    if type(buildState.skillMods) ~= "table" then
        return fallback
    end
    local id = tonumber(skillId)
    if not id then
        return fallback
    end
    local mods = buildState.skillMods[id]
    if type(mods) ~= "table" then
        return fallback
    end
    local value = mods[key]
    if value == nil then
        return fallback
    end
    local num = tonumber(value)
    if num ~= nil then
        return num
    end
    if default == nil then
        return value
    end
    return fallback
end

---@param hero table|nil
---@param key string
---@param default any|nil
---@return any
function FeatModHelper.GetClassMod(hero, key, default)
    local fallback = resolveNumericDefault(default)
    local buildState = getBuildState(hero)
    if not buildState then
        return fallback
    end
    if type(buildState.classMods) ~= "table" then
        return fallback
    end
    local value = buildState.classMods[key]
    if value == nil then
        return fallback
    end
    local num = tonumber(value)
    if num ~= nil then
        return num
    end
    return fallback
end

---@param hero table|nil
---@param skillId integer|string|nil
---@param key string
---@return boolean
function FeatModHelper.HasFlag(hero, skillId, key)
    local buildState = getBuildState(hero)
    if not buildState then
        return false
    end
    if type(buildState.skillMods) ~= "table" then
        return false
    end
    local id = tonumber(skillId)
    if not id then
        return false
    end
    local mods = buildState.skillMods[id]
    if type(mods) ~= "table" then
        return false
    end
    return mods[key] == true
end

return FeatModHelper
