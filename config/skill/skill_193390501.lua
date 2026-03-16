--lua export version 2
skill_193390501 = {
  Class = 512,
  LuaFile = "19339",
  actData = { {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 2.2,
        animationPath = "Assets/Content/Character/Villain/Bane/Ani/An_B_139_Skill_S_01.anim",
        animationname = "An_B_139_Skill_S_01",
        animatorname = "Skill",
        during = 2.2
      },
      keyFrameDatas = { {
          TriggerS = 1.133333,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          TriggerS = 1.9,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.133333,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21302/FX_Mon_21302_Skill_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.3333333,
          data = '{  DuringS = 0,  FunctionName = "a_skill_19339_1",  LuaName = "ActiveSkills/19339.lua",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          TriggerS = 6.938894e-18,
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Bane_Skill_S",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 0.3333333,
        animationPath = "Assets/Content/Character/Villain/Bane/Ani/An_S_139_Idle_Loop.anim",
        animationname = "An_S_139_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 8
      },
      targetsSelections = {
        castTarget = 2
      }
    } },
  targetsSelections = {
    castTarget = 3,
    tSConditions = {
      Num = 8,
      conditionDirection = 3,
      measureType = 2,
      tSFilter = {
        PropertyID = 5,
        conditionFilterDirection = 2
      }
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_193390501, SkillTemplateNew_Default, "SkillTemplateNew")