-- 5e 风格的 feat 系统配置。
-- 设计原则：
--   1. feat 按 classId 分池。升级时根据角色 Class 抽取候选。
--   2. 每个 feat 带 minLevel（Level Gate），只在达到条件时进入抽取池。
--   3. tag 用于保证 3 选 1 的多样性；risk 仅作为可选风味，不强制出现。
--   4. exclusiveGroup 用于流派互斥（例如 Lv3 格挡 / 狂战 / 血祭三选一，选其一锁死同组其他）。
-- 固有效果（属性曲线）仍由 hero_data.lua 的模板驱动；feat 只在固有效果之上叠加。

---@alias FeatTag "offense"|"defense"|"control"|"utility"|"risk"|"core"

---@class FeatEffect
---@field type "stat_add"|"stat_mult"|"unlock_skill"|"upgrade_skill"|"passive"|"risk_modifier"
---@field maxHp integer|nil
---@field atk integer|nil
---@field def integer|nil
---@field ac integer|nil
---@field hit integer|nil
---@field spellDC integer|nil
---@field saveFort integer|nil
---@field saveRef integer|nil
---@field saveWill integer|nil
---@field speed integer|nil
---@field critRate integer|nil
---@field blockRate integer|nil
---@field healBonus integer|nil
---@field skillId integer|nil
---@field skillLevel integer|nil
---@field passiveId integer|nil
---@field onBattleStart string|nil   -- 例如 "lose_hp_pct:0.08"
---@field onTurnStart string|nil     -- 例如 "lose_hp:2"
---@field grant table<string, integer>|nil -- risk_modifier 的代价换取效果

---@class FeatDef
---@field id integer
---@field name string
---@field code string             -- 卡面短描述
---@field classId integer         -- 归属 Class（9 个之一）
---@field minLevel integer        -- Level Gate
---@field tags FeatTag[]
---@field weight integer
---@field exclusiveGroup string|nil
---@field effects FeatEffect[]

local FeatConfig = {}

local function FeatId(classId, level, index)
    -- 7 digits: 11 C LL NN
    return 1100000 + (tonumber(classId) or 0) * 10000 + (tonumber(level) or 0) * 100 + (tonumber(index) or 0)
end

---@type table<integer, FeatDef>
local FEATS = {
    -- ======================================================================
    -- Class 2 Fighter / Tank（格挡）
    -- ======================================================================
    [FeatId(2, 2, 1)] = {
        id = FeatId(2, 2, 1), name = "防守姿态", code = "强化格挡反击，提升防守稳定性",
        classId = 2, minLevel = 2, tags = { "defense", "core" }, weight = 100,
        effects = { { type = "stat_add", ac = 1, blockRate = 400 } },
    },
    [FeatId(2, 2, 2)] = {
        id = FeatId(2, 2, 2), name = "压制挥砍", code = "顺劈斩更易压制目标行动",
        classId = 2, minLevel = 2, tags = { "offense", "core" }, weight = 100,
        effects = { { type = "upgrade_skill", skillId = 80002003, skillLevel = 2 }, { type = "stat_add", hit = 1 } },
    },
    [FeatId(2, 2, 3)] = {
        id = FeatId(2, 2, 3), name = "战斗韧性", code = "二次生命后获得短时护体",
        classId = 2, minLevel = 2, tags = { "utility" }, weight = 80,
        effects = { { type = "stat_add", maxHp = 8, saveFort = 1 } },
    },
    [FeatId(2, 2, 4)] = {
        id = FeatId(2, 2, 4), name = "盾墙协同", code = "强化前排保护与抗压能力",
        classId = 2, minLevel = 2, tags = { "defense" }, weight = 80,
        effects = { { type = "stat_add", ac = 1, maxHp = 8 } },
    },

    -- Lv3 流派分叉（互斥）
    [FeatId(2, 3, 1)] = {
        id = FeatId(2, 3, 1), name = "护卫流派", code = "锁定护卫路线：强化拦截与守线",
        classId = 2, minLevel = 3, tags = { "defense", "core" }, weight = 100,
        exclusiveGroup = "class2_path",
        effects = { { type = "stat_add", ac = 1, blockRate = 800 } },
    },
    [FeatId(2, 3, 2)] = {
        id = FeatId(2, 3, 2), name = "斗士流派", code = "锁定斗士路线：强化反击与压制",
        classId = 2, minLevel = 3, tags = { "offense", "core" }, weight = 100,
        exclusiveGroup = "class2_path",
        effects = { { type = "upgrade_skill", skillId = 80002003, skillLevel = 2 }, { type = "stat_add", hit = 1 } },
    },
    [FeatId(2, 3, 3)] = {
        id = FeatId(2, 3, 3), name = "狂锋流派", code = "锁定狂锋路线：强化清场与连斩",
        classId = 2, minLevel = 3, tags = { "offense", "core" }, weight = 80,
        exclusiveGroup = "class2_path",
        effects = { { type = "upgrade_skill", skillId = 80002004, skillLevel = 2 }, { type = "stat_add", atk = 1 } },
    },

    -- Lv4
    [FeatId(2, 4, 1)] = {
        id = FeatId(2, 4, 1), name = "属性提升", code = "5e ASI：提升基础命中与攻击",
        classId = 2, minLevel = 4, tags = { "utility" }, weight = 100,
        effects = { { type = "stat_add", atk = 1, hit = 1 } },
    },
    [FeatId(2, 4, 2)] = {
        id = FeatId(2, 4, 2), name = "盾击专精", code = "盾击更稳，防守反击更易触发",
        classId = 2, minLevel = 4, tags = { "defense" }, weight = 100,
        effects = { { type = "upgrade_skill", skillId = 80002001, skillLevel = 2 }, { type = "stat_add", ac = 1 } },
    },
    [FeatId(2, 4, 3)] = {
        id = FeatId(2, 4, 3), name = "顺劈扩展", code = "顺劈打击覆盖更广",
        classId = 2, minLevel = 4, tags = { "offense" }, weight = 80,
        effects = { { type = "upgrade_skill", skillId = 80002003, skillLevel = 3 } },
    },
    [FeatId(2, 4, 4)] = {
        id = FeatId(2, 4, 4), name = "钢铁意志", code = "前排抗压与豁免稳定性提升",
        classId = 2, minLevel = 4, tags = { "defense" }, weight = 80,
        effects = { { type = "stat_add", saveFort = 1, maxHp = 10 } },
    },

    -- Lv5
    [FeatId(2, 5, 1)] = {
        id = FeatId(2, 5, 1), name = "旋风战法", code = "旋风斩强化，清场能力提升",
        classId = 2, minLevel = 5, tags = { "offense", "core" }, weight = 100,
        effects = { { type = "upgrade_skill", skillId = 80002004, skillLevel = 2 }, { type = "stat_add", atk = 2 } },
    },
    [FeatId(2, 5, 2)] = {
        id = FeatId(2, 5, 2), name = "钢铁防线", code = "护卫能力提升，守线更稳",
        classId = 2, minLevel = 5, tags = { "defense", "core" }, weight = 100,
        effects = { { type = "stat_add", ac = 1, maxHp = 12 } },
    },
    [FeatId(2, 5, 3)] = {
        id = FeatId(2, 5, 3), name = "处决连动", code = "击杀后更易衔接追击",
        classId = 2, minLevel = 5, tags = { "offense", "core" }, weight = 80,
        effects = { { type = "stat_add", hit = 1, critRate = 500 } },
    },

    -- ======================================================================
    -- Class 1 Rogue（刺客）
    -- ======================================================================
    [FeatId(1, 2, 1)] = { id = FeatId(1, 2, 1), name = "影袭", code = "普攻更易打出背刺窗口", classId = 1, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80001001, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(1, 2, 2)] = { id = FeatId(1, 2, 2), name = "灵巧步法", code = "位移与机动能力增强", classId = 1, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", speed = 4, saveRef = 1 } } },
    [FeatId(1, 2, 3)] = { id = FeatId(1, 2, 3), name = "精确处决", code = "斩击对低血目标收益更高", classId = 1, minLevel = 2, tags = { "offense" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80001003, skillLevel = 2 }, { type = "stat_add", critRate = 300 } } },
    [FeatId(1, 2, 4)] = { id = FeatId(1, 2, 4), name = "渗透战术", code = "提升后排压制能力", classId = 1, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", hit = 1, speed = 2 } } },
    [FeatId(1, 3, 1)] = { id = FeatId(1, 3, 1), name = "刺客流派", code = "锁定刺客路线：先手与处决", classId = 1, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class1_path", effects = { { type = "upgrade_skill", skillId = 80001001, skillLevel = 2 }, { type = "stat_add", critRate = 500 } } },
    [FeatId(1, 3, 2)] = { id = FeatId(1, 3, 2), name = "诡术流派", code = "锁定诡术路线：位移与扰乱", classId = 1, minLevel = 3, tags = { "utility", "core" }, weight = 100, exclusiveGroup = "class1_path", effects = { { type = "upgrade_skill", skillId = 80001003, skillLevel = 2 }, { type = "stat_add", speed = 3 } } },
    [FeatId(1, 3, 3)] = { id = FeatId(1, 3, 3), name = "游斗流派", code = "锁定游斗路线：持续压制", classId = 1, minLevel = 3, tags = { "offense", "core" }, weight = 80, exclusiveGroup = "class1_path", effects = { { type = "upgrade_skill", skillId = 80001004, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(1, 4, 1)] = { id = FeatId(1, 4, 1), name = "属性提升", code = "5e ASI：提高攻击与机动", classId = 1, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", atk = 1, speed = 1 } } },
    [FeatId(1, 4, 2)] = { id = FeatId(1, 4, 2), name = "淬毒武器", code = "斩击更易附加持续压制", classId = 1, minLevel = 4, tags = { "control" }, weight = 90, effects = { { type = "stat_add", spellDC = 1, atk = 1 } } },
    [FeatId(1, 4, 3)] = { id = FeatId(1, 4, 3), name = "精准渗透", code = "后排打击稳定性提升", classId = 1, minLevel = 4, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80001003, skillLevel = 3 } } },
    [FeatId(1, 4, 4)] = { id = FeatId(1, 4, 4), name = "轻甲熟练", code = "提升存活率与灵活性", classId = 1, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, saveRef = 1 } } },
    [FeatId(1, 5, 1)] = { id = FeatId(1, 5, 1), name = "处决连锁", code = "大招收割链能力提升", classId = 1, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80001004, skillLevel = 3 }, { type = "stat_add", critRate = 500 } } },
    [FeatId(1, 5, 2)] = { id = FeatId(1, 5, 2), name = "致命破绽", code = "背刺与处决窗口更稳定", classId = 1, minLevel = 5, tags = { "offense" }, weight = 90, effects = { { type = "stat_add", hit = 2, critRate = 300 } } },
    [FeatId(1, 5, 3)] = { id = FeatId(1, 5, 3), name = "影遁", code = "生存与拉扯能力增强", classId = 1, minLevel = 5, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", saveRef = 1, speed = 2 } } },

    -- ======================================================================
    -- Class 3 Monk（武僧）
    -- ======================================================================
    [FeatId(3, 2, 1)] = { id = FeatId(3, 2, 1), name = "气劲", code = "+2 攻击，+3 速度", classId = 3, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", atk = 2, speed = 3 } } },
    [FeatId(3, 2, 2)] = { id = FeatId(3, 2, 2), name = "铁布衫", code = "+10 生命上限，+1 坚韧豁免", classId = 3, minLevel = 2, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", maxHp = 10, saveFort = 1 } } },
    [FeatId(3, 2, 3)] = { id = FeatId(3, 2, 3), name = "洞察反射", code = "+1 敏捷豁免，+1 意志豁免", classId = 3, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", saveRef = 1, saveWill = 1 } } },
    [FeatId(3, 2, 4)] = { id = FeatId(3, 2, 4), name = "燃命冲拳", code = "每回合失去 2 HP，换取 +4 攻击", classId = 3, minLevel = 2, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:2", grant = { atk = 4 } } } },
    [FeatId(3, 3, 1)] = { id = FeatId(3, 3, 1), name = "连环腿", code = "主动技能升阶，+1 命中", classId = 3, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class3_path", effects = { { type = "upgrade_skill", skillId = 80003003, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(3, 3, 2)] = { id = FeatId(3, 3, 2), name = "护体真气", code = "+1 AC，+8 生命上限", classId = 3, minLevel = 3, tags = { "defense", "core" }, weight = 100, exclusiveGroup = "class3_path", effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(3, 3, 3)] = { id = FeatId(3, 3, 3), name = "破釜沉舟", code = "战斗开场失去 6% 生命，换取 +10% 暴击", classId = 3, minLevel = 3, tags = { "risk", "core" }, weight = 80, exclusiveGroup = "class3_path", effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.06", grant = { critRate = 1000 } } } },
    [FeatId(3, 4, 1)] = { id = FeatId(3, 4, 1), name = "武艺精进", code = "+3 攻击", classId = 3, minLevel = 4, tags = { "offense" }, weight = 100, effects = { { type = "stat_add", atk = 3 } } },
    [FeatId(3, 4, 2)] = { id = FeatId(3, 4, 2), name = "身法精进", code = "+6 速度，+1 敏捷豁免", classId = 3, minLevel = 4, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", speed = 6, saveRef = 1 } } },
    [FeatId(3, 4, 3)] = { id = FeatId(3, 4, 3), name = "气血调息", code = "+12 生命上限，+1 意志豁免", classId = 3, minLevel = 4, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", maxHp = 12, saveWill = 1 } } },
    [FeatId(3, 4, 4)] = { id = FeatId(3, 4, 4), name = "狂气", code = "-1 AC，换取 +5 攻击（代价）", classId = 3, minLevel = 4, tags = { "risk" }, weight = 80, effects = { { type = "stat_add", ac = -1, atk = 5 } } },
    [FeatId(3, 5, 1)] = { id = FeatId(3, 5, 1), name = "迅捷连击", code = "+2 命中，+3 速度", classId = 3, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", hit = 2, speed = 3 } } },
    [FeatId(3, 5, 2)] = { id = FeatId(3, 5, 2), name = "金钟罩", code = "+1 AC，+1 坚韧豁免", classId = 3, minLevel = 5, tags = { "defense", "core" }, weight = 90, effects = { { type = "stat_add", ac = 1, saveFort = 1 } } },
    [FeatId(3, 5, 3)] = { id = FeatId(3, 5, 3), name = "伤换势", code = "每回合失去 3 HP，换取 +6% 暴击", classId = 3, minLevel = 5, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:3", grant = { critRate = 600 } } } },

    -- ======================================================================
    -- Class 4 BattleRage（战意/狂战）
    -- ======================================================================
    [FeatId(4, 2, 1)] = { id = FeatId(4, 2, 1), name = "怒火", code = "+3 攻击", classId = 4, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", atk = 3 } } },
    [FeatId(4, 2, 2)] = { id = FeatId(4, 2, 2), name = "坚皮", code = "+12 生命上限", classId = 4, minLevel = 2, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", maxHp = 12 } } },
    [FeatId(4, 2, 3)] = { id = FeatId(4, 2, 3), name = "战吼", code = "+1 命中，+1 坚韧豁免", classId = 4, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", hit = 1, saveFort = 1 } } },
    [FeatId(4, 2, 4)] = { id = FeatId(4, 2, 4), name = "血怒", code = "战斗开场失去 8% 生命，换取 +6 攻击", classId = 4, minLevel = 2, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.08", grant = { atk = 6 } } } },
    [FeatId(4, 3, 1)] = { id = FeatId(4, 3, 1), name = "撕裂之道", code = "+4 攻击，-1 AC", classId = 4, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class4_path", effects = { { type = "stat_add", atk = 4, ac = -1 } } },
    [FeatId(4, 3, 2)] = { id = FeatId(4, 3, 2), name = "铁血之道", code = "+20 生命上限", classId = 4, minLevel = 3, tags = { "defense", "core" }, weight = 100, exclusiveGroup = "class4_path", effects = { { type = "stat_add", maxHp = 20 } } },
    [FeatId(4, 3, 3)] = { id = FeatId(4, 3, 3), name = "献祭之道", code = "每回合失去 3 HP，换取 +10% 暴击", classId = 4, minLevel = 3, tags = { "risk", "core" }, weight = 80, exclusiveGroup = "class4_path", effects = { { type = "risk_modifier", onTurnStart = "lose_hp:3", grant = { critRate = 1000 } } } },
    [FeatId(4, 4, 1)] = { id = FeatId(4, 4, 1), name = "破坏欲", code = "+5 攻击", classId = 4, minLevel = 4, tags = { "offense" }, weight = 100, effects = { { type = "stat_add", atk = 5 } } },
    [FeatId(4, 4, 2)] = { id = FeatId(4, 4, 2), name = "耐痛", code = "+18 生命上限", classId = 4, minLevel = 4, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", maxHp = 18 } } },
    [FeatId(4, 4, 3)] = { id = FeatId(4, 4, 3), name = "凶猛", code = "+2 命中，-1 AC（代价）", classId = 4, minLevel = 4, tags = { "risk" }, weight = 80, effects = { { type = "stat_add", hit = 2, ac = -1 } } },
    [FeatId(4, 4, 4)] = { id = FeatId(4, 4, 4), name = "不屈", code = "+1 坚韧豁免，+1 意志豁免", classId = 4, minLevel = 4, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", saveFort = 1, saveWill = 1 } } },
    [FeatId(4, 5, 1)] = { id = FeatId(4, 5, 1), name = "屠戮", code = "+6 攻击，+1 命中", classId = 4, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", atk = 6, hit = 1 } } },
    [FeatId(4, 5, 2)] = { id = FeatId(4, 5, 2), name = "狂战皮革", code = "+1 AC，+10 生命上限", classId = 4, minLevel = 5, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, maxHp = 10 } } },
    [FeatId(4, 5, 3)] = { id = FeatId(4, 5, 3), name = "焚命怒涛", code = "战斗开场失去 10% 生命，换取 +8 攻击", classId = 4, minLevel = 5, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.10", grant = { atk = 8 } } } },

    -- ======================================================================
    -- Class 5 Poison / Ranger（毒爆）
    -- ======================================================================
    [FeatId(5, 2, 1)] = { id = FeatId(5, 2, 1), name = "毒素学", code = "+1 法术 DC，+1 命中", classId = 5, minLevel = 2, tags = { "control", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 1, hit = 1 } } },
    [FeatId(5, 2, 2)] = { id = FeatId(5, 2, 2), name = "游击", code = "+4 速度，+1 敏捷豁免", classId = 5, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", speed = 4, saveRef = 1 } } },
    [FeatId(5, 2, 3)] = { id = FeatId(5, 2, 3), name = "腐蚀刃", code = "+2 攻击", classId = 5, minLevel = 2, tags = { "offense" }, weight = 90, effects = { { type = "stat_add", atk = 2 } } },
    [FeatId(5, 2, 4)] = { id = FeatId(5, 2, 4), name = "以毒养毒", code = "每回合失去 2 HP，换取 +2 法术 DC（代价）", classId = 5, minLevel = 2, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:2", grant = { spellDC = 2 } } } },
    [FeatId(5, 3, 1)] = { id = FeatId(5, 3, 1), name = "爆发之道", code = "+2 法术 DC，主动技能升阶", classId = 5, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class5_path", effects = { { type = "stat_add", spellDC = 2 }, { type = "upgrade_skill", skillId = 80005003, skillLevel = 2 } } },
    [FeatId(5, 3, 2)] = { id = FeatId(5, 3, 2), name = "控制之道", code = "+2 法术 DC，+1 意志豁免", classId = 5, minLevel = 3, tags = { "control", "core" }, weight = 100, exclusiveGroup = "class5_path", effects = { { type = "stat_add", spellDC = 2, saveWill = 1 } } },
    [FeatId(5, 3, 3)] = { id = FeatId(5, 3, 3), name = "血毒之道", code = "战斗开场失去 6% 生命，换取 +3 法术 DC", classId = 5, minLevel = 3, tags = { "risk", "core" }, weight = 80, exclusiveGroup = "class5_path", effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.06", grant = { spellDC = 3 } } } },
    [FeatId(5, 4, 1)] = { id = FeatId(5, 4, 1), name = "毒性强化", code = "+2 法术 DC", classId = 5, minLevel = 4, tags = { "control" }, weight = 100, effects = { { type = "stat_add", spellDC = 2 } } },
    [FeatId(5, 4, 2)] = { id = FeatId(5, 4, 2), name = "精准投射", code = "+2 命中，+1 攻击", classId = 5, minLevel = 4, tags = { "offense" }, weight = 90, effects = { { type = "stat_add", hit = 2, atk = 1 } } },
    [FeatId(5, 4, 3)] = { id = FeatId(5, 4, 3), name = "抗毒体质", code = "+12 生命上限，+1 坚韧豁免", classId = 5, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", maxHp = 12, saveFort = 1 } } },
    [FeatId(5, 4, 4)] = { id = FeatId(5, 4, 4), name = "剧毒代价", code = "-1 AC，换取 +3 法术 DC（代价）", classId = 5, minLevel = 4, tags = { "risk" }, weight = 80, effects = { { type = "stat_add", ac = -1, spellDC = 3 } } },
    [FeatId(5, 5, 1)] = { id = FeatId(5, 5, 1), name = "毒爆精通", code = "+3 法术 DC，+1 命中", classId = 5, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 3, hit = 1 } } },
    [FeatId(5, 5, 2)] = { id = FeatId(5, 5, 2), name = "游猎者", code = "+6 速度，+1 敏捷豁免", classId = 5, minLevel = 5, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", speed = 6, saveRef = 1 } } },
    [FeatId(5, 5, 3)] = { id = FeatId(5, 5, 3), name = "饮鸩止渴", code = "每回合失去 3 HP，换取 +4 法术 DC", classId = 5, minLevel = 5, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:3", grant = { spellDC = 4 } } } },

    -- ======================================================================
    -- Class 6 Cleric（牧师）
    -- ======================================================================
    [FeatId(6, 2, 1)] = { id = FeatId(6, 2, 1), name = "圣疗", code = "群疗效率提升，溢出更稳定", classId = 6, minLevel = 2, tags = { "utility", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 2 }, { type = "stat_add", healBonus = 800 } } },
    [FeatId(6, 2, 2)] = { id = FeatId(6, 2, 2), name = "神圣专注", code = "神术命中与稳定性提升", classId = 6, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", spellDC = 1, saveWill = 1 } } },
    [FeatId(6, 2, 3)] = { id = FeatId(6, 2, 3), name = "惩戒火花", code = "普攻与神圣打击联动增强", classId = 6, minLevel = 2, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80006001, skillLevel = 2 }, { type = "stat_add", atk = 1 } } },
    [FeatId(6, 2, 4)] = { id = FeatId(6, 2, 4), name = "护佑", code = "前中排站位更稳", classId = 6, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(6, 3, 1)] = { id = FeatId(6, 3, 1), name = "生命领域", code = "锁定生命路线：群疗与复苏强化", classId = 6, minLevel = 3, tags = { "utility", "core" }, weight = 100, exclusiveGroup = "class6_path", effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 3 }, { type = "stat_add", healBonus = 1000 } } },
    [FeatId(6, 3, 2)] = { id = FeatId(6, 3, 2), name = "光辉领域", code = "锁定光辉路线：奶伤混合", classId = 6, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class6_path", effects = { { type = "upgrade_skill", skillId = 80006001, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(6, 3, 3)] = { id = FeatId(6, 3, 3), name = "守护领域", code = "锁定守护路线：护盾与减伤", classId = 6, minLevel = 3, tags = { "defense", "core" }, weight = 80, exclusiveGroup = "class6_path", effects = { { type = "upgrade_skill", skillId = 80006004, skillLevel = 2 }, { type = "stat_add", ac = 1 } } },
    [FeatId(6, 4, 1)] = { id = FeatId(6, 4, 1), name = "属性提升", code = "5e ASI：提高施法与意志", classId = 6, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", spellDC = 1, saveWill = 1 } } },
    [FeatId(6, 4, 2)] = { id = FeatId(6, 4, 2), name = "净化圣言", code = "治疗附带净化能力增强", classId = 6, minLevel = 4, tags = { "utility" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 3 } } },
    [FeatId(6, 4, 3)] = { id = FeatId(6, 4, 3), name = "板甲训练", code = "前线支援能力增强", classId = 6, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, hit = 1 } } },
    [FeatId(6, 4, 4)] = { id = FeatId(6, 4, 4), name = "圣裁引导", code = "神圣打击与法术压制提升", classId = 6, minLevel = 4, tags = { "offense" }, weight = 80, effects = { { type = "stat_add", spellDC = 1, atk = 1 } } },
    [FeatId(6, 5, 1)] = { id = FeatId(6, 5, 1), name = "群疗强化", code = "群疗目标与收益强化", classId = 6, minLevel = 5, tags = { "utility", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 4 }, { type = "stat_add", healBonus = 1500 } } },
    [FeatId(6, 5, 2)] = { id = FeatId(6, 5, 2), name = "复苏恩典", code = "复活与保护能力提升", classId = 6, minLevel = 5, tags = { "defense" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80006004, skillLevel = 3 }, { type = "stat_add", ac = 1 } } },
    [FeatId(6, 5, 3)] = { id = FeatId(6, 5, 3), name = "裁决圣火", code = "奶伤混合输出能力提升", classId = 6, minLevel = 5, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80006001, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },

    -- ======================================================================
    -- Class 7 Fire Mage（火）
    -- ======================================================================
    [FeatId(7, 2, 1)] = { id = FeatId(7, 2, 1), name = "灼热", code = "+2 法术 DC，+1 命中", classId = 7, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 2, hit = 1 } } },
    [FeatId(7, 2, 2)] = { id = FeatId(7, 2, 2), name = "余烬护体", code = "+1 AC，+8 生命上限", classId = 7, minLevel = 2, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(7, 2, 3)] = { id = FeatId(7, 2, 3), name = "咒术熟练", code = "+1 意志豁免，+1 法术 DC", classId = 7, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", saveWill = 1, spellDC = 1 } } },
    [FeatId(7, 2, 4)] = { id = FeatId(7, 2, 4), name = "燃烧血脉", code = "每回合失去 2 HP，换取 +3 法术 DC", classId = 7, minLevel = 2, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:2", grant = { spellDC = 3 } } } },
    [FeatId(7, 3, 1)] = { id = FeatId(7, 3, 1), name = "爆裂之道", code = "主动技能升阶，+2 法术 DC", classId = 7, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class7_path", effects = { { type = "upgrade_skill", skillId = 80007003, skillLevel = 2 }, { type = "stat_add", spellDC = 2 } } },
    [FeatId(7, 3, 2)] = { id = FeatId(7, 3, 2), name = "烈焰护盾之道", code = "+1 AC，+2 法术 DC", classId = 7, minLevel = 3, tags = { "defense", "core" }, weight = 100, exclusiveGroup = "class7_path", effects = { { type = "stat_add", ac = 1, spellDC = 2 } } },
    [FeatId(7, 3, 3)] = { id = FeatId(7, 3, 3), name = "焚命之道", code = "战斗开场失去 8% 生命，换取 +4 法术 DC", classId = 7, minLevel = 3, tags = { "risk", "core" }, weight = 80, exclusiveGroup = "class7_path", effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.08", grant = { spellDC = 4 } } } },
    [FeatId(7, 4, 1)] = { id = FeatId(7, 4, 1), name = "法术精进", code = "+3 法术 DC", classId = 7, minLevel = 4, tags = { "offense" }, weight = 100, effects = { { type = "stat_add", spellDC = 3 } } },
    [FeatId(7, 4, 2)] = { id = FeatId(7, 4, 2), name = "奥术护甲", code = "+1 AC，+1 意志豁免", classId = 7, minLevel = 4, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, saveWill = 1 } } },
    [FeatId(7, 4, 3)] = { id = FeatId(7, 4, 3), name = "专注施法", code = "+1 法术 DC，+1 命中", classId = 7, minLevel = 4, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", spellDC = 1, hit = 1 } } },
    [FeatId(7, 4, 4)] = { id = FeatId(7, 4, 4), name = "献血燃烧", code = "-1 AC，换取 +5 法术 DC（代价）", classId = 7, minLevel = 4, tags = { "risk" }, weight = 80, effects = { { type = "stat_add", ac = -1, spellDC = 5 } } },
    [FeatId(7, 5, 1)] = { id = FeatId(7, 5, 1), name = "炎爆权能", code = "+4 法术 DC，+1 命中", classId = 7, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 4, hit = 1 } } },
    [FeatId(7, 5, 2)] = { id = FeatId(7, 5, 2), name = "灰烬结界", code = "+1 AC，+10 生命上限", classId = 7, minLevel = 5, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, maxHp = 10 } } },
    [FeatId(7, 5, 3)] = { id = FeatId(7, 5, 3), name = "焚尽", code = "每回合失去 3 HP，换取 +6 法术 DC", classId = 7, minLevel = 5, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:3", grant = { spellDC = 6 } } } },

    -- ======================================================================
    -- Class 8 Ice Mage（冰）
    -- ======================================================================
    [FeatId(8, 2, 1)] = { id = FeatId(8, 2, 1), name = "寒霜专注", code = "+2 法术 DC，+1 坚韧豁免", classId = 8, minLevel = 2, tags = { "control", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 2, saveFort = 1 } } },
    [FeatId(8, 2, 2)] = { id = FeatId(8, 2, 2), name = "冰甲", code = "+1 AC，+8 生命上限", classId = 8, minLevel = 2, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(8, 2, 3)] = { id = FeatId(8, 2, 3), name = "冷静", code = "+1 意志豁免，+1 法术 DC", classId = 8, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", saveWill = 1, spellDC = 1 } } },
    [FeatId(8, 2, 4)] = { id = FeatId(8, 2, 4), name = "冻伤代价", code = "战斗开场失去 6% 生命，换取 +3 法术 DC", classId = 8, minLevel = 2, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.06", grant = { spellDC = 3 } } } },
    [FeatId(8, 3, 1)] = { id = FeatId(8, 3, 1), name = "冻结之道", code = "主动技能升阶，+2 法术 DC", classId = 8, minLevel = 3, tags = { "control", "core" }, weight = 100, exclusiveGroup = "class8_path", effects = { { type = "upgrade_skill", skillId = 80008003, skillLevel = 2 }, { type = "stat_add", spellDC = 2 } } },
    [FeatId(8, 3, 2)] = { id = FeatId(8, 3, 2), name = "壁垒之道", code = "+1 AC，+2 法术 DC", classId = 8, minLevel = 3, tags = { "defense", "core" }, weight = 100, exclusiveGroup = "class8_path", effects = { { type = "stat_add", ac = 1, spellDC = 2 } } },
    [FeatId(8, 3, 3)] = { id = FeatId(8, 3, 3), name = "冰血之道", code = "每回合失去 2 HP，换取 +4 法术 DC", classId = 8, minLevel = 3, tags = { "risk", "core" }, weight = 80, exclusiveGroup = "class8_path", effects = { { type = "risk_modifier", onTurnStart = "lose_hp:2", grant = { spellDC = 4 } } } },
    [FeatId(8, 4, 1)] = { id = FeatId(8, 4, 1), name = "寒域", code = "+3 法术 DC", classId = 8, minLevel = 4, tags = { "control" }, weight = 100, effects = { { type = "stat_add", spellDC = 3 } } },
    [FeatId(8, 4, 2)] = { id = FeatId(8, 4, 2), name = "霜盾", code = "+1 AC，+1 坚韧豁免", classId = 8, minLevel = 4, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, saveFort = 1 } } },
    [FeatId(8, 4, 3)] = { id = FeatId(8, 4, 3), name = "凝神", code = "+1 意志豁免，+1 法术 DC", classId = 8, minLevel = 4, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", saveWill = 1, spellDC = 1 } } },
    [FeatId(8, 4, 4)] = { id = FeatId(8, 4, 4), name = "极寒代价", code = "-1 AC，换取 +5 法术 DC（代价）", classId = 8, minLevel = 4, tags = { "risk" }, weight = 80, effects = { { type = "stat_add", ac = -1, spellDC = 5 } } },
    [FeatId(8, 5, 1)] = { id = FeatId(8, 5, 1), name = "冰封权能", code = "+4 法术 DC，+1 坚韧豁免", classId = 8, minLevel = 5, tags = { "control", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 4, saveFort = 1 } } },
    [FeatId(8, 5, 2)] = { id = FeatId(8, 5, 2), name = "寒霜铠", code = "+1 AC，+10 生命上限", classId = 8, minLevel = 5, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, maxHp = 10 } } },
    [FeatId(8, 5, 3)] = { id = FeatId(8, 5, 3), name = "冻脉", code = "战斗开场失去 8% 生命，换取 +6 法术 DC", classId = 8, minLevel = 5, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.08", grant = { spellDC = 6 } } } },

    -- ======================================================================
    -- Class 9 Thunder Mage（雷）
    -- ======================================================================
    [FeatId(9, 2, 1)] = { id = FeatId(9, 2, 1), name = "雷鸣专注", code = "+2 法术 DC，+5% 暴击", classId = 9, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 2, critRate = 500 } } },
    [FeatId(9, 2, 2)] = { id = FeatId(9, 2, 2), name = "电荷步伐", code = "+5 速度，+1 敏捷豁免", classId = 9, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", speed = 5, saveRef = 1 } } },
    [FeatId(9, 2, 3)] = { id = FeatId(9, 2, 3), name = "静电护盾", code = "+1 AC，+8 生命上限", classId = 9, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(9, 2, 4)] = { id = FeatId(9, 2, 4), name = "过载", code = "每回合失去 2 HP，换取 +4 法术 DC", classId = 9, minLevel = 2, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:2", grant = { spellDC = 4 } } } },
    [FeatId(9, 3, 1)] = { id = FeatId(9, 3, 1), name = "连锁之道", code = "主动技能升阶，+2 法术 DC", classId = 9, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class9_path", effects = { { type = "upgrade_skill", skillId = 80009003, skillLevel = 2 }, { type = "stat_add", spellDC = 2 } } },
    [FeatId(9, 3, 2)] = { id = FeatId(9, 3, 2), name = "暴击之道", code = "+15% 暴击率", classId = 9, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class9_path", effects = { { type = "stat_add", critRate = 1500 } } },
    [FeatId(9, 3, 3)] = { id = FeatId(9, 3, 3), name = "焚路之道", code = "战斗开场失去 8% 生命，换取 +6 法术 DC", classId = 9, minLevel = 3, tags = { "risk", "core" }, weight = 80, exclusiveGroup = "class9_path", effects = { { type = "risk_modifier", onBattleStart = "lose_hp_pct:0.08", grant = { spellDC = 6 } } } },
    [FeatId(9, 4, 1)] = { id = FeatId(9, 4, 1), name = "雷术精进", code = "+3 法术 DC", classId = 9, minLevel = 4, tags = { "offense" }, weight = 100, effects = { { type = "stat_add", spellDC = 3 } } },
    [FeatId(9, 4, 2)] = { id = FeatId(9, 4, 2), name = "静电集中", code = "+2 命中，+1 意志豁免", classId = 9, minLevel = 4, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", hit = 2, saveWill = 1 } } },
    [FeatId(9, 4, 3)] = { id = FeatId(9, 4, 3), name = "避雷针", code = "+1 AC，+1 敏捷豁免", classId = 9, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, saveRef = 1 } } },
    [FeatId(9, 4, 4)] = { id = FeatId(9, 4, 4), name = "自毁过载", code = "-1 AC，换取 +5 法术 DC（代价）", classId = 9, minLevel = 4, tags = { "risk" }, weight = 80, effects = { { type = "stat_add", ac = -1, spellDC = 5 } } },
    [FeatId(9, 5, 1)] = { id = FeatId(9, 5, 1), name = "雷暴权能", code = "+4 法术 DC，+10% 暴击", classId = 9, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "stat_add", spellDC = 4, critRate = 1000 } } },
    [FeatId(9, 5, 2)] = { id = FeatId(9, 5, 2), name = "磁场护体", code = "+1 AC，+10 生命上限", classId = 9, minLevel = 5, tags = { "defense" }, weight = 90, effects = { { type = "stat_add", ac = 1, maxHp = 10 } } },
    [FeatId(9, 5, 3)] = { id = FeatId(9, 5, 3), name = "过载暴走", code = "每回合失去 3 HP，换取 +6 法术 DC", classId = 9, minLevel = 5, tags = { "risk" }, weight = 80, effects = { { type = "risk_modifier", onTurnStart = "lose_hp:3", grant = { spellDC = 6 } } } },
}

---@type table<integer, integer[]>
local FEATS_BY_CLASS = {}

local function buildIndex()
    for featId, def in pairs(FEATS) do
        local classId = tonumber(def.classId) or 0
        FEATS_BY_CLASS[classId] = FEATS_BY_CLASS[classId] or {}
        FEATS_BY_CLASS[classId][#FEATS_BY_CLASS[classId] + 1] = featId
    end
end

buildIndex()

---@param featId integer
---@return FeatDef|nil
function FeatConfig.GetFeat(featId)
    return FEATS[tonumber(featId) or 0]
end

---@param classId integer
---@return integer[]
function FeatConfig.GetClassFeatIds(classId)
    return FEATS_BY_CLASS[tonumber(classId) or 0] or {}
end

---@param classId integer
---@param forLevel integer
---@param acquiredFeatIds integer[]|nil  -- 已拥有的 feat（用于互斥过滤）
---@return FeatDef[]
function FeatConfig.GetEligibleFeats(classId, forLevel, acquiredFeatIds)
    local ids = FeatConfig.GetClassFeatIds(classId)
    if #ids == 0 then
        return {}
    end

    local acquired = {}
    for _, fid in ipairs(acquiredFeatIds or {}) do
        acquired[fid] = true
    end

    local lockedGroups = {}
    for fid in pairs(acquired) do
        local def = FEATS[fid]
        if def and def.exclusiveGroup then
            lockedGroups[def.exclusiveGroup] = true
        end
    end

    local result = {}
    local lv = tonumber(forLevel) or 1
    for _, fid in ipairs(ids) do
        local def = FEATS[fid]
        if def and not acquired[fid] and (tonumber(def.minLevel) or 1) <= lv then
            if not def.exclusiveGroup or not lockedGroups[def.exclusiveGroup] then
                result[#result + 1] = def
            end
        end
    end
    return result
end

---@return table<integer, FeatDef>
function FeatConfig.GetAll()
    return FEATS
end

return FeatConfig
