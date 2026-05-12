---
--- Battle Enums
--- Copied from Assets/Lua/Modules/Battle/BattleEnum.lua
---

E_SKILL_TYPE_NORMAL = 1
E_SKILL_TYPE_ACTIVE = 2    -- 主动技能
-- Legacy name kept for compatibility. In the 5e refactor we no longer have "ultimate".
-- Value 3 is treated as "limited-use" (per-rest charges) skill.
E_SKILL_TYPE_ULTIMATE = 3
E_SKILL_TYPE_LIMITED = 3
E_SKILL_TYPE_PASSIVE = 4
E_SKILL_TYPE_COLLECT = 5
E_SKILL_TYPE_HIDE = 9

E_BATTLE_STATE =
{
    PREPARE = 0,
    BEFORE_BATTLE = 1,
    IN_BATTLE = 2,
    PREPARE_END_BATTLE = 3,
    AFTER_BATTLE = 4,
    FINI_BATTLE = 5,
}

E_CAST_TARGET = {
    NA = 0,
    Enemy = 1,
    Self = 2,
    Alias = 3,
    AlliesExcludeSelf = 4,
    AliasIncludeCollect = 5,
    EveryOne = 7,
    EveryOneExcludeSelf = 8,
    Pos = 9,
    MainTarget1 = 10,
    MainTarget2 = 11,
    MainTarget3 = 12,
    MainTarget4 = 13,
    MainTarget5 = 14,
    AliasPos = 15,
    EnemyPos = 16,
    EveryOneIncludeCollect = 17,
    AlliesExcludeSelfDied = 18,
    RefereeLeft = 19,
    RefereeRight = 20,
}

E_MEASURE_TYPE = {
    NA = 0,
    Row = 1,
    Muti = 2,
    Contra = 3,
    AOE = 4,
    Buff = 5,
    HeroId = 6,
    ContraAOE = 7,
}

E_CONDITION_DIRECTION = {
    NA = 0,
    Order = 1,
    Reverse = 2,
    ALL = 3,
}

E_CONDITION_FILTER = {
    Random = 0,
    Property = 2,
    Buff = 3,
    Damage = 4,
    WPType = 5,
    BuffMainType = 6,
}

E_CSV_SKILL_ASSOCIATE = {
    NA = 0,
    Param1 = 1,
    Param2 = 2,
    Param3 = 3,
    Param4 = 4,
}

E_TRIGGER_TYPE = {
    None = 0,
    Damage = 1,
    Heal = 2,
    Dispel = 3,
    Convert = 4,
    Energy = 5,
    Actionforce = 6,
}

E_CAMP_TYPE = {
    None = 0,
    A = 1,
    B = 2,
    C = 3,
}

E_MOTION_TYPE = {
    Immovability = 1,
    Missile = 3,
    BoundMissile = 4,
    Chain = 14,
}

E_MOVE_TYPE = {
    Linear = 0,
    Parabolic = 1,
    Bezier = 2,
    CubicBezier = 3,
}

E_ATTACH_TYPE = {
    None = 0,
    Bone = 1,
    Relative = 2,
    Space = 3,
    HpPoint = 4,
}

E_ATTACK_TYPE = {
    Physical = 1,
    Magic = 2,
}

E_BUFF_TYPE = {
    GOOD = 1,
    BAD = 2,
    CONTROL = 3,
    NOT_GOOD_OR_BAD = 9
}

E_ENERGY_TYPE = {
    Bar = 1,
    Point = 2,
}

E_BINDING_TYPE = {
    Follow = 0,
    Attach = 1,
    AttachPosition = 2,
    FixOnModel = 3,
    FollowPosition = 4,
}

E_LAYER_TARGET = {
    NA = 0,
    Targets = 1,
    Self = 2,
    ForeLayer = 3,
    Arena = 4,
    Camera = 5,
    TargetBattleFieldPos = 6,
    SelfBattleFieldPos = 7,
    TargetsPos = 8,
}

E_PLACE_TYPE = {
    Row_0 = 100,
    Row_1 = 101,
    Row_2 = 102,
    Row_3 = 103,
    Center = 201,
    Ground = 301,
    CenterBattle = 401,
}

E_SKILL_CONDITION = {
    Round = 1,
    EnemyRowCount = 2,
    FriendDiedNumLargerThan = 3,
}

E_LAUNCH_SHOW_METHOD = {
    Hide = 0,
    Show = 1,
}

E_PASSIVE_SKILL_TRIGGER_TIME = {
    BuffChg = 1,
    DmgMakeKill = 2,
    BattleBegin = 3,
    AtkBeforeDmgCalc = 4,
    AtkBeforeDmg = 5,
    DefBeforeDmgCalc = 6,
    DefBeforeDmg = 7,
    SelfTurnEnd = 8,
    Died = 9,
    DefAfterDmg = 10,
    NormalAtkFinish = 11,
    FriendAfterDmg = 12,
    AtkBeforeHealCalc = 13,
    SelfTurnBegin = 14,
    FriendTurnBegin = 15,
    NormalAtkStart = 16,
    FriendNormalAtkStart = 17,
    CasterBuff = 18,
    ReceiveBuff = 19,
    AtkBeforeDotDmg = 20,
    DefBeforeDotDmg = 21,
    DefAfterHeal = 22,
    HpChg = 25,
    CriticalRateChg = 27,
    DmgMakeDeath = 28,
    DmgCauseDeath = 29,
    FriendAtkBeforeDmg = 30,
    AtkBeforeDotDmgCalc = 31,
    TurnEndAddEnergy = 32,
    FriendDmgMakeDeath = 33,
    FriendDmgCauseDeath = 34,
    EnterBuffSubType = 35,
    LeaveBuffSubType = 36,
    Dying = 37,
    Revive = 38,
    FriendCasterBuff = 39,
    FriendReceiveBuff = 40,
    CollectAtkStart = 41,
    CollectAtkFinish = 42,
    DefBeforeDotDmgCalc = 43,
    EnemyDefBeforeDotDmgCalc = 44,
    DefAfterBurnDmg = 45,
    EnemyDefAfterBurnDmg = 46,
    FriendHpChg = 47,
    PayHp = 49,
    FriendPayHp = 50,
    DefAfterDmgUnifiedPoint = 51,
    DefBeforeHeal = 61,
    FriendCollectMakeDeath = 62,
    JudgeRoundEnd = 63,
    AfterCasterBuff = 64,
    AfterReceiveBuff = 65,
    EnemyTurnBegin = 66,
    EnemyAfterReceiveBuff = 67,
    AtkBeforeDmgBeforeShield = 68,
    DefBeforeDmgBeforeShield = 69,
    SelfTurnEndActionForceUpdated = 80,
    BeControl = 91,
    AtkAfterHeal = 92,
    ReviveFriend = 100,
    ReviveByFriend = 101,
    FriendDying = 102,
    TransferEnd = 103,
    FriendAfterHeal = 104,
    DefAfterRecover = 105,
    FriendAfterRecover = 106,
    BeforeBattleEnd = 120,
}

E_BUFF_SPEC_SUBTYPE = {
    Frozen = 30007,
    STUN = 30001,
    SILENT = 30004,
    SpecState = 90004,
    Shield = 90000,
    ProtectFrozen = 1530201,
    Reborn = 90001,
    Charm = 1380801,
    Charm2 = 1380803,
    Transfer = 22120799,
    SpecStateMat = 90006,
    Telepathy = 1060201,
}

E_CONTROL_BUFF_SUBTYPE = {
    E_BUFF_SPEC_SUBTYPE.Frozen,
    E_BUFF_SPEC_SUBTYPE.STUN,
    E_BUFF_SPEC_SUBTYPE.SILENT,
}

E_BUFF_SPEC_SHOW_TYPE = {
    Hide_Hit_EFF = 1,
    UniformPos = 2,
}

E_BUFF_MAIN_TYPE = {
    GOOD = 1,
    BAD = 2,
    CONTROL = 3,
    MIDDLE = 9,
}

E_HIT_TYPE = {
    Normal = 0,
    Fly = 1,
    Back = 2,
    Block = 3,
}

E_DMG_TYPE = {
    Normal = 1,
    Dot = 2,
    Plus = 3,
    PayHp = 4,
    AttrDmg = 5,
}

E_HEAL_TYPE = {
    Normal = 0,
    Recover = 1,
}

E_CAMERA_TIMELINE_TYPE = {
    FollowAtk = 0,
    FollowVirtual = 1,
}

E_CAMERA_TIMELINE_FOCUS_POINT = {
    AtkRow1 = 0,
    AtkRow2 = 1,
    AtkRow3 = 2,
    AtkCenter = 3,
    DefRow1 = 4,
    DefRow2 = 5,
    DefRow3 = 6,
    DefCenter = 7,
    TargetsCenter = 8,
    CenterPos = 9,
}

E_GOOD_BAD_DEF = {
    BAD = 0,
    GOOD = 1,
    MID = 2
}
