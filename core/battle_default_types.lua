---
--- LEGACY SHIM: BattleDefaultTypesOpt 默认值设置工具
--- 仅用于兼容仍调用 BattleDefaultTypesOpt.SetDefault 的旧配置文件。
--- 新配置不要继续依赖全局注入，待旧配置迁移完成后可删除。
---

-- 深拷贝函数
local function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- 合并默认值到目标表
local function MergeDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == 'table' then
                target[key] = DeepCopy(value)
            else
                target[key] = value
            end
        elseif type(target[key]) == 'table' and type(value) == 'table' then
            -- 递归合并子表
            MergeDefaults(target[key], value)
        end
    end
end

-- BattleDefaultTypesOpt 主对象
BattleDefaultTypesOpt = {
    --- 为配置表设置默认值
    -- @param configTable 目标配置表
    -- @param defaultTable 默认模板表
    -- @param templateName 模板名称（用于日志）
    SetDefault = function(configTable, defaultTable, templateName)
        if not configTable then
            print(string.format("[BattleDefaultTypesOpt] Warning: configTable is nil (template: %s)", tostring(templateName)))
            return
        end
        
        if not defaultTable then
            print(string.format("[BattleDefaultTypesOpt] Warning: defaultTable is nil (template: %s)", tostring(templateName)))
            return
        end
        
        -- 合并默认值
        MergeDefaults(configTable, defaultTable)
        
        -- 可选：记录调试信息
        -- print(string.format("[BattleDefaultTypesOpt] Applied defaults from %s", tostring(templateName)))
    end
}

-- 为了保持兼容性，将 BattleDefaultTypesOpt 设为全局变量
_G.BattleDefaultTypesOpt = BattleDefaultTypesOpt

return BattleDefaultTypesOpt
