-- 技能执行器
-- 解析技能Lua数据并执行技能效果（伤害、Buff等）

local SkillExecutor = {}

-- 本地日志函数
local function Log(msg)
    print("[SkillExecutor] " .. msg)
end

local function LogError(msg)
    print("[SkillExecutor] [ERROR] " .. msg)
end

--- 原工程使用的字符串转表函数
-- 技能数据使用Lua表字面量格式，不是JSON格式
local function StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return nil
    end
    -- 移除可能的前导空格
    str = str:match("^%s*(.-)%s*$")
    if str == "" then
        return nil
    end
    local success, result = pcall(function()
        return load("return " .. str)()
    end)
    if success then
        return result
    else
        LogError("StrToTable解析失败: " .. tostring(result) .. ", 字符串: " .. str:sub(1, 50))
        return nil
    end
end

--- 解析技能数据中的字符串
local function ParseSkillData(dataStr)
    if not dataStr or dataStr == "" then
        return nil
    end
    return StrToTable(dataStr)
end

--- 从技能Lua数据中提取关键帧效果
function SkillExecutor.ExtractSkillEffects(skillData)
    local effects = {
        damages = {},
        buffs = {},
        heals = {},
        spells = {}
    }
    
    if not skillData or not skillData.actData then
        return effects
    end
    
    -- 遍历所有actData
    for _, act in ipairs(skillData.actData) do
        if act.keyFrameDatas then
            for _, keyFrame in ipairs(act.keyFrameDatas) do
                local dataType = keyFrame.datatype
                local data = ParseSkillData(keyFrame.data)
                
                if data then
                    if dataType == "DWCommon.DamageData" then
                        -- 伤害数据
                        table.insert(effects.damages, {
                            attackType = data.attackType or 1,
                            damageType = data.damageType or 1,
                            hitType = data.hitType or 0,
                            cSVSkillAssociate = data.cSVSkillAssociate or 1,
                            triggerTime = keyFrame.TriggerS or 0
                        })
                    elseif dataType == "DWCommon.LaunchBuff" then
                        -- Buff数据
                        table.insert(effects.buffs, {
                            buffId = data.AssociateBuff or 0,
                            triggerTime = keyFrame.TriggerS or 0
                        })
                    elseif dataType == "DWCommon.HealData" then
                        -- 治疗数据
                        table.insert(effects.heals, {
                            healValue = data.HealValue or 0,
                            healType = data.HealType or 1,
                            triggerTime = keyFrame.TriggerS or 0
                        })
                    elseif dataType == "DWCommon.LaunchSpell" then
                        -- 法术/技能数据
                        table.insert(effects.spells, {
                            spellId = data.SpellID or 0,
                            triggerTime = keyFrame.TriggerS or 0,
                            targetsSelections = data.targetsSelections
                        })
                    end
                end
            end
        end
    end
    
    return effects
end

--- 执行技能伤害
function SkillExecutor.ExecuteDamage(hero, targets, damageConfig, skillParam)
    if not targets or #targets == 0 then
        return false
    end
    
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local BattleFormula = require("core.battle_formula")
    
    -- 从skillParam获取伤害倍率
    local damageRate = 10000  -- 默认100%
    if skillParam and #skillParam > 0 then
        damageRate = skillParam[1] or 10000
    end
    
    Log(string.format("[SkillExecutor.ExecuteDamage] %s 对 %d 个目标造成伤害 (倍率:%d)", 
        hero.name or "Unknown", #targets, damageRate))
    
    for _, target in ipairs(targets) do
        if target.isAlive and not target.isDead then
            -- 使用战斗公式计算最终伤害
            -- CalcDamage返回 { damage, isCrit, isBlock }
            local damageResult = BattleFormula.CalcDamage(hero, target, damageRate)
            local finalDamage = damageResult.damage or 0
            
            -- 应用伤害
            if finalDamage > 0 then
                BattleDmgHeal.ApplyDamage(target, finalDamage, hero)
                Log(string.format("  -> %s 受到 %d 点伤害", target.name or "Unknown", finalDamage))
            end
        end
    end
    
    return true
end

--- 执行技能Buff
function SkillExecutor.ExecuteBuff(hero, targets, buffConfig)
    if not targets or #targets == 0 then
        return false
    end
    
    local BattleBuff = require("modules.battle_buff")
    local BuffConfig = require("config.buff_config")
    
    Log(string.format("[SkillExecutor.ExecuteBuff] %s 对 %d 个目标施加Buff", 
        hero.name or "Unknown", #targets))
    
    for _, target in ipairs(targets) do
        if target.isAlive and not target.isDead then
            -- 添加Buff
            if buffConfig.buffId and buffConfig.buffId > 0 then
                -- 从Buff配置表获取完整配置
                local buffConfigData = BuffConfig.ConvertToBattleBuffConfig(buffConfig.buffId)
                
                if buffConfigData then
                    BattleBuff.Add(hero, target, buffConfigData)
                    Log(string.format("  -> %s 获得Buff [%s] ID=%d", 
                        target.name or "Unknown", buffConfigData.name, buffConfig.buffId))
                else
                    -- 回退到默认配置
                    local defaultConfig = {
                        buffId = buffConfig.buffId,
                        stackNum = 1,
                        duration = 3,
                    }
                    BattleBuff.Add(hero, target, defaultConfig)
                    Log(string.format("  -> %s 获得Buff %d (使用默认配置)", 
                        target.name or "Unknown", buffConfig.buffId))
                end
            end
        end
    end
    
    return true
end

--- 执行技能治疗
function SkillExecutor.ExecuteHeal(hero, targets, healConfig)
    if not targets or #targets == 0 then
        return false
    end
    
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    
    Log(string.format("[SkillExecutor.ExecuteHeal] %s 治疗 %d 个目标", 
        hero.name or "Unknown", #targets))
    
    for _, target in ipairs(targets) do
        if target.isAlive and not target.isDead then
            local healValue = healConfig.healValue or 0
            if healValue > 0 then
                BattleDmgHeal.ApplyHeal(target, healValue, hero)
                Log(string.format("  -> %s 恢复 %d 点HP", target.name or "Unknown", healValue))
            end
        end
    end
    
    return true
end

--- 加载法术技能Lua
local spellLuaCache = {}
local function LoadSpellLua(spellId)
    if spellLuaCache[spellId] then
        return spellLuaCache[spellId]
    end
    
    -- 构建法术文件名
    local spellFileName = string.format("spell_%d", spellId)
    -- 从config目录加载
    local luaFile = string.format("config.spell.%s", spellFileName)
    
    -- 尝试加载
    local success, result = pcall(require, luaFile)
    if not success then
        Log(string.format("[SkillExecutor] 法术文件不存在: %s, 错误: %s", luaFile, tostring(result)))
        return nil
    end
    
    -- 从全局变量获取法术数据
    local globalVarName = spellFileName
    local spellData = _G[globalVarName]
    
    if spellData then
        spellLuaCache[spellId] = spellData
        return spellData
    end
    
    return nil
end

--- 执行法术技能
function SkillExecutor.ExecuteSpell(hero, targets, spellConfig)
    if not spellConfig.spellId or spellConfig.spellId <= 0 then
        return false
    end
    
    -- 加载法术技能
    local spellData = LoadSpellLua(spellConfig.spellId)
    if not spellData then
        Log(string.format("[SkillExecutor.ExecuteSpell] 无法加载法术: %d", spellConfig.spellId))
        return false
    end
    
    Log(string.format("[SkillExecutor.ExecuteSpell] %s 执行法术 %d", 
        hero.name or "Unknown", spellConfig.spellId))
    
    local executed = false
    
    -- 执行法术伤害
    if spellData.NewAttackDrop and spellData.NewAttackDrop.damageData then
        local damageData = spellData.NewAttackDrop.damageData
        
        -- 获取技能参数（从法术配置或默认）
        local skillParam = {10000}  -- 默认100%伤害
        
        -- 对所有目标造成伤害
        for _, target in ipairs(targets) do
            if target.isAlive and not target.isDead then
                local BattleDmgHeal = require("modules.battle_dmg_heal")
                local BattleFormula = require("core.battle_formula")
                
                -- 计算伤害
                local damageResult = BattleFormula.CalcDamage(hero, target, 10000)
                local finalDamage = damageResult.damage or 0
                
                if finalDamage > 0 then
                    BattleDmgHeal.ApplyDamage(target, finalDamage, hero)
                    Log(string.format("  -> %s 受到 %d 点法术伤害", target.name or "Unknown", finalDamage))
                    executed = true
                end
            end
        end
    end
    
    return executed
end

--- 执行完整技能
function SkillExecutor.ExecuteSkill(hero, targets, skillData, skillConfig)
    if not skillData then
        LogError("[SkillExecutor.ExecuteSkill] 技能数据为空")
        return false
    end
    
    Log(string.format("[SkillExecutor.ExecuteSkill] %s 执行技能", hero.name or "Unknown"))
    
    -- 提取技能效果
    local effects = SkillExecutor.ExtractSkillEffects(skillData)
    
    -- 获取技能参数
    local skillParam = nil
    if skillConfig and skillConfig.skillParam then
        skillParam = skillConfig.skillParam
    end
    
    local executed = false
    
    -- 执行伤害
    if #effects.damages > 0 then
        for _, damageConfig in ipairs(effects.damages) do
            SkillExecutor.ExecuteDamage(hero, targets, damageConfig, skillParam)
            executed = true
        end
    end
    
    -- 执行Buff
    if #effects.buffs > 0 then
        for _, buffConfig in ipairs(effects.buffs) do
            SkillExecutor.ExecuteBuff(hero, targets, buffConfig)
            executed = true
        end
    end
    
    -- 执行治疗
    if #effects.heals > 0 then
        for _, healConfig in ipairs(effects.heals) do
            SkillExecutor.ExecuteHeal(hero, targets, healConfig)
            executed = true
        end
    end
    
    -- 执行法术（范围攻击）
    if #effects.spells > 0 then
        for _, spellCfg in ipairs(effects.spells) do
            SkillExecutor.ExecuteSpell(hero, targets, spellCfg)
            executed = true
        end
    end
    
    return executed
end

return SkillExecutor
