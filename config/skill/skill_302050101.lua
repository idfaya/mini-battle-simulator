--lua export version 2
skill_302050101 = {
  Class = 4,
  LuaFile = "30205",
  actData = { {
      actConditionn = {
        NotU1 = true,
        campType = 1
      },
      atLeastTimeS = 1.266667,
      keyFrameDatas = { {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_UI/FX_UI_Common/FX_UI_Screen/FX_UI_Common_Heiping_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 4,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Battle_Skill_U",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          TriggerS = 1.266667,
          data = "{  TotalS = 0.06666667,  darken = true,  showMethod = 0}",
          datatype = "DWCommon.LaunchShowControl",
          targetsSelections = {
            castTarget = 2,
            tSConditions = {
              Num = 1,
              conditionDirection = 3,
              measureType = 2
            }
          }
        }, {
          data = "{  TotalS = 0.03333334,  darken = false,  showMethod = 0}",
          datatype = "DWCommon.LaunchShowControl",
          targetsSelections = {
            castTarget = 3,
            tSConditions = {
              Num = 9,
              conditionDirection = 3,
              measureType = 2
            }
          }
        } }
    }, {
      atLeastTimeS = 0.6666667,
      cartoon = {
        TotalS = 1.966667,
        animationPath = "Assets/Content/Character/Collection/GreenLanternPowerBattery/Ani/An_B_C205_Skill.anim",
        animationname = "An_B_C205_Skill",
        animatorname = "Skill",
        during = 2,
        triggerS = 0.06666667
      },
      keyFrameDatas = { {
          TriggerS = 0.5333334,
          data = "{  TotalS = 0.4666667,  darken = true,  showMethod = 1}",
          datatype = "DWCommon.LaunchShowControl",
          targetsSelections = {
            castTarget = 3,
            tSConditions = {
              Num = 9,
              conditionDirection = 3,
              measureType = 2
            }
          }
        }, {
          TriggerS = 1.166667,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attributeType = 9,  cSVSkillAssociate = 1,  healType = 0}",
          datatype = "DWCommon.HealData"
        }, {
          TriggerS = 1.4,
          data = '{  AssociateBuff = 3,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          TriggerS = 1.4,
          data = '{  AssociateBuff = 2,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          DuringS = 0.1,
          TriggerS = 0.1666667,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 4,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.026667,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 4,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  DuringS = 0,  FunctionName = "a_skill_30205_2",  LuaName = "30205",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.166667,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_King_Shark/FX_B_129_Skill_U1_07.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.4,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 6,    RelativePointName = "Cha_RP_top",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 2,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.4,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Hit2",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Battle_Collection_GreenLanternPowerBattery",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } },
      targetsSelections = {
        tSConditions = {
          autoFullNum = true,
          measureType = 2
        }
      }
    }, {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 0.2,
        animationPath = "Assets/Content/Character/Collection/GreenLanternPowerBattery/Ani/An_B_C205_Idle_Loop.anim",
        animationname = "An_B_C205_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      },
      keyFrameDatas = { {
          data = "{  FlagType = 0}",
          datatype = "DWCommon.FlagData"
        } }
    } },
  targetsSelections = {
    castTarget = 3,
    tSConditions = {
      Num = 9,
      conditionDirection = 1,
      measureType = 1
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_302050101, SkillTemplateNew_Default, "SkillTemplateNew")