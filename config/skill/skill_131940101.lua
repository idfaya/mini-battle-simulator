--lua export version 2
skill_131940101 = {
  Class = 2,
  LuaFile = "13194",
  actData = { {
      LaunchMove = {
        MLimitTimeS = 0.3666667,
        MoveID = 10101,
        moveOffsetDis = -1.5,
        triggerTimeS = 0.6666667
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 2.066667,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Skill_N_01.anim",
        animationname = "An_B_194_Skill_N_01",
        animatorname = "MoveFwd_Start",
        during = 2.066667
      },
      keyFrameDatas = { {
          TriggerS = 1.433333,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 0.4333333,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          DuringS = 0.1,
          TriggerS = 0.4,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_01.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.5,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 1,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_02.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.333333,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_04.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 1,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_06.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.4,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Hit2",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_03.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.3333333,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOn",  LuaName = "ActiveSkills/13194",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.4,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_kyleRayner_Skill_N",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.4666667,
        MoveID = 10103,
        triggerTimeS = 0.06666667
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 0.9333333,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Skill_N_01_bwd.anim",
        animationname = "An_B_194_Skill_N_01_bwd",
        animatorname = "MoveBwd_Start",
        during = 0.9333336
      },
      keyFrameDatas = { {
          TriggerS = 0.1666667,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.5333334,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOff",  LuaName = "ActiveSkills/13194",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 1,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_06.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        } },
      targetsSelections = {
        castTarget = 2
      }
    } },
  targetsSelections = {
    castTarget = 1,
    tSConditions = {
      conditionDirection = 1,
      measureType = 3
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_131940101, SkillTemplateNew_Default, "SkillTemplateNew")