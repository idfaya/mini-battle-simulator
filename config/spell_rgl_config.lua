-- Roguelike Spell 配置加载模块

local SpellRglConfig = {}

-- Spell 缓存
local spellCache = {}

-- 本地日志
local function Log(msg)
    print("[SpellRglConfig] " .. msg)
end

--- 加载 Spell Lua 脚本
---@param spellId number Spell ID
---@return table Spell 数据
function SpellRglConfig.LoadSpell(spellId)
    if spellCache[spellId] then
        return spellCache[spellId]
    end
    
    local spellFileName = string.format("spell_%d", spellId)
    local luaPath = string.format("config.spell_rgl.%s", spellFileName)
    
    -- 尝试加载
    local success, result = pcall(function()
        return require(luaPath)
    end)
    
    if not success or not result then
        -- 尝试从 spell 目录加载（兼容旧配置）
        luaPath = string.format("config.spell.%s", spellFileName)
        success, result = pcall(function()
            return require(luaPath)
        end)
    end
    
    if success and result and type(result) == "table" then
        spellCache[spellId] = result
        return result
    else
        Log(string.format("无法加载 Spell: %d", spellId))
        return nil
    end
end

--- 执行 Spell
---@param hero table 施法者
---@param targets table 目标列表
---@param spellId number Spell ID
---@return boolean 是否成功执行
function SpellRglConfig.ExecuteSpell(hero, targets, spellId)
    local spellData = SpellRglConfig.LoadSpell(spellId)
    if not spellData then
        return false
    end
    
    Log(string.format("%s 执行 Spell %d (%s)", 
        hero.name or "Unknown", spellId, spellData.Name or "Unknown"))
    
    -- 执行伤害效果
    if spellData.NewAttackDrop and spellData.NewAttackDrop.damageData then
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local BattleFormula = require("core.battle_formula")
        
        local damageData = spellData.NewAttackDrop.damageData
        
        for _, target in ipairs(targets or {}) do
            if target and target.isAlive and not target.isDead then
                -- 计算伤害
                local damageRate = 10000  -- 默认100%
                local damageResult = BattleFormula.CalcDamage(hero, target, damageRate)
                
                -- 应用伤害
                BattleDmgHeal.ApplyDamage(target, damageResult.damage, hero)
                
                Log(string.format("  -> 对 %s 造成 %d 伤害", 
                    target.name or "Unknown", damageResult.damage))
            end
        end
    end
    
    -- 执行治疗效果
    if spellData.NewAttackDrop and spellData.NewAttackDrop.healData then
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        
        for _, target in ipairs(targets or {}) do
            if target and target.isAlive and not target.isDead then
                -- 计算治疗量（简化处理）
                local healAmount = (hero.atk or 1000) * 0.5
                BattleDmgHeal.ApplyHeal(target, healAmount, hero)
                
                Log(string.format("  -> 对 %s 恢复 %d HP", 
                    target.name or "Unknown", healAmount))
            end
        end
    end
    
    -- 触发 Buff
    if spellData.launchBuff and spellData.launchBuff.AssociateBuff then
        local buffId = spellData.launchBuff.AssociateBuff
        if buffId > 0 then
            local BattleBuff = require("modules.battle_buff")
            local BuffRglConfig = require("config.buff_rgl_config")
            
            for _, target in ipairs(targets or {}) do
                local buffConfig = BuffRglConfig.ConvertToBattleBuffConfig(buffId)
                if buffConfig then
                    BattleBuff.Add(hero, target, buffConfig)
                    Log(string.format("  -> 对 %s 施加 Buff %d", 
                        target.name or "Unknown", buffId))
                end
            end
        end
    end
    
    return true
end

--- 获取 Spell 信息
---@param spellId number Spell ID
---@return table Spell 信息
function SpellRglConfig.GetSpellInfo(spellId)
    local spellData = SpellRglConfig.LoadSpell(spellId)
    if not spellData then
        return nil
    end
    
    return {
        id = spellId,
        name = spellData.Name or "Unknown",
        title = spellData.Title or "",
        motionEffect = spellData.MotionEffectPath or "",
        hasDamage = spellData.NewAttackDrop and spellData.NewAttackDrop.damageData ~= nil,
        hasHeal = spellData.NewAttackDrop and spellData.NewAttackDrop.healData ~= nil,
    }
end

return SpellRglConfig
