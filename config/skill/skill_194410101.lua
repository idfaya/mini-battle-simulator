--lua export version 2
skill_194410101 = {
  Class = 2,
  LuaFile = "13141",
  actData = { {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.066667,
        animationPath = "Assets/Content/Character/Villain/Killer_Frost/Ani/An_B_141_Skill_N_01.anim",
        animationname = "An_B_141_Skill_N_01",
        animatorname = "Skill",
        during = 1.066667
      },
      keyFrameDatas = { {
          TriggerS = 0.4333333,
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131410101,  StartBoneData = {    AttachType = 1,    BoneName = "Bip001 L Finger22",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.2666667,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 10,    markForDel = true,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          TriggerS = 0.5333334,
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131410101,  StartBoneData = {    AttachType = 1,    BoneName = "Bip001 L Finger22",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.4,  preContidion = {    FunctionName = "a_skill_13141_1_ultCheck_1"  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 11,    markForDel = true,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          TriggerS = 0.5333334,
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131410101,  StartBoneData = {    AttachType = 1,    BoneName = "Bip001 L Finger22",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.4,  preContidion = {    FunctionName = "a_skill_13141_1_ultCheck_2"  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 12,    markForDel = true,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          DuringS = 0.1,
          TriggerS = 0.3666667,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Bip001 L Finger22",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Killer_Frost/FX_B_141_Skill_N_01_1.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.6666667,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_KillerFrost_Skill_N1",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          TriggerS = 0.8333333,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          TriggerS = 0.8,
          data = '{  AssociateBuff = 0,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        } }
    }, {
      atLeastTimeS = 0.03333334,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Villain/Killer_Frost/Ani/An_B_141_Idle_Loop.anim",
        animationname = "An_B_141_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      }
    } },
  extraTargetsSelections = { {
      castTarget = 1,
      markForDel = true,
      tSConditions = {
        Num = 1,
        conditionDirection = 2,
        measureType = 3
      }
    }, {
      castTarget = 1,
      markForDel = true,
      tSConditions = {
        Num = 1,
        conditionDirection = 2,
        measureType = 2
      }
    } },
  targetsSelections = {
    castTarget = 1,
    markForDel = true,
    tSConditions = {
      Num = 9,
      measureType = 3
    }
  }
}BattleDefaultTypesOpt.SetDefault(skill_194410101, SkillTemplateNew_Default, "SkillTemplateNew")