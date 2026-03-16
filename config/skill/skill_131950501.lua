--lua export version 2
skill_131950501 = {
  Class = 512,
  LuaFile = "13195",
  actData = { {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 1.7,
        animationPath = "Assets/Content/Character/Hero/JohnStewart/Ani/An_B_195_Skill_U_03_spec.anim",
        animationname = "An_B_195_Skill_U_03_spec",
        animatorname = "Skill",
        during = 1.7
      },
      keyFrameDatas = { {
          DuringS = 0.6,
          TriggerS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Bone041",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 2,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_06.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.6,
          TriggerS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "wp_fire003",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 2,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_07.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.2666667,
          TriggerS = 0.5,
          contidion = {
            FunctionName = "a_skill_13195_02_1"
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13195_02_1",  LuaName = "13195",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          TriggerS = 0.1,
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131950201,  StartBoneData = {    AttachType = 1,    BoneName = "FX_WP_R",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.3666667,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          DuringS = 0.2333333,
          TriggerS = 1.333333,
          contidion = {
            FunctionName = "a_skill_13195_ClosenGreen"
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13195_ClosenGreen",  LuaName = "13195",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.6,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "wp_fire003",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 2,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_10.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_JohnStewart_Skill_U3",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          DuringS = 0.2333333,
          TriggerS = 0.5,
          data = '{  CameraShakeName = "CameraShakeCfg_zuihouzadi",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        } }
    }, {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 0.7,
        animationPath = "Assets/Content/Character/Hero/JohnStewart/Ani/An_B_195_Idle_Loop.anim",
        animationname = "An_B_195_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      },
      keyFrameDatas = { {
          TriggerS = 0.4,
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
      Num = 1,
      conditionDirection = 3,
      measureType = 2,
      tSFilter = {
        conditionFilter = 4,
        conditionFilterDirection = 2
      }
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_131950501, SkillTemplateNew_Default, "SkillTemplateNew")