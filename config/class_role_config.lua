---@class ClassRoleEntry
---@field streamId string
---@field name string
---@field icon string
---@field isMelee boolean
---@field preferRow string

---@class ClassRoleConfigModule
---@field ROLES table<integer, ClassRoleEntry>
---@field GetRole fun(classId: integer): ClassRoleEntry|nil
---@field GetIcon fun(classId: integer): string
---@field GetName fun(classId: integer): string
---@field IsMelee fun(classId: integer): boolean
---@field PreferFrontRow fun(classId: integer): boolean

---@type ClassRoleConfigModule
local ClassRoleConfig = {}

-- classId is treated as "role/class id" used by balance/UI.
-- We keep numeric ids stable for now, but display them as 5e base-class flavored labels.
-- 1..5: 前排（近战）；6..9: 后排（法术/辅助）
---@type table<integer, ClassRoleEntry>
ClassRoleConfig.ROLES = {
    [1] = { streamId = "Rogue", name = "盗贼", icon = "🗡️", isMelee = true, preferRow = "front" },
    [2] = { streamId = "Fighter", name = "战士", icon = "🛡️", isMelee = true, preferRow = "front" },
    [3] = { streamId = "Monk", name = "武僧", icon = "⚡", isMelee = true, preferRow = "front" },
    [4] = { streamId = "Paladin", name = "圣武士", icon = "✨", isMelee = true, preferRow = "front" },
    [5] = { streamId = "Ranger", name = "游侠", icon = "🏹", isMelee = false, preferRow = "back" },
    [6] = { streamId = "Cleric", name = "牧师", icon = "💚", isMelee = false, preferRow = "back" },
    [7] = { streamId = "Sorcerer", name = "术士(火)", icon = "🔥", isMelee = false, preferRow = "back" },
    [8] = { streamId = "Wizard", name = "法师(冰)", icon = "❄️", isMelee = false, preferRow = "back" },
    [9] = { streamId = "Warlock", name = "邪术师(雷)", icon = "🌩️", isMelee = false, preferRow = "back" },
}

function ClassRoleConfig.GetRole(classId)
    local id = tonumber(classId) or 0
    return ClassRoleConfig.ROLES[id]
end

function ClassRoleConfig.GetIcon(classId)
    local role = ClassRoleConfig.GetRole(classId)
    return role and role.icon or "?"
end

function ClassRoleConfig.GetName(classId)
    local role = ClassRoleConfig.GetRole(classId)
    if not role then
        return "未知"
    end
    return role.name
end

function ClassRoleConfig.IsMelee(classId)
    local role = ClassRoleConfig.GetRole(classId)
    return role and role.isMelee == true
end

function ClassRoleConfig.PreferFrontRow(classId)
    local role = ClassRoleConfig.GetRole(classId)
    return role and role.preferRow == "front"
end

return ClassRoleConfig
