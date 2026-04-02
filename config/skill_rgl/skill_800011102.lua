-- 穿透冰箭: 冰箭穿透同列，前排100%，后排70%
-- 技能ID: 800011102
-- ClassID: 8000111, Level: 2

skill_800011102 = {
    -- 技能基础信息
    meta = {
        id = 800011102,
        classId = 8000111,
        level = 2,
        name = "穿透冰箭",
        description = "冰箭穿透同列，前排100%，后排70%",
        type = 2,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 150,
        cooldown = 2,
        cost = 3,
        icon = "skill_ice_penetrate",
    },
    
    -- 目标选择配置
    targetsSelections = {
        castTarget = 2,  -- 2=敌方
        tSConditions = {
            Num = 1,
            wpType = nil,
        }
    },
    
    -- 技能参数
    -- SkillParam 参数
    skillParam = {10000, 7000, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810016,
        probability = 10000,
        targetType = 2,
        delayRound = 2,
        stackCount = 1,
    },
    },
    
    -- 动作时间轴数据（根据技能类型生成）
    actData = {},
    
    -- 被动技能特有配置
    passiveConfig = {
        isPassive = false,
        triggerTiming = 0,  -- 触发时机（需要根据实际情况配置）
    },
}

--- 执行技能
function skill_800011102.Execute(hero, targets, skill)
    if not hero or not targets or #targets == 0 then
        return false
    end
    
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local BattleFormula = require("core.battle_formula")
    
    local params = skill_800011102.skillParam
    local damageRate = params[1] or 10000
    
    -- 对每个目标造成伤害
    for _, target in ipairs(targets) do
        if target and target.isAlive and not target.isDead then
            local damageResult = BattleFormula.CalcDamage(hero, target, damageRate)
            BattleDmgHeal.ApplyDamage(target, damageResult.damage, hero)
            
            -- 触发Buff
            for _, buffTrigger in ipairs(skill_800011102.buffTriggers) do
                if math.random(1, 10000) <= buffTrigger.probability then
                    local BattleBuff = require("modules.battle_buff")
                    local BuffRglConfig = require("config.buff_rgl_config")
                    local buffConfig = BuffRglConfig.ConvertToBattleBuffConfig(buffTrigger.buffId)
                    if buffConfig then
                        BattleBuff.Add(hero, target, buffConfig)
                    end
                end
            end
        end
    end
    
    return true
end

return skill_800011102
