--lua export version 2
skill_193390201 = {
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
        TotalS = 0.9333333,
        animationPath = "Assets/Content/Character/Villain/Bane/Ani/An_B_139_Idle_Loop.anim",
        animationname = "An_B_139_Idle_Loop",
        animatorname = "Skill",
        during = 1.333333
      },
      keyFrameDatas = { {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Bane_Skill_U_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          DuringS = 1.033333,
          data = '{  sameFuncAsVideo = false,  timelineA = {    during = 1.033333333332,    timelinePath = "Content/Character/Villain/Bane/TimeLine/U1/139_U1_1"  }}',
          datatype = "DWCommon.TimelineData"
        } }
    }, {
      actConditionn = {
        campType = 2
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.033333,
        animationPath = "Assets/Content/Character/Villain/Bane/Ani/An_B_139_Skill_U_01.anim",
        animationname = "An_B_139_Skill_U_01",
        animatorname = "Skill",
        during = 1.033333
      },
      keyFrameDatas = { {
          DuringS = 0.1,
          TriggerS = 0.48,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bane/FX_B_Bane_Skill_U_03_01_A.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Bane_Skill_U_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 3.1,
        animationPath = "Assets/Content/Character/Villain/Bane/Ani/An_B_139_Skill_U_03.anim",
        animationname = "An_B_139_Skill_U_03",
        animatorname = "Skill",
        during = 3.1
      },
      keyFrameDatas = { {
          TriggerS = 0.6,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attributeType = 9,  cSVSkillAssociate = 1,  healType = 0}",
          datatype = "DWCommon.HealData"
        }, {
          TriggerS = 1.65,
          data = "{  Sender = {    IDS = { {        ID = 32,        Param = 4      } }  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 2,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData",
          targetsSelections = {
            castTarget = 1,
            tSConditions = {
              Num = 20,
              conditionDirection = 3,
              measureType = 2,
              tSFilter = {
                conditionFilter = 2,
                conditionFilterDirection = 3
              }
            }
          }
        }, {
          TriggerS = 1.65,
          data = '{  AssociateBuff = 2,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 1,    markForDel = false,    tSConditions = {      Num = 20,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 3,      heroId = 0,      measureType = 2,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 2,        conditionFilterDirection = 3,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          TriggerS = 1.6,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 1,    markForDel = false,    tSConditions = {      Num = 20,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 3,      heroId = 0,      measureType = 2,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 2,        conditionFilterDirection = 3,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          DuringS = 0.1,
          TriggerS = 0.6,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bane/FX_B_Bane_Skill_U_03_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.6,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.63,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bane/FX_B_Bane_Skill_U_03_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.15,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bane/FX_B_Bane_Skill_U_03_06.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0.1}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.15,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Bip001 R Hand",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bane/FX_B_Bane_Skill_U_03_07.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.65,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bane/FX_B_Bane_Skill_U_03_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.65,
          data = '{  CameraShakeName = "CameraShakeCfg_zuihouzadi",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          TriggerS = 1.766667,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.333333,
        animationPath = "Assets/Content/Character/Villain/Bane/Ani/An_B_139_Idle_Loop.anim",
        animationname = "An_B_139_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 1.333333
      },
      targetsSelections = {
        castTarget = 2
      }
    } },
  targetsSelections = {
    castTarget = 2
  }
}
BattleDefaultTypesOpt.SetDefault(skill_193390201, SkillTemplateNew_Default, "SkillTemplateNew")