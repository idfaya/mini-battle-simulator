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
    -- Class 2 Fighter（前线战士）
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
    [FeatId(3, 2, 1)] = { id = FeatId(3, 2, 1), name = "连环拳", code = "武艺连缀更稳定，强化起手压制", classId = 3, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80003001, skillLevel = 2 }, { type = "stat_add", speed = 1 } } },
    [FeatId(3, 2, 2)] = { id = FeatId(3, 2, 2), name = "调息", code = "短回复与解控能力更可靠", classId = 3, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80003003, skillLevel = 2 }, { type = "stat_add", saveWill = 1 } } },
    [FeatId(3, 2, 3)] = { id = FeatId(3, 2, 3), name = "疾步", code = "机动与回避增强，方便游斗切入", classId = 3, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", speed = 3, saveRef = 1 } } },
    [FeatId(3, 2, 4)] = { id = FeatId(3, 2, 4), name = "铁身", code = "前排承压更稳，维持连击节奏", classId = 3, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, saveFort = 1 } } },
    [FeatId(3, 3, 1)] = { id = FeatId(3, 3, 1), name = "开放手流", code = "锁定控制路线：穿透打击更强", classId = 3, minLevel = 3, tags = { "control", "core" }, weight = 100, exclusiveGroup = "class3_path", effects = { { type = "upgrade_skill", skillId = 80003004, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(3, 3, 2)] = { id = FeatId(3, 3, 2), name = "影行流", code = "锁定游斗路线：起手与收割更顺", classId = 3, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class3_path", effects = { { type = "upgrade_skill", skillId = 80003001, skillLevel = 3 }, { type = "stat_add", saveRef = 1 } } },
    [FeatId(3, 3, 3)] = { id = FeatId(3, 3, 3), name = "调和流", code = "锁定续航路线：自愈与稳定更强", classId = 3, minLevel = 3, tags = { "utility", "core" }, weight = 90, exclusiveGroup = "class3_path", effects = { { type = "upgrade_skill", skillId = 80003003, skillLevel = 3 }, { type = "stat_add", saveWill = 1 } } },
    [FeatId(3, 4, 1)] = { id = FeatId(3, 4, 1), name = "属性提升", code = "5e ASI：提高命中与机动", classId = 3, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", atk = 1, speed = 1 } } },
    [FeatId(3, 4, 2)] = { id = FeatId(3, 4, 2), name = "震步", code = "穿透打击控制与覆盖能力提升", classId = 3, minLevel = 4, tags = { "control" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80003004, skillLevel = 3 } } },
    [FeatId(3, 4, 3)] = { id = FeatId(3, 4, 3), name = "气海", code = "续航与站场能力同步强化", classId = 3, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", maxHp = 8, ac = 1 } } },
    [FeatId(3, 4, 4)] = { id = FeatId(3, 4, 4), name = "体术专注", code = "出手更稳，易衔接被动追打", classId = 3, minLevel = 4, tags = { "offense" }, weight = 80, effects = { { type = "stat_add", hit = 1, critRate = 300 } } },
    [FeatId(3, 5, 1)] = { id = FeatId(3, 5, 1), name = "拳风连缀", code = "基础连击终盘更有压制力", classId = 3, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80003001, skillLevel = 3 }, { type = "stat_add", atk = 1 } } },
    [FeatId(3, 5, 2)] = { id = FeatId(3, 5, 2), name = "无垢躯体", code = "高压环境下仍能维持回复节奏", classId = 3, minLevel = 5, tags = { "utility", "core" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80003003, skillLevel = 3 }, { type = "stat_add", maxHp = 10 } } },
    [FeatId(3, 5, 3)] = { id = FeatId(3, 5, 3), name = "截脉", code = "控制终结能力与命中再上台阶", classId = 3, minLevel = 5, tags = { "control", "core" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80003004, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },

    -- ======================================================================
    -- Class 4 Paladin（圣武士）
    -- ======================================================================
    [FeatId(4, 2, 1)] = { id = FeatId(4, 2, 1), name = "神圣武艺", code = "惩击与平砍联动更稳定", classId = 4, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80004001, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(4, 2, 2)] = { id = FeatId(4, 2, 2), name = "庇护祷言", code = "战意光环持续更稳，豁免更高", classId = 4, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80004003, skillLevel = 2 }, { type = "stat_add", saveWill = 1 } } },
    [FeatId(4, 2, 3)] = { id = FeatId(4, 2, 3), name = "怜悯之手", code = "救急治疗与团队稳态更强", classId = 4, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80004004, skillLevel = 2 }, { type = "stat_add", healBonus = 600 } } },
    [FeatId(4, 2, 4)] = { id = FeatId(4, 2, 4), name = "重甲训练", code = "前线承伤能力增强", classId = 4, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, saveFort = 1 } } },
    [FeatId(4, 3, 1)] = { id = FeatId(4, 3, 1), name = "奉献誓约", code = "锁定守护路线：治疗与续战更强", classId = 4, minLevel = 3, tags = { "utility", "core" }, weight = 100, exclusiveGroup = "class4_path", effects = { { type = "upgrade_skill", skillId = 80004004, skillLevel = 2 }, { type = "stat_add", healBonus = 800 } } },
    [FeatId(4, 3, 2)] = { id = FeatId(4, 3, 2), name = "复仇誓约", code = "锁定裁决路线：单体惩击更强", classId = 4, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class4_path", effects = { { type = "upgrade_skill", skillId = 80004001, skillLevel = 3 }, { type = "stat_add", atk = 1 } } },
    [FeatId(4, 3, 3)] = { id = FeatId(4, 3, 3), name = "古贤誓约", code = "锁定灵光路线：团队增益更持久", classId = 4, minLevel = 3, tags = { "defense", "core" }, weight = 90, exclusiveGroup = "class4_path", effects = { { type = "upgrade_skill", skillId = 80004003, skillLevel = 3 }, { type = "stat_add", ac = 1 } } },
    [FeatId(4, 4, 1)] = { id = FeatId(4, 4, 1), name = "属性提升", code = "5e ASI：提高惩击与施法稳定性", classId = 4, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", atk = 1, spellDC = 1 } } },
    [FeatId(4, 4, 2)] = { id = FeatId(4, 4, 2), name = "庇护灵光", code = "团队战意光环覆盖更稳", classId = 4, minLevel = 4, tags = { "utility" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80004003, skillLevel = 3 }, { type = "stat_add", saveWill = 1 } } },
    [FeatId(4, 4, 3)] = { id = FeatId(4, 4, 3), name = "圣愈精通", code = "回复与急救能力进一步强化", classId = 4, minLevel = 4, tags = { "utility" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80004004, skillLevel = 3 }, { type = "stat_add", healBonus = 600 } } },
    [FeatId(4, 4, 4)] = { id = FeatId(4, 4, 4), name = "盾誓", code = "守线能力与生存空间同步提升", classId = 4, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(4, 5, 1)] = { id = FeatId(4, 5, 1), name = "神圣裁击", code = "高等级惩击具备更强终结性", classId = 4, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80004001, skillLevel = 3 }, { type = "stat_add", critRate = 300 } } },
    [FeatId(4, 5, 2)] = { id = FeatId(4, 5, 2), name = "王者灵光", code = "队伍在拉锯战中更难被压垮", classId = 4, minLevel = 5, tags = { "defense", "core" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80004003, skillLevel = 3 }, { type = "stat_add", saveWill = 1 } } },
    [FeatId(4, 5, 3)] = { id = FeatId(4, 5, 3), name = "无畏圣疗", code = "前线治疗与返场容错进一步提升", classId = 4, minLevel = 5, tags = { "utility", "core" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80004004, skillLevel = 3 }, { type = "stat_add", ac = 1 } } },

    -- ======================================================================
    -- Class 5 Ranger（游侠）
    -- ======================================================================
    [FeatId(5, 2, 1)] = { id = FeatId(5, 2, 1), name = "猎手标记", code = "毒刃命中与挂毒效率提升", classId = 5, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80005001, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(5, 2, 2)] = { id = FeatId(5, 2, 2), name = "游猎步法", code = "拉扯与换位能力增强", classId = 5, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", speed = 3, saveRef = 1 } } },
    [FeatId(5, 2, 3)] = { id = FeatId(5, 2, 3), name = "毒液知识", code = "群体挂毒更稳，后续爆发更高", classId = 5, minLevel = 2, tags = { "control" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80005003, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(5, 2, 4)] = { id = FeatId(5, 2, 4), name = "野外坚忍", code = "长线作战与环境适应更强", classId = 5, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", maxHp = 8, saveFort = 1 } } },
    [FeatId(5, 3, 1)] = { id = FeatId(5, 3, 1), name = "追猎者", code = "锁定单体路线：猎杀与收割更强", classId = 5, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class5_path", effects = { { type = "upgrade_skill", skillId = 80005001, skillLevel = 3 }, { type = "stat_add", hit = 1 } } },
    [FeatId(5, 3, 2)] = { id = FeatId(5, 3, 2), name = "疫毒者", code = "锁定控制路线：群体挂毒更厚", classId = 5, minLevel = 3, tags = { "control", "core" }, weight = 100, exclusiveGroup = "class5_path", effects = { { type = "upgrade_skill", skillId = 80005003, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(5, 3, 3)] = { id = FeatId(5, 3, 3), name = "爆裂者", code = "锁定终结路线：毒爆会波及全场", classId = 5, minLevel = 3, tags = { "offense", "core" }, weight = 90, exclusiveGroup = "class5_path", effects = { { type = "upgrade_skill", skillId = 80005004, skillLevel = 2 }, { type = "stat_add", atk = 1 } } },
    [FeatId(5, 4, 1)] = { id = FeatId(5, 4, 1), name = "属性提升", code = "5e ASI：提高输出与机动", classId = 5, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", atk = 1, speed = 1 } } },
    [FeatId(5, 4, 2)] = { id = FeatId(5, 4, 2), name = "剧毒箭簇", code = "群毒扩散效率进一步提升", classId = 5, minLevel = 4, tags = { "control" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80005003, skillLevel = 3 } } },
    [FeatId(5, 4, 3)] = { id = FeatId(5, 4, 3), name = "收割毒爆", code = "引爆效率更高，收尾更稳定", classId = 5, minLevel = 4, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80005004, skillLevel = 3 } } },
    [FeatId(5, 4, 4)] = { id = FeatId(5, 4, 4), name = "猎隼感知", code = "目标识别与稳定命中增强", classId = 5, minLevel = 4, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", hit = 1, saveWill = 1 } } },
    [FeatId(5, 5, 1)] = { id = FeatId(5, 5, 1), name = "终结毒素", code = "爆裂连段拥有更强的清场终结力", classId = 5, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80005004, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(5, 5, 2)] = { id = FeatId(5, 5, 2), name = "压制连射", code = "单体挂毒与持续压制同步增强", classId = 5, minLevel = 5, tags = { "offense", "core" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80005001, skillLevel = 3 }, { type = "stat_add", atk = 1 } } },
    [FeatId(5, 5, 3)] = { id = FeatId(5, 5, 3), name = "游侠本能", code = "复杂战场中更易维持节奏与站位", classId = 5, minLevel = 5, tags = { "utility", "core" }, weight = 80, effects = { { type = "stat_add", speed = 4, saveRef = 1 } } },

    -- ======================================================================
    -- Class 6 Cleric（牧师）
    -- ======================================================================
    [FeatId(6, 2, 1)] = { id = FeatId(6, 2, 1), name = "急救祷言", code = "Healing Word 可同时照顾两名低血友军", classId = 6, minLevel = 2, tags = { "utility", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 2 }, { type = "stat_add", healBonus = 400 } } },
    [FeatId(6, 2, 2)] = { id = FeatId(6, 2, 2), name = "神圣专注", code = "神术命中与稳定性提升", classId = 6, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", spellDC = 1, saveWill = 1 } } },
    [FeatId(6, 2, 3)] = { id = FeatId(6, 2, 3), name = "惩戒火花", code = "权杖命中后追加少量神圣附伤", classId = 6, minLevel = 2, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80006001, skillLevel = 2 }, { type = "stat_add", atk = 1 } } },
    [FeatId(6, 2, 4)] = { id = FeatId(6, 2, 4), name = "护佑", code = "前中排站位更稳", classId = 6, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(6, 3, 1)] = { id = FeatId(6, 3, 1), name = "生命领域", code = "锁定生命路线：急救附带轻净化并强化治疗", classId = 6, minLevel = 3, tags = { "utility", "core" }, weight = 100, exclusiveGroup = "class6_path", effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 3 }, { type = "stat_add", healBonus = 800 } } },
    [FeatId(6, 3, 2)] = { id = FeatId(6, 3, 2), name = "光辉领域", code = "锁定光辉路线：权杖命中后的神圣附伤更强", classId = 6, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class6_path", effects = { { type = "upgrade_skill", skillId = 80006001, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(6, 3, 3)] = { id = FeatId(6, 3, 3), name = "守护领域", code = "锁定守护路线：复活返场更稳", classId = 6, minLevel = 3, tags = { "defense", "core" }, weight = 80, exclusiveGroup = "class6_path", effects = { { type = "upgrade_skill", skillId = 80006004, skillLevel = 2 }, { type = "stat_add", ac = 1 } } },
    [FeatId(6, 4, 1)] = { id = FeatId(6, 4, 1), name = "属性提升", code = "5e ASI：提高施法与意志", classId = 6, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", spellDC = 1, saveWill = 1 } } },
    [FeatId(6, 4, 2)] = { id = FeatId(6, 4, 2), name = "净化圣言", code = "Healing Word 的净化与治疗收益进一步增强", classId = 6, minLevel = 4, tags = { "utility" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 4 } } },
    [FeatId(6, 4, 3)] = { id = FeatId(6, 4, 3), name = "板甲训练", code = "前线支援能力增强", classId = 6, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, hit = 1 } } },
    [FeatId(6, 4, 4)] = { id = FeatId(6, 4, 4), name = "圣裁引导", code = "命中与神术压制同步提升", classId = 6, minLevel = 4, tags = { "offense" }, weight = 80, effects = { { type = "stat_add", spellDC = 1, atk = 1 } } },
    [FeatId(6, 5, 1)] = { id = FeatId(6, 5, 1), name = "生命恩典", code = "急救圣言的收益来到职业质变节点", classId = 6, minLevel = 5, tags = { "utility", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80006003, skillLevel = 4 }, { type = "stat_add", healBonus = 1200 } } },
    [FeatId(6, 5, 2)] = { id = FeatId(6, 5, 2), name = "复苏恩典", code = "复活返场更稳，虚弱更轻", classId = 6, minLevel = 5, tags = { "defense" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80006004, skillLevel = 3 }, { type = "stat_add", saveWill = 1 } } },
    [FeatId(6, 5, 3)] = { id = FeatId(6, 5, 3), name = "裁决圣火", code = "权杖打击的神圣惩戒来到终盘强度", classId = 6, minLevel = 5, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80006001, skillLevel = 3 }, { type = "stat_add", atk = 1 } } },

    -- ======================================================================
    -- Class 7 Sorcerer（术士 / 火）
    -- ======================================================================
    [FeatId(7, 2, 1)] = { id = FeatId(7, 2, 1), name = "灼痕", code = "火焰箭与点燃稳定性提升", classId = 7, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80007001, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(7, 2, 2)] = { id = FeatId(7, 2, 2), name = "烈线", code = "灼热射线更适合处理中排目标", classId = 7, minLevel = 2, tags = { "offense" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80007003, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(7, 2, 3)] = { id = FeatId(7, 2, 3), name = "余烬护体", code = "脆皮法师在拉锯战中更稳", classId = 7, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(7, 2, 4)] = { id = FeatId(7, 2, 4), name = "咒术熟练", code = "施法稳定性与豁免进一步提升", classId = 7, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", spellDC = 1, saveWill = 1 } } },
    [FeatId(7, 3, 1)] = { id = FeatId(7, 3, 1), name = "爆燃血脉", code = "锁定爆发路线：火球后劲更足", classId = 7, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class7_path", effects = { { type = "upgrade_skill", skillId = 80007004, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(7, 3, 2)] = { id = FeatId(7, 3, 2), name = "灼线血脉", code = "锁定连射路线：灼热射线更强", classId = 7, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class7_path", effects = { { type = "upgrade_skill", skillId = 80007003, skillLevel = 3 }, { type = "stat_add", hit = 1 } } },
    [FeatId(7, 3, 3)] = { id = FeatId(7, 3, 3), name = "余烬血脉", code = "锁定拉锯路线：火焰箭更适合叠层", classId = 7, minLevel = 3, tags = { "utility", "core" }, weight = 90, exclusiveGroup = "class7_path", effects = { { type = "upgrade_skill", skillId = 80007001, skillLevel = 3 }, { type = "stat_add", ac = 1 } } },
    [FeatId(7, 4, 1)] = { id = FeatId(7, 4, 1), name = "属性提升", code = "5e ASI：提高施法与命中", classId = 7, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", spellDC = 1, hit = 1 } } },
    [FeatId(7, 4, 2)] = { id = FeatId(7, 4, 2), name = "灼烧蔓延", code = "射线的持续压制与扩散更强", classId = 7, minLevel = 4, tags = { "offense" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80007003, skillLevel = 3 } } },
    [FeatId(7, 4, 3)] = { id = FeatId(7, 4, 3), name = "炎球专精", code = "火球伤害与点燃回合双提升", classId = 7, minLevel = 4, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80007004, skillLevel = 3 } } },
    [FeatId(7, 4, 4)] = { id = FeatId(7, 4, 4), name = "火焰韧性", code = "提高法师在高压环境中的容错", classId = 7, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", maxHp = 8, saveWill = 1 } } },
    [FeatId(7, 5, 1)] = { id = FeatId(7, 5, 1), name = "炎爆权能", code = "高等级火球成为主要清场支点", classId = 7, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80007004, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(7, 5, 2)] = { id = FeatId(7, 5, 2), name = "烈焰连珠", code = "射线流在长线战斗中更强", classId = 7, minLevel = 5, tags = { "offense", "core" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80007003, skillLevel = 3 }, { type = "stat_add", hit = 1 } } },
    [FeatId(7, 5, 3)] = { id = FeatId(7, 5, 3), name = "灼骨火花", code = "基础火焰箭也具备可靠终结性", classId = 7, minLevel = 5, tags = { "offense", "core" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80007001, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },

    -- ======================================================================
    -- Class 8 Wizard（法师 / 冰）
    -- ======================================================================
    [FeatId(8, 2, 1)] = { id = FeatId(8, 2, 1), name = "寒霜专注", code = "寒霜射线减速与冻结更稳定", classId = 8, minLevel = 2, tags = { "control", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80008001, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(8, 2, 2)] = { id = FeatId(8, 2, 2), name = "冰环构筑", code = "近身控制更稳定，方便护后排", classId = 8, minLevel = 2, tags = { "control" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80008003, skillLevel = 2 }, { type = "stat_add", saveFort = 1 } } },
    [FeatId(8, 2, 3)] = { id = FeatId(8, 2, 3), name = "冰甲", code = "薄弱身板获得额外保护", classId = 8, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(8, 2, 4)] = { id = FeatId(8, 2, 4), name = "冷静", code = "施法豁免与稳定性提升", classId = 8, minLevel = 2, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", saveWill = 1, spellDC = 1 } } },
    [FeatId(8, 3, 1)] = { id = FeatId(8, 3, 1), name = "冻结学派", code = "锁定控制路线：冰环冻结更强", classId = 8, minLevel = 3, tags = { "control", "core" }, weight = 100, exclusiveGroup = "class8_path", effects = { { type = "upgrade_skill", skillId = 80008003, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(8, 3, 2)] = { id = FeatId(8, 3, 2), name = "壁垒学派", code = "锁定阵地路线：暴风雪压制更强", classId = 8, minLevel = 3, tags = { "defense", "core" }, weight = 100, exclusiveGroup = "class8_path", effects = { { type = "upgrade_skill", skillId = 80008004, skillLevel = 2 }, { type = "stat_add", ac = 1 } } },
    [FeatId(8, 3, 3)] = { id = FeatId(8, 3, 3), name = "寒矢学派", code = "锁定点控路线：单体冻结更可靠", classId = 8, minLevel = 3, tags = { "control", "core" }, weight = 90, exclusiveGroup = "class8_path", effects = { { type = "upgrade_skill", skillId = 80008001, skillLevel = 3 }, { type = "stat_add", hit = 1 } } },
    [FeatId(8, 4, 1)] = { id = FeatId(8, 4, 1), name = "属性提升", code = "5e ASI：提高法术与意志", classId = 8, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", spellDC = 1, saveWill = 1 } } },
    [FeatId(8, 4, 2)] = { id = FeatId(8, 4, 2), name = "深寒法印", code = "暴风雪成为更稳定的阵地技", classId = 8, minLevel = 4, tags = { "control" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80008004, skillLevel = 3 } } },
    [FeatId(8, 4, 3)] = { id = FeatId(8, 4, 3), name = "凝滞术式", code = "冰环打断与控场质量提升", classId = 8, minLevel = 4, tags = { "control" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80008003, skillLevel = 3 } } },
    [FeatId(8, 4, 4)] = { id = FeatId(8, 4, 4), name = "霜护躯壳", code = "站桩施法时的安全性更高", classId = 8, minLevel = 4, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", maxHp = 8, ac = 1 } } },
    [FeatId(8, 5, 1)] = { id = FeatId(8, 5, 1), name = "极寒领域", code = "暴风雪进入高压控场阶段", classId = 8, minLevel = 5, tags = { "control", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80008004, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(8, 5, 2)] = { id = FeatId(8, 5, 2), name = "冻结之触", code = "单点冻结能力与命中同步增强", classId = 8, minLevel = 5, tags = { "control", "core" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80008001, skillLevel = 3 }, { type = "stat_add", saveFort = 1 } } },
    [FeatId(8, 5, 3)] = { id = FeatId(8, 5, 3), name = "冰环压制", code = "中距离团控在后期更可靠", classId = 8, minLevel = 5, tags = { "control", "core" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80008003, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },

    -- ======================================================================
    -- Class 9 Warlock（邪术师 / 雷）
    -- ======================================================================
    [FeatId(9, 2, 1)] = { id = FeatId(9, 2, 1), name = "邪能共鸣", code = "邪能冲击与连锁触发更稳定", classId = 9, minLevel = 2, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80009001, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(9, 2, 2)] = { id = FeatId(9, 2, 2), name = "电荷步伐", code = "走位与收尾能力增强", classId = 9, minLevel = 2, tags = { "utility" }, weight = 90, effects = { { type = "stat_add", speed = 3, saveRef = 1 } } },
    [FeatId(9, 2, 3)] = { id = FeatId(9, 2, 3), name = "雷链预演", code = "连锁法术进入中期成长曲线", classId = 9, minLevel = 2, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80009003, skillLevel = 2 }, { type = "stat_add", hit = 1 } } },
    [FeatId(9, 2, 4)] = { id = FeatId(9, 2, 4), name = "静电护盾", code = "法系身板获得额外容错", classId = 9, minLevel = 2, tags = { "defense" }, weight = 80, effects = { { type = "stat_add", ac = 1, maxHp = 8 } } },
    [FeatId(9, 3, 1)] = { id = FeatId(9, 3, 1), name = "连锁契约", code = "锁定连锁路线：中距离跳电更强", classId = 9, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class9_path", effects = { { type = "upgrade_skill", skillId = 80009003, skillLevel = 2 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(9, 3, 2)] = { id = FeatId(9, 3, 2), name = "风暴契约", code = "锁定爆发路线：雷暴更具清场能力", classId = 9, minLevel = 3, tags = { "offense", "core" }, weight = 100, exclusiveGroup = "class9_path", effects = { { type = "upgrade_skill", skillId = 80009004, skillLevel = 2 }, { type = "stat_add", critRate = 300 } } },
    [FeatId(9, 3, 3)] = { id = FeatId(9, 3, 3), name = "诅咒契约", code = "锁定稳定路线：基础邪能冲击更强", classId = 9, minLevel = 3, tags = { "utility", "core" }, weight = 90, exclusiveGroup = "class9_path", effects = { { type = "upgrade_skill", skillId = 80009001, skillLevel = 3 }, { type = "stat_add", hit = 1 } } },
    [FeatId(9, 4, 1)] = { id = FeatId(9, 4, 1), name = "属性提升", code = "5e ASI：提高施法与意志", classId = 9, minLevel = 4, tags = { "utility" }, weight = 100, effects = { { type = "stat_add", spellDC = 1, saveWill = 1 } } },
    [FeatId(9, 4, 2)] = { id = FeatId(9, 4, 2), name = "雷链加深", code = "连锁弹跳数与压制力提升", classId = 9, minLevel = 4, tags = { "offense" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80009003, skillLevel = 3 } } },
    [FeatId(9, 4, 3)] = { id = FeatId(9, 4, 3), name = "风暴共鸣", code = "雷暴额外跳电更具威慑力", classId = 9, minLevel = 4, tags = { "offense" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80009004, skillLevel = 3 } } },
    [FeatId(9, 4, 4)] = { id = FeatId(9, 4, 4), name = "不羁步伐", code = "复杂战场中的拉扯能力提升", classId = 9, minLevel = 4, tags = { "utility" }, weight = 80, effects = { { type = "stat_add", speed = 4, saveRef = 1 } } },
    [FeatId(9, 5, 1)] = { id = FeatId(9, 5, 1), name = "超载邪能", code = "基础邪能冲击成长为可靠主力", classId = 9, minLevel = 5, tags = { "offense", "core" }, weight = 100, effects = { { type = "upgrade_skill", skillId = 80009001, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },
    [FeatId(9, 5, 2)] = { id = FeatId(9, 5, 2), name = "雷暴权能", code = "终局清场时拥有更高爆发上限", classId = 9, minLevel = 5, tags = { "offense", "core" }, weight = 90, effects = { { type = "upgrade_skill", skillId = 80009004, skillLevel = 3 }, { type = "stat_add", critRate = 300 } } },
    [FeatId(9, 5, 3)] = { id = FeatId(9, 5, 3), name = "连锁支配", code = "中距离跳电收束能力更强", classId = 9, minLevel = 5, tags = { "offense", "core" }, weight = 80, effects = { { type = "upgrade_skill", skillId = 80009003, skillLevel = 3 }, { type = "stat_add", spellDC = 1 } } },
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
