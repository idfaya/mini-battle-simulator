--lua export version 2
skill_193450301 = {
  Class = 512,
  actData = { {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 3.166667,
        animationPath = "Assets/Content/Character/Villain/Scarecrow/Ani/An_B_145_Skill_S_01.anim",
        animationname = "An_B_145_Skill_S_01",
        animatorname = "Skill",
        during = 3.166667
      },
      keyFrameDatas = { {
          TriggerS = 1.75,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          DuringS = 0.1,
          TriggerS = 1.5,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "bone24",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_S1_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.75,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 3,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 201    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_S1_02.prefab",  fieldData = {    placeType = 201  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 6,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Scarecrow_Skill_S",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          TriggerS = 1.85,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Villain/Scarecrow/Ani/An_B_145_Idle_Loop.anim",
        animationname = "An_B_145_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      },
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
BattleDefaultTypesOpt.SetDefault(skill_193450301, SkillTemplateNew_Default, "SkillTemplateNew")