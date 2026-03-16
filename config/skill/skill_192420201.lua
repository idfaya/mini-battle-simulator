--lua export version 2
skill_192420201 = {
  Class = 4,
  actData = { {
      actConditionn = {
        NotU1 = true,
        campType = 1
      },
      atLeastTimeS = 1.485,
      keyFrameDatas = { {
          DuringS = 1.485,
          data = '{  DuringS = 1.485,  FunctionName = "g_actdata_combox",  LuaName = "WarEvent/130000001.lua",  triggerS = 0.4}',
          datatype = "DWCommon.LuaData"
        } }
    }, {
      actConditionn = {
        NotU1 = true,
        campType = 2
      },
      atLeastTimeS = 0.693,
      keyFrameDatas = { {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Battle/FX_B_Common_Battle_DaZhao_Start.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_UI/FX_UI_Common/FX_UI_Screen/FX_UI_Common_Heiping_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 4,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Battle_Skill_U",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      actConditionn = {
        campType = 1
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.5,
        animationPath = "Assets/Content/Character/Villain/Harley_Quinn/Ani/An_B_142_Skill_U_01_1.anim",
        animationname = "An_B_142_Skill_U_01_1",
        animatorname = "Skill",
        during = 1.5
      },
      keyFrameDatas = { {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Quinn_Skill_U_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          DuringS = 1.283333,
          data = '{  sameFuncAsVideo = false,  timelineA = {    during = 1.2833333333333,    timelinePath = "Content/Character/Villain/Harley_Quinn/TimeLine/U1/142_U1_1"  }}',
          datatype = "DWCommon.TimelineData"
        } }
    }, {
      actConditionn = {
        campType = 2
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.5,
        animationPath = "Assets/Content/Character/Villain/Harley_Quinn/Ani/An_B_142_Skill_U_01_1.anim",
        animationname = "An_B_142_Skill_U_01_1",
        animatorname = "Skill",
        during = 1.5
      },
      keyFrameDatas = { {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Bip001 R Hand",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U1_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Quinn_Skill_U_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.3,
        MoveID = 10101,
        triggerTimeS = 0.15
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 2.8,
        animationPath = "Assets/Content/Character/Villain/Harley_Quinn/Ani/An_B_142_skill_U_03.anim",
        animationname = "An_B_142_skill_U_03",
        animatorname = "Skill",
        during = 2.8
      },
      keyFrameDatas = { {
          TriggerS = 0.7,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 1,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 1.3,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 1.6,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 3,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 201    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_02.prefab",  fieldData = {    placeType = 201  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 6,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.8,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 2.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.9,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.3,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.6,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Harley_Quinn/FX_B_142_Skill_U3_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          DuringS = 0.1,
          TriggerS = 1,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.3,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.6,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.5,
        MoveID = 10103,
        triggerTimeS = 0.3
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 2,
        animationPath = "Assets/Content/Character/Villain/Harley_Quinn/Ani/An_B_142_Skill_U_03_Bwd.anim",
        animationname = "An_B_142_Skill_U_03_Bwd",
        animatorname = "MoveBwd_Start",
        during = 2
      },
      keyFrameDatas = { {
          TriggerS = 1.6,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        } },
      targetsSelections = {
        castTarget = 2
      }
    } },
  targetsSelections = {
    castTarget = 1,
    tSConditions = {
      Num = 9,
      conditionDirection = 3,
      measureType = 4
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_192420201, SkillTemplateNew_Default, "SkillTemplateNew")