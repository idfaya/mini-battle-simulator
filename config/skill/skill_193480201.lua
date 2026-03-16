--lua export version 2
skill_193480201 = {
  Class = 4,
  LuaFile = "19348",
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
        TotalS = 1.5,
        animationPath = "Assets/Content/Character/Villain/Penguin/Ani/An_B_148_Skill_U_01_0.anim",
        animationname = "An_B_148_Skill_U_01_0",
        animatorname = "Skill",
        during = 1.5
      },
      keyFrameDatas = { {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Penguin_Skill_U_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          DuringS = 1.6,
          data = '{  sameFuncAsVideo = false,  timelineA = {    during = 1.599999999999,    timelinePath = "Content/Character/Villain/Penguin/TimeLine/U1/148_U1_1"  }}',
          datatype = "DWCommon.TimelineData"
        }, {
          contidion = {
            FunctionName = "a_skill_19348_03_vfx_remove"
          },
          data = "{  cSVSkillAssociate = 0}",
          datatype = "DWCommon.ActionforceData"
        } }
    }, {
      actConditionn = {
        campType = 2
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.5,
        animationPath = "Assets/Content/Character/Villain/Penguin/Ani/An_B_148_Skill_U_01_1.anim",
        animationname = "An_B_148_Skill_U_01_1",
        animatorname = "Skill",
        during = 1.5
      },
      keyFrameDatas = { {
          DuringS = 0.1,
          TriggerS = 0.594,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Penguin/FX_B_148_Skill_U01_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Penguin_Skill_U_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          contidion = {
            FunctionName = "a_skill_19348_03_vfx_remove"
          },
          data = "{  cSVSkillAssociate = 0}",
          datatype = "DWCommon.ActionforceData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.4,
        animationPath = "Assets/Content/Character/Villain/Penguin/Ani/An_B_148_Skill_U_03.anim",
        animationname = "An_B_148_Skill_U_03",
        animatorname = "Skill",
        during = 1.4
      },
      keyFrameDatas = { {
          data = '{  HitBoneData = {    AttachType = 3,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 103    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131480201,  StartBoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 1.233333,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          DuringS = 0.1,
          TriggerS = 1.2,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Penguin/FX_B_148_Skill_U03_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.866667,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bane/FX_B_Bane_Skill_U_03_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.2,
          data = '{  CameraShakeName = "CameraShakeCfg_U_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.2,
          data = '{  DuringS = 0.1,  FunctionName = "a_skill_19348_02_enemyHit",  LuaName = "",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.866667,
          data = '{  DuringS = 0.1,  FunctionName = "a_skill_19348_02_heal",  LuaName = "",  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          TriggerS = 1.933333,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        } }
    }, {
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Villain/Penguin/Ani/An_B_148_Idle_Loop.anim",
        animationname = "An_B_148_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      },
      keyFrameDatas = { {
          contidion = {
            FunctionName = "a_skill_19348_03_vfx_add"
          },
          data = "{  cSVSkillAssociate = 0}",
          datatype = "DWCommon.ActionforceData"
        } }
    } },
  targetsSelections = {
    castTarget = 1,
    tSConditions = {
      Num = 3,
      conditionDirection = 2,
      measureType = 2
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_193480201, SkillTemplateNew_Default, "SkillTemplateNew")