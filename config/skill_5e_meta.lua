-- Centralized 5e meta for skills.
-- This avoids inferring behavior from "targets count" at runtime and keeps the rules explicit.

---@alias Skill5eMetaKind
---| "physical"
---| "spell"
---| "auto"

---@alias Skill5eSaveType
---| "fort"
---| "ref"
---| "will"

---@alias Skill5eOnSaveSuccess
---| "half"
---| "none"

---@class Skill5eMetaEntry
---@field kind Skill5eMetaKind
---@field saveType Skill5eSaveType|nil
---@field onSaveSuccess Skill5eOnSaveSuccess|nil
---@field isAOE boolean|nil
---@field hardControl boolean|nil
---@field damageDice string|nil
---@field healDice string|nil
---@field chainDice string|nil
---@field diceScale number|nil
---@field chantTurns integer|nil
---@field concentration boolean|nil
---@field revivePct number|nil
---@field revivePenaltyTurns integer|nil
---@field revivePenaltyAtkMul number|nil
---@field revivePenaltyDefMul number|nil
---@field revivePenaltySpeedMul number|nil
---@field role string|nil                -- concise combat role summary
---@field notes string|nil               -- explicit 5e-facing rules note
---@field tierNotes table<integer, string>|nil -- skill.level => what changes in runtime

---@class Skill5eMetaModule
---@field Get fun(skillId: integer): Skill5eMetaEntry

---@type Skill5eMetaModule
local Skill5eMeta = {}

-- Default dice scale for 5e-style small numbers.
local DEFAULT_DICE_SCALE = 1

-- Meta schema:
-- kind: "physical" | "spell" | "auto"
-- saveType: "fort"|"ref"|"will"  (spell only)
-- onSaveSuccess: "half"|"none"   (spell only, default depends on isAOE/hardControl)
-- isAOE: boolean                 (spell only, influences default onSaveSuccess)
-- hardControl: boolean           (spell only; success => immune to control tags)
-- damageDice: string             (optional; dice expr. If omitted, uses base dice.)
-- diceScale: number              (optional; default 100)
-- chantTurns: number             (optional; 0 default)
-- concentration: boolean         (optional; false default)
-- role/notes/tierNotes: documentation-only fields for UI/design/debug sync.
-- They do not affect runtime resolution unless another system reads them explicitly.

---@type table<integer, Skill5eMetaEntry>
local OVERRIDES = {
    -- Rogue Build
    [80001011] = {
        kind = "physical",
        damageDice = "1d8",
        role = "盗贼基础武器攻击",
        notes = "盗贼 Build 主轴动作。单体近战武器攻击，偷袭、穿行突刺和处决打击都围绕这一母技能结算。",
        tierNotes = {
            [1] = "标准版：单体近战武器攻击。",
        },
    },
    [80001013] = {
        kind = "physical",
        damageDice = "1d8",
        role = "处决打击",
        notes = "刺客子职主动。对当前目标发动一次基础武器攻击；若目标生命不高于一半，再追加 2d6 处决伤害。",
        tierNotes = {
            [1] = "基础版：当前目标基础武器攻击，半血目标额外吃 2d6。",
        },
    },
    [80001014] = {
        kind = "physical",
        damageDice = "1d8",
        role = "扰乱飞刃",
        notes = "诡术师子职主动。对后排目标发动一次基础武器攻击；若命中，目标 AC -1 直到下回合开始前。",
        tierNotes = {
            [1] = "基础版：后排定点压制并制造 AC 破绽。",
        },
    },
    [80001015] = {
        kind = "physical",
        damageDice = "1d8",
        role = "穿行突刺",
        notes = "游斗者子职主动。可指定任意敌人发动一次基础武器攻击；该次攻击视为满足偷袭条件。",
        tierNotes = {
            [1] = "基础版：稳定兑现一次强制偷袭窗口。",
        },
    },
    [80001101] = {
        kind = "auto",
        role = "盗贼被动：偷袭",
        notes = "每回合一次的职业主轴爆发。目标被控制，或前排夹击成立时，基础武器攻击命中后追加偷袭伤害。",
        tierNotes = {
            [1] = "基础版：追加 1d6；后续通过专精与 capstone 继续加骰。",
        },
    },
    [80001108] = {
        kind = "auto",
        role = "盗贼被动：Uncanny Dodge",
        notes = "Lv5 共用保命被动。每回合第一次被攻击命中时，受到伤害减半；不同 capstone 再追加各自后续收益。",
        tierNotes = {
            [1] = "基础版：首次受击减半。",
        },
    },
    -- Rogue
    [80001001] = {
        kind = "physical",
        damageDice = "8",
        role = "高爆发单体起手",
        notes = "盗贼基础背刺。按武器命中结算，附带额外暴击率；高阶会引入毒压制，形成收割窗口。",
        tierNotes = {
            [1] = "基础版：单体伤害并附加 20% 暴击率。",
            [2] = "进阶版：暴击率增益提高到 30%，更稳定触发爆发窗口。",
            [3] = "高阶版：在进阶版基础上，命中后附加 1 层中毒。",
        },
    },
    [80001003] = {
        kind = "physical",
        damageDice = "8",
        role = "锁定残血并触发追击",
        notes = "主动收割技。优先攻击最低血敌人，击杀后触发追击；高阶增加减速与中毒控制层。",
        tierNotes = {
            [1] = "基础版：优先锁定最低血目标，击杀触发追击。",
            [2] = "进阶版：附带轻度减速，增强后续收割稳定性。",
            [3] = "高阶版：在减速基础上再附加 1 层中毒。",
        },
    },
    [80001004] = {
        kind = "physical",
        damageDice = "5",
        role = "多段随机收割",
        notes = "终结型多段攻击。通过 random_hits_damage 对敌方进行多次随机命中，每次击杀都可衔接追击。",
        tierNotes = {
            [1] = "基础版：2 段随机命中，支持击杀后追击。",
            [2] = "进阶版：命中段数提高到 3。",
            [3] = "高阶版：命中段数提高到 4。",
        },
    },
    [80001002] = {
        kind = "auto",
        role = "盗贼被动：追击/精通/闪避",
        notes = "被动技能（不走技能时间线）。战斗开始时（>=2级）获得 hit+1（简化 Expertise）；>=5级后每回合第一次被单体伤害命中时减半（简化 Uncanny Dodge）。追击本身由技能 tag `pursuit_on_kill` 驱动，以保持体系一致性。",
        tierNotes = {
            [1] = "被动：随等级解锁命中加成与每回合一次的减伤；追击由技能 tag 触发。",
        },
    },

    -- Fighter / Defender
    [80002001] = {
        kind = "physical",
        damageDice = "1d8",
        role = "战士基础武器攻击",
        notes = "战士主轴动作。单体近战物理攻击，所有反击、连击、额外攻击都复用这一母技能完成结算。",
        tierNotes = {
            [1] = "标准版：单体近战物理攻击。",
        },
    },
    [80002003] = {
        kind = "physical",
        damageDice = "7",
        role = "动作激增",
        notes = "战士共享主动爆发。CD3，立刻追加 1 次基础武器攻击，目标重新选择；不影响该回合原本的普通攻击。",
        tierNotes = {
            [1] = "标准版：立刻追加 1 次可重选目标的基础武器攻击。",
        },
    },
    [80002004] = {
        kind = "physical",
        damageDice = "7",
        role = "旧战士保留技能",
        notes = "旧战士链路保留条目。新战士 Build 管线不再使用该技能承载任何路线能力。",
        tierNotes = {
            [1] = "兼容模式：仅供旧链路兜底。",
        },
    },
    [80002002] = {
        kind = "auto",
        role = "旧战士兼容被动",
        notes = "旧战士实现的兼容条目。新战士 Build 管线不再依赖该技能承载 Action Surge、Second Wind、Extra Attack 等全部职业特性。",
        tierNotes = {
            [1] = "兼容模式：仅供旧链路保底使用。",
        },
    },
    [80002005] = {
        kind = "auto",
        role = "护卫架势",
        notes = "护卫路线代表动作。CD3，进入持续到下回合开始的护卫窗口；期间你和友军被攻击时获得 AC+2，并减少等同熟练加值的伤害；若攻击者为近战单位，则在其攻击结算后发动 1 次护卫反击。",
        tierNotes = {
            [1] = "标准版：开启 AC+2、自保减伤与近战护卫反击窗口。",
        },
    },

    -- Monk (Melee skirmisher / control)
    [80003001] = {
        kind = "physical",
        damageDice = "8",
        role = "单体连击起手，触发额外追打",
        notes = "武僧基础武艺攻击。命中后会通过 combo 框架尝试追加一段小型追击；仍按近战武器攻击处理。",
        tierNotes = {
            [1] = "基础版：单体伤害，命中后按 combo 规则尝试追加一次追打。",
            [2] = "进阶版：基础伤害提高，并在出手前获得额外暴击率。",
            [3] = "高阶版：在进阶版基础上进一步提高伤害，作为武僧稳定单点主力。",
        },
    },
    [80003003] = {
        kind = "auto",
        healDice = "2d8+4",
        role = "自疗与自我解控",
        notes = "非攻击型动作。回复自身生命并清除冻结、眩晕、沉默等关键控制，体现短休式调息。",
        tierNotes = {
            [1] = "基础版：自疗并清除常见硬控/施法限制。",
            [2] = "进阶版：治疗骰提升到 2d8+3，增强中盘续航。",
            [3] = "高阶版：治疗骰提升到 2d8+6，作为高压环境下的稳定返场按钮。",
        },
    },
    [80003004] = {
        kind = "spell",
        saveType = "fort",
        hardControl = true,
        onSaveSuccess = "half",
        damageDice = "3d8+4",
        role = "重击穿透与单体硬控",
        notes = "以强体术冲击目标，豁免类型为 fort。失败时施加冻结型硬控 buff，成功仍承受半伤。",
        tierNotes = {
            [1] = "基础版：高伤单体终结技，命中后附带 1 回合冻结。",
            [2] = "进阶版：伤害显著提高，更偏向 Open Hand/控制路线。",
            [3] = "高阶版：进一步提高伤害，并在出手前获得额外暴击率。",
        },
    },
    [80003002] = {
        kind = "auto",
        role = "武僧被动：连击精通",
        notes = "被动技能（不走技能时间线）。战斗开始时写入 `comboMasterMinRate = 5000`，将连击追加伤害的最小触发概率提升到 50%（用于稳定武僧的连击节奏）。",
        tierNotes = {
            [1] = "被动：将连击触发底线提高到 50%。",
        },
    },
    [80003011] = {
        kind = "physical",
        damageDice = "8",
        role = "武僧基础徒手攻击",
        notes = "新 Build 管线的武僧母技能。所有武艺、额外攻击和 Lv3 主动都围绕该徒手攻击展开。",
    },
    [80003013] = {
        kind = "physical",
        damageDice = "8",
        role = "震劲掌",
        notes = "对当前目标执行 1 次徒手打击；命中后再检定强韧豁免，失败则 STUN 1 回合。",
    },
    [80003014] = {
        kind = "physical",
        damageDice = "6",
        role = "影步连打",
        notes = "对任意目标执行 1 次徒手打击；若目标位于后排，追加 1d8 伤害。",
    },
    [80003015] = {
        kind = "auto",
        healDice = "2d8+4",
        role = "调息自愈",
        notes = "回复自身生命并清除关键控制，作为武僧的续战按钮。",
    },

    -- Paladin (frontline support / smite / aura)
    [80004001] = {
        kind = "physical",
        damageDice = "8",
        role = "前线单体惩击",
        notes = "圣武士的近战基础打击。按武器攻击结算，代表 Divine Smite 风格的稳定单体输出。",
        tierNotes = {
            [1] = "基础版：稳定单体物理打击。",
            [2] = "进阶版：基础伤害提高，作为誓约路线的通用前线动作。",
            [3] = "高阶版：伤害再提高，并获得额外暴击率，增强终结能力。",
        },
    },
    [80004003] = {
        kind = "physical",
        concentration = true,
        damageDice = "2",
        role = "团队战意灵光",
        notes = "属于持续型团队增益动作。开启后进入专注，给友军施加 battle intent buff；skill.level 主要延长持续回合。",
        tierNotes = {
            [1] = "基础版：开启团队战意 buff，并进入专注。",
            [2] = "进阶版：buff 持续时间 +1 回合。",
            [3] = "高阶版：buff 持续时间再 +1 回合，更适合拉锯战。",
        },
    },
    [80004004] = {
        kind = "auto",
        healDice = "3d8+6",
        role = "强力单体急救",
        notes = "圣武士的大型治疗动作，偏 Lay on Hands 风格。主要承担保坦、救急和队伍稳态恢复。",
        tierNotes = {
            [1] = "基础版：高额单体治疗。",
            [2] = "进阶版：治疗数值提升，更适合守护路线。",
            [3] = "高阶版：治疗再次提升，成为后期前排返场核心按钮。",
        },
    },
    [80004002] = {
        kind = "auto",
        role = "圣武士被动：战意叠层",
        notes = "被动技能（不走技能时间线）。击杀敌人后为自身叠加 `战意(840001)`，最多 5 层。战意层数会被战斗公式用于提高输出/生存/治疗等相关结算（按模块内的 5e 风味规则进行缩放）。",
        tierNotes = {
            [1] = "被动：击杀叠战意（上限5），战意影响多项战斗结算。",
        },
    },
    [80004011] = {
        kind = "physical",
        damageDice = "7",
        role = "圣武士基础武器攻击",
        notes = "新 Build 管线的圣武士母技能。用于触发神圣惩击、额外攻击和各类誓约强化。",
    },
    [80004013] = {
        kind = "auto",
        healDice = "2d8+4",
        role = "圣疗之手",
        notes = "为生命最低的友军回复生命并清除关键负面状态。",
    },
    [80004014] = {
        kind = "physical",
        damageDice = "7",
        role = "复仇裁击",
        notes = "先执行 1 次基础武器攻击；若命中，再追加 2d8 光耀伤害。",
    },
    [80004015] = {
        kind = "auto",
        role = "守护灵光",
        notes = "直到你下回合开始前，为我方全体提供 AC 加成与首次受击减伤。",
    },

    -- Ranger / Venom hunter (damage-over-time / burst conversion)
    [80005001] = {
        kind = "physical",
        damageDice = "6",
        role = "单体挂毒起手",
        notes = "游侠/毒猎人的基础攻击。按武器攻击结算，并在命中后追加中毒层数，服务于后续引爆。",
        tierNotes = {
            [1] = "基础版：单体命中后附加 1 层中毒。",
            [2] = "进阶版：伤害提高，并附加 2 层中毒。",
            [3] = "高阶版：伤害进一步提高，并附加 3 层中毒。",
        },
    },
    [80005003] = {
        kind = "physical",
        damageDice = "6",
        role = "随机多目标挂毒",
        notes = "中距离扩散技。随机命中多个敌人并叠加毒层，为毒爆路线铺垫全场引爆条件。",
        tierNotes = {
            [1] = "基础版：随机命中 3 个目标并附加 2 层中毒。",
            [2] = "进阶版：目标数提高到 4，伤害略升。",
            [3] = "高阶版：目标数提高到 5，同时每个目标附加 3 层中毒。",
        },
    },
    [80005004] = {
        kind = "physical",
        damageDice = "7",
        role = "中毒引爆终结",
        notes = "将目标身上的中毒层数转化为即时伤害并清空毒层。高阶后可转为对全体存活敌人执行引爆检查。",
        tierNotes = {
            [1] = "基础版：只对当前目标执行中毒引爆。",
            [2] = "进阶版：改为对全体存活敌人执行中毒引爆，形成清场终结。",
            [3] = "高阶版：延续全场引爆模型，主要由前置挂毒技能提供更高收益。",
        },
    },
    [80005002] = {
        kind = "auto",
        role = "游侠被动：感染加深",
        notes = "被动技能（不走技能时间线）。在自身回合开始时对敌方全体执行“感染”检查：若目标已有中毒（850001），则额外叠加 1 层中毒（相当于让毒层随时间自然加深）。",
        tierNotes = {
            [1] = "被动：回合开始时让所有已中毒敌人额外+1层毒。",
        },
    },
    [80005011] = {
        kind = "physical",
        damageDice = "6",
        role = "游侠基础远程攻击",
        notes = "新 Build 管线的游侠母技能。围绕猎人印记、额外攻击和子职射击展开。",
    },
    [80005013] = {
        kind = "physical",
        damageDice = "6",
        role = "猎杀箭",
        notes = "先执行 1 次远程基础攻击；若目标带有猎人印记，再追加 2d6 伤害。",
    },
    [80005014] = {
        kind = "physical",
        damageDice = "6",
        role = "暮影射击",
        notes = "对任意敌人执行 1 次远程基础攻击；若目标位于后排，再追加 1d8 伤害。",
    },
    [80005015] = {
        kind = "physical",
        damageDice = "6",
        role = "缠绕箭",
        notes = "对任意敌人执行 1 次远程基础攻击；命中后若目标反射豁免失败，则冻结 1 回合近似表达 Restrained。",
    },

    -- Cleric / Holy
    -- Note: holy skills use custom handlers for ally heal / enemy damage.
    -- We still define heal dice here so runtime can stay free of MaxHP% healing.
    [80006011] = {
        kind = "physical",
        damageDice = "1d8",
        role = "牧师基础神术",
        notes = "新 Build 管线的牧师母技能。使用 spellDC 派生的法术攻击加值进行单体远程神术攻击；后续裁断祷文、神术专精与 Blessed Strikes 都围绕它触发。",
    },
    [80006012] = {
        kind = "auto",
        healDice = "1d8",
        role = "治愈之言",
        notes = "每场战斗 1 次，自动治疗生命最低友军。基础值为 1d8 + 等级，后续可被复苏祷文、治疗专精与慈恩主教继续增强。",
    },
    [80006013] = {
        kind = "auto",
        healDice = "1d8+4",
        role = "群愈祷言",
        notes = "生命领域主动。为生命最低的两名友军各回复 1d8 + 4 生命；可继续叠加治疗专精与慈恩主教。",
    },
    [80006014] = {
        kind = "physical",
        damageDice = "1d8",
        role = "圣焰裁决",
        notes = "光明领域主动。先发动 1 次基础神术；若命中，再追加 2d6 光耀伤害。",
    },
    [80006015] = {
        kind = "auto",
        role = "圣域祷言",
        notes = "守护领域主动。持续到施法者下回合开始；期间我方全体 AC +1，且各自第一次受到的伤害减少 1d6。圣域专精可再提高 AC。",
    },
    [80006109] = {
        kind = "auto",
        role = "圣焰主教",
        notes = "每回合第一次基础神术命中后，额外造成 1d8 光耀伤害。",
    },
    [80006110] = {
        kind = "auto",
        role = "慈恩主教",
        notes = "每回合第一次回复友军生命时，额外再回复 1d6 生命。",
    },
    [80006111] = {
        kind = "auto",
        role = "守望主教",
        notes = "每回合第一次基础神术命中后，直到你下回合开始，我方前排 AC +1。",
    },
    [80006001] = {
        kind = "physical",
        role = "牧师近战武器打击",
        notes = "牧师基础动作。始终对敌方执行近战武器攻击，符合 5e Cleric 使用权杖/钉头锤近战作战的定位。神圣附伤由 feat 驱动的 skill.level 提供，不再承担治疗职责。",
        tierNotes = {
            [1] = "基础版：稳定近战武器伤害。",
            [2] = "进阶版：命中后追加少量神圣附伤，体现光辉路线的惩戒感。",
            [3] = "高阶版：神圣附伤进一步提高；若本回合神术强化尚未消耗，则附伤再增强。",
        },
    },
    [80006002] = {
        kind = "auto",
        role = "牧师被动：神术强化",
        notes = "被动技能（不走技能时间线）。战斗开始与自身每回合开始时获得一次“神术强化”准备状态；本回合第一次关键神术会消耗该状态并获得额外收益。",
        tierNotes = {
            [1] = "被动：每回合首次神术获得强化，不再提供全队常驻 HOT。",
        },
    },
    [80006003] = {
        kind = "auto",
        healDice = "2d8+5",
        role = "急救圣言",
        notes = "主动急救技。优先治疗最低血友军，强调保命与拉血线，而不是大范围抬全队。高阶后最多同时照顾 2 人，并附带轻净化。",
        tierNotes = {
            [1] = "基础版：治疗最低血的 1 名友军。",
            [2] = "进阶版：治疗最低血的 2 名友军。",
            [3] = "高阶版：仍治疗 2 名友军，并净化中毒/燃烧。",
            [4] = "顶阶版：在高阶基础上进一步提高治疗收益，适合生命领域终盘强化。",
        },
    },
    [80006004] = {
        kind = "auto",
        revivePct = 0.20,
        revivePenaltyTurns = 2,
        revivePenaltyAtkMul = 0.75,
        revivePenaltyDefMul = 0.75,
        revivePenaltySpeedMul = 0.80,
        role = "返场复苏",
        notes = "次数制返场神术。复活最近阵亡的友军，但会附带复活虚弱与一次行动跳过。高阶后提高返场血量并减轻虚弱惩罚。",
        tierNotes = {
            [1] = "基础版：20% 生命返场，虚弱持续 2 回合。",
            [2] = "进阶版：25% 生命返场，虚弱缩短到 1 回合且惩罚减轻。",
            [3] = "高阶版：30% 生命返场，保留 1 回合轻度虚弱，强调守护路线的返场稳定性。",
        },
    },

    -- Sorcerer (Fire)
    [80007001] = {
        kind = "auto",
        damageDice = "2d8+2",
        role = "稳定点燃的基础火焰箭",
        notes = "基础远程火系法术。命中后附加燃烧；高阶提升燃烧层数与持续回合，适合作为 DoT 铺垫。",
        tierNotes = {
            [1] = "基础版：单体火焰伤害并附加 1 层燃烧，持续 2 回合。",
            [2] = "进阶版：伤害提高，燃烧层数提高到 2。",
            [3] = "高阶版：伤害进一步提高，燃烧持续时间延长到 3 回合。",
        },
    },
    [80007003] = {
        kind = "spell",
        saveType = "ref",
        isAOE = true,
        onSaveSuccess = "half",
        damageDice = "2d6+2",
        role = "多目标灼热射线",
        notes = "以多束火线分摊到随机敌人，适合处理中后排与叠加全队燃烧压力。",
        tierNotes = {
            [1] = "基础版：随机命中 3 个敌人并附加燃烧。",
            [2] = "进阶版：目标数提高到 4，伤害提升。",
            [3] = "高阶版：目标数提高到 5，燃烧持续时间延长到 3 回合。",
        },
    },
    [80007004] = {
        kind = "spell",
        saveType = "ref",
        isAOE = true,
        onSaveSuccess = "half",
        damageDice = "4d6+5",
        chantTurns = 1,
        role = "大范围火球清场",
        notes = "典型 5e 火球型大招。全体范围法术，反射豁免成功仍吃半伤，并附加多层燃烧。",
        tierNotes = {
            [1] = "基础版：全体火球，附加 2 层燃烧。",
            [2] = "进阶版：伤害提高，燃烧持续时间延长到 3 回合，燃烧层数提高到 3。",
            [3] = "高阶版：伤害再提高，燃烧层数提高到 4，成为主要清场支点。",
        },
    },
    [80007002] = {
        kind = "auto",
        role = "火焰亲和（被动）",
        notes = "被动技能（不走技能时间线）。在自身回合开始确保自身带 `火焰亲和(870002)`：\n- 火系伤害 +15%（仅当技能标记为 fire damageKind）。\n- 由该角色施加的燃烧持续时间 +1 回合（ApplyBurn 规则）。",
        tierNotes = {
            [1] = "被动：维持火焰亲和 buff，强化火伤与燃烧持续。",
        },
    },

    -- Wizard (Ice)
    [80008001] = {
        kind = "spell",
        saveType = "ref",
        isAOE = false,
        hardControl = false,
        onSaveSuccess = "half",
        damageDice = "2d8+4",
        role = "单体减速/冻结射线",
        notes = "冰法基础点控法术。默认提供减速，高阶后会转为附带冻结回合的稳定单控。",
        tierNotes = {
            [1] = "基础版：单体伤害并附加减速。",
            [2] = "进阶版：伤害提高，减速幅度增加。",
            [3] = "高阶版：伤害再提高，并附加 1 回合冻结。",
        },
    },
    [80008003] = {
        kind = "spell",
        saveType = "ref",
        isAOE = true,
        hardControl = true,
        onSaveSuccess = "half",
        damageDice = "2d6+3",
        role = "近中距离群体冻结",
        notes = "范围冰环控制技。失败目标会进入冻结；成功目标仍吃半伤，但免于硬控。",
        tierNotes = {
            [1] = "基础版：范围伤害并冻结 1 回合。",
            [2] = "进阶版：伤害提高，减速进一步增加。",
            [3] = "高阶版：冻结时间延长到 2 回合，成为主要控场技能。",
        },
    },
    [80008004] = {
        kind = "spell",
        saveType = "ref",
        isAOE = true,
        hardControl = true,
        onSaveSuccess = "half",
        damageDice = "3d6+4",
        chantTurns = 1,
        role = "全场暴风雪压制",
        notes = "大范围冰系终结法术。对全体敌人进行反射豁免判定，并按概率附加冻结/重减速。",
        tierNotes = {
            [1] = "基础版：全体伤害，35% 基础概率附加冻结。",
            [2] = "进阶版：伤害提高，冻结概率提升到 45%。",
            [3] = "高阶版：伤害再提高，冻结概率提升到 55%，减速幅度同步提高。",
        },
    },
    [80008002] = {
        kind = "auto",
        role = "寒冰专注（被动）",
        notes = "被动技能（不走技能时间线）。战斗开始时写入被动运行时参数：\n- `iceDamageBonusPct = 1000`（冰系伤害+10%）\n- `iceFreezeChanceBonus = 1000`（冻结概率+10%）\n由冰系技能通过 tag `set_damage_rate_passive` / `chance_apply_freeze` 读取并生效。",
        tierNotes = {
            [1] = "被动：冰伤+10%，冻结概率+10%。",
        },
    },

    -- Warlock / Thunder caster
    [80009001] = {
        kind = "spell",
        saveType = "ref",
        isAOE = false,
        onSaveSuccess = "half",
        damageDice = "2d8+4",
        chainDice = "1d6+1",
        role = "单体邪能冲击并概率跳电",
        notes = "基础远程雷击。命中后有机会触发额外连锁闪电；高阶时连锁概率和跳电次数都会增加。",
        tierNotes = {
            [1] = "基础版：20% 概率触发 1 次跳电。",
            [2] = "进阶版：伤害提高，跳电概率提高到 30%，跳电次数提高到 2。",
            [3] = "高阶版：伤害再提高，跳电概率提高到 40%，跳电次数提高到 3。",
        },
    },
    [80009003] = {
        kind = "spell",
        saveType = "ref",
        isAOE = true,
        onSaveSuccess = "half",
        damageDice = "2d6+3",
        role = "中距离连锁闪电",
        notes = "以首目标为起点的跳电法术。skill.level 直接提高连锁弹跳目标数与每跳伤害。",
        tierNotes = {
            [1] = "基础版：连锁命中 4 个目标。",
            [2] = "进阶版：连锁目标数提高到 5，单跳伤害上升。",
            [3] = "高阶版：连锁目标数提高到 6，作为主要中盘清线技。",
        },
    },
    [80009004] = {
        kind = "spell",
        saveType = "ref",
        isAOE = true,
        onSaveSuccess = "half",
        damageDice = "3d6+4",
        chantTurns = 1,
        chainDice = "1d6+1",
        role = "全场雷暴并追加跳电",
        notes = "后期全场雷系大招。先对所有敌人造成范围伤害，再追加连锁跳电作为收束输出。",
        tierNotes = {
            [1] = "基础版：全体伤害后追加 2 次跳电。",
            [2] = "进阶版：伤害提高，跳电次数提高到 3。",
            [3] = "高阶版：伤害再提高，跳电次数提高到 4，清场能力显著增强。",
        },
    },
    [80009002] = {
        kind = "auto",
        role = "祷言/启示（被动）",
        notes = "被动技能（不走技能时间线）。战斗开始时写入雷系被动运行时参数：\n- `thunderChainChanceBonus = 2000`（连锁触发概率+20%）\n- `thunderChainDecayReductionPct = 1000`（弹射衰减减免预留值，当前主要用于未来扩展）",
        tierNotes = {
            [1] = "被动：提高雷系连锁触发概率，预留衰减优化参数。",
        },
    },
}

local function resolveDefault(skillId)
    local classId = math.floor((tonumber(skillId) or 0) / 100) * 100
    if classId >= 80006000 and classId <= 80009000 then
        -- Spell classes by ID range: 80006xxx..80009xxx
        return { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half" }
    end
    return { kind = "physical" }
end

function Skill5eMeta.Get(skillId)
    local id = tonumber(skillId) or 0
    local meta = OVERRIDES[id] or resolveDefault(id)
    -- Ensure defaults.
    if meta.diceScale == nil then
        meta.diceScale = DEFAULT_DICE_SCALE
    end
    if meta.chantTurns == nil then
        meta.chantTurns = 0
    end
    if meta.concentration == nil then
        meta.concentration = false
    end
    if meta.kind == "spell" then
        if meta.isAOE == nil then meta.isAOE = false end
        if meta.hardControl == nil then meta.hardControl = false end
        if meta.onSaveSuccess == nil then
            -- Project rule: AOE defaults to half, hard control defaults to none.
            meta.onSaveSuccess = meta.isAOE and "half" or "half"
            if meta.hardControl and not meta.isAOE then
                meta.onSaveSuccess = "none"
            end
        end
        if meta.saveType == nil then
            meta.saveType = "ref"
        end
    end
    return meta
end

return Skill5eMeta
