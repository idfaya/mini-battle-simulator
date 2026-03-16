--lua export version 2
skill_193450201 = {
  Class = 4,
  LuaFile = "19345",
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
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 3.8,
        animationPath = "Assets/Content/Character/Villain/Scarecrow/Ani/An_B_145_Skill_U_01.anim",
        animationname = "An_B_145_Skill_U_01",
        animatorname = "Skill",
        during = 3.8
      },
      keyFrameDatas = { {
          TriggerS = 3.2,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 2,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 3.4,
          contidion = {
            FunctionName = "a_skill_19345_1"
          },
          data = "{  cSVSkillAssociate = 0}",
          datatype = "DWCommon.ActionforceData"
        }, {
          DuringS = 0.1,
          TriggerS = 3.11,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_U3_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.3,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_U1_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.6,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_U3_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.7,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_U2_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 3.11,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_U3_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 3.2,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Scarecrow/FX_B_145_Skill_U3_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Scarecrow_Skill_U",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          DuringS = 0.1,
          TriggerS = 3.2,
          data = '{  CameraShakeName = "CameraShakeCfg_U_jiguangshexian",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          TriggerS = 3.5,
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
BattleDefaultTypesOpt.SetDefault(skill_193450201, SkillTemplateNew_Default, "SkillTemplateNew")