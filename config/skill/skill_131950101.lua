--lua export version 2
skill_131950101 = {
  Class = 2,
  LuaFile = "13195",
  actData = { {
      LaunchMove = {
        MLimitTimeS = 0.3,
        MoveID = 10101,
        moveOffsetDis = -1.5,
        triggerTimeS = 0.3666667
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 1.1,
        animationPath = "Assets/Content/Character/Hero/JohnStewart/Ani/An_B_195_Skill_N_01.anim",
        animationname = "An_B_195_Skill_N_01",
        animatorname = "Skill",
        during = 1.1
      },
      keyFrameDatas = { {
          TriggerS = 0.7,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 2,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_N01_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_Body",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_N01_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "FX_Body",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 2,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_N01_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_N01_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7,
          contidion = {
            FunctionName = "a_skill_13195_01_1"
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13195_01_1",  LuaName = "13195",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.2333333,
          contidion = {
            FunctionName = "a_skill_13195_OpenGreen"
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13195_OpenGreen",  LuaName = "13195",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_JohnStewart_Skill_N",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.3333333,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Hit2",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 2,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_N01_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.297,
        MoveID = 10103,
        triggerTimeS = 0.1666667
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 0.9333333,
        animationPath = "Assets/Content/Character/Hero/JohnStewart/Ani/An_B_195_Skill_N_01_Bwd.anim",
        animationname = "An_B_195_Skill_N_01_Bwd",
        animatorname = "MoveBwd_Start",
        during = 0.9333335
      },
      keyFrameDatas = { {
          DuringS = 0.2333333,
          contidion = {
            FunctionName = "a_skill_13195_ClosenGreen"
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13195_ClosenGreen",  LuaName = "13195",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          TriggerS = 0.4636666,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.4636666,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Hit2",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 2,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_N01_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        } },
      targetsSelections = {
        castTarget = 2
      }
    } },
  targetsSelections = {
    castTarget = 1,
    tSConditions = {
      Num = 1,
      conditionDirection = 3,
      measureType = 2,
      tSFilter = {
        buffMainType = 2,
        conditionFilter = 6,
        conditionFilterDirection = 1
      }
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_131950101, SkillTemplateNew_Default, "SkillTemplateNew")