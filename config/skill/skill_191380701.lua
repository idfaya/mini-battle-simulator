--lua export version 2
skill_191380701 = {
  Class = 512,
  actData = { {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 2.533333,
        animationPath = "Assets/Content/Character/Villain/Poison_Ivy/Ani/An_B_138_Skill_S_03.anim",
        animationname = "An_B_138_Skill_S_03",
        animatorname = "Skill",
        during = 2.533334
      },
      keyFrameDatas = { {
          TriggerS = 1.5,
          data = "{  TokenAssociate = 1}",
          datatype = "DWCommon.TokenData",
          targetsSelections = {
            castTarget = 15,
            tSConditions = {
              Num = 1,
              conditionDirection = 2,
              measureType = 2,
              tSFilter = {
                conditionFilter = 5,
                wpType = 3
              }
            }
          }
        }, {
          TriggerS = 1.533333,
          data = '{  HitBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 191380701,  StartBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.1333333,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell",
          targetsSelections = {
            castTarget = 4,
            tSConditions = {
              Num = 1,
              conditionDirection = 1,
              measureType = 2
            }
          }
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21301/An_B_21301_Skill_N_01_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_PoisonIvy_Skill_S",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Villain/Poison_Ivy/Ani/An_B_138_Idle_loop.anim",
        animationname = "An_B_138_Idle_loop",
        animatorname = "Idle_Loop",
        during = 2,
        triggerS = 3.608225e-16
      }
    } },
  targetsSelections = {
    castTarget = 2
  }
}
BattleDefaultTypesOpt.SetDefault(skill_191380701, SkillTemplateNew_Default, "SkillTemplateNew")