-- 雷神之怒: 弹射10次，必定暴击
-- 技能ID: 800012104
-- ClassID: 8000121, Level: 4

skill_800012104 = {
    -- 技能基础信息
    meta = {
        id = 800012104,
        classId = 8000121,
        level = 4,
        name = "雷神之怒",
        description = "弹射10次，必定暴击",
        type = 3,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 350,
        cooldown = 0,
        cost = 100,
        icon = "skill_thunder_god",
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
    skillParam = {15000, 12000, 9600, 7680, 6144, 4915, 3932, 3146, 2517, 2013},
    
    -- Buff触发配置
    buffTriggers = {

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
function skill_800012104.Execute(hero, targets, skill)
    if not hero or not targets or #targets == 0 then
        return false
    end
    
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local BattleFormula = require("core.battle_formula")
    
    local params = skill_800012104.skillParam
    local damageRate = params[1] or 10000
    
    -- 对每个目标造成伤害
    for _, target in ipairs(targets) do
        if target and target.isAlive and not target.isDead then
            local damageResult = BattleFormula.CalcDamage(hero, target, damageRate)
            BattleDmgHeal.ApplyDamage(target, damageResult.damage, hero)
            
            -- 触发Buff
            for _, buffTrigger in ipairs(skill_800012104.buffTriggers) do
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

return skill_800012104
