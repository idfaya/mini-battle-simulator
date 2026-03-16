--lua export version 2
skill_192440101 = {
  Class = 2,
  LuaFile = "19244",
  actData = { {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.6,
        animationPath = "Assets/Content/Character/Villain/Captain_Boomerang/Ani/An_B_144_Skill_N_01.anim",
        animationname = "An_B_144_Skill_N_01",
        animatorname = "Skill",
        during = 1.6
      },
      contidion = {
        FunctionName = "a_skill_19244_01_bounce_false"
      },
      keyFrameDatas = { {
          TriggerS = 0.4,
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131440101,  StartBoneData = {    AttachType = 1,    BoneName = "Bip001 R Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.3,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 10,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          TriggerS = 1.266667,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0.5,
          TriggerS = 0.7,
          data = '{  DuringS = 0.1,  FunctionName = "a_skill_19244_01_return",  LuaName = "",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_CaptainBoomerang_Skill_N",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.6,
        animationPath = "Assets/Content/Character/Villain/Captain_Boomerang/Ani/An_B_144_Skill_N_02.anim",
        animationname = "An_B_144_Skill_N_02",
        animatorname = "Skill",
        during = 1.766667
      },
      contidion = {
        FunctionName = "a_skill_19244_01_bounce_true"
      },
      keyFrameDatas = { {
          TriggerS = 0.4,
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131440103,  StartBoneData = {    AttachType = 1,    BoneName = "Bip001 R Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.3333333,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          TriggerS = 1.266667,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_CaptainBoomerang_Skill_N_T",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 0.01666667,
        animationPath = "Assets/Content/Character/Villain/Captain_Boomerang/Ani/An_B_144_Idle_Loop.anim",
        animationname = "An_B_144_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      }
    } },
  extraTargetsSelections = { {
      castTarget = 1,
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
      conditionDirection = 1,
      measureType = 3
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_192440101, SkillTemplateNew_Default, "SkillTemplateNew")