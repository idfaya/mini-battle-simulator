--lua export version 2
skill_131450101 = {
  Class = 2,
  actData = { {
      LaunchMove = {
        MLimitTimeS = 0.45,
        MoveID = 10101,
        moveOffsetDis = -1.5,
        triggerTimeS = 0.27
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.533333,
        animationPath = "Assets/Content/Character/Villain/Scarecrow/Ani/An_B_145_Skill_N_01.anim",
        animationname = "An_B_145_Skill_N_01",
        animatorname = "Skill",
        during = 1.533333
      },
      keyFrameDatas = { {
          TriggerS = 0.7333333,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 0.7333333,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          DuringS = 0.1,
          TriggerS = 0.35,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 1,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_N_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7333333,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_N_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Scarecrow_Skill_N",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7333333,
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.35,
        MoveID = 10103
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 0.9666669,
        animationPath = "Assets/Content/Character/Villain/Scarecrow/Ani/An_B_145_Skill_N_01_Bwd.anim",
        animationname = "An_B_145_Skill_N_01_Bwd",
        animatorname = "MoveBwd_Start",
        during = 0.9666669
      },
      keyFrameDatas = { {
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
      conditionDirection = 1,
      measureType = 3
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_131450101, SkillTemplateNew_Default, "SkillTemplateNew")