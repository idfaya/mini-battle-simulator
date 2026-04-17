local ClassRoleConfig = {}

-- classId is treated as "stream id" (九流派) and may change at runtime (转职).
-- 1..5: 前排流派（近战）；6..9: 后排流派（法术/辅助）
ClassRoleConfig.ROLES = {
    [1] = { streamId = "A1", name = "追击流", icon = "⚔️", isMelee = true, preferRow = "front" },
    [2] = { streamId = "D1", name = "格挡流", icon = "🛡️", isMelee = true, preferRow = "front" },
    [3] = { streamId = "S1", name = "连击流", icon = "⚡", isMelee = true, preferRow = "front" },
    [4] = { streamId = "B1", name = "战意流", icon = "✨", isMelee = true, preferRow = "front" },
    [5] = { streamId = "T1", name = "毒爆流", icon = "🔮", isMelee = true, preferRow = "front" },
    [6] = { streamId = "H1", name = "圣光流", icon = "💚", isMelee = false, preferRow = "back" },
    [7] = { streamId = "M1", name = "火法", icon = "🔥", isMelee = false, preferRow = "back" },
    [8] = { streamId = "M2", name = "冰法", icon = "❄️", isMelee = false, preferRow = "back" },
    [9] = { streamId = "M3", name = "雷法", icon = "🌩️", isMelee = false, preferRow = "back" },
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
        return "Unknown"
    end
    return string.format("%s %s", role.streamId, role.name)
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
