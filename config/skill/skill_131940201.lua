--lua export version 2
skill_131940201 = {
  Class = 4,
  LuaFile = "13194",
  actData = { {
      actConditionn = {
        NotU1 = true,
        campType = 1
      },
      atLeastTimeS = 1.485,
      keyFrameDatas = { {
          DuringS = 1.485,
          data = '{  DuringS = 1.485,  FunctionName = "g_actdata_combox",  LuaName = "WarEvent/130000001.lua",  preCondition = {    FunctionName = ""  },  triggerS = 0.4}',
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
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 1,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Battle/FX_B_Common_Battle_DaZhao_Start.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_UI/FX_UI_Common/FX_UI_Screen/FX_UI_Common_Heiping_01.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 4,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Battle_Skill_U",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      actConditionn = {
        campType = 2
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 1.566667,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Skill_U_01.anim",
        animationname = "An_B_194_Skill_U_01",
        animatorname = "Skill",
        during = 1.566667
      },
      contidion = {
        FunctionName = "a_skill_13194_02_part1_check"
      },
      keyFrameDatas = { {
          TriggerS = 0.2,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_01.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_Body",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U1_01.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.9,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U1_03.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.6,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U1_04.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.1,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOn",  LuaName = "ActiveSkills/13194",  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          TriggerS = 6.938894e-18,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U1_02.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.433333,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U1_05.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_kyleRayner_Skill_U1_U1",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          data = '{  TotalS = 1.566667,  cameraBlur = {    blurRadius = 1,    centerIntensity = 1,    centerX = 0,    centerY = 0,    edgeIntensity = 1,    scaleX = 1,    scaleY = 1  },  cameraBlurDelay = 0,  cameraPrefabName = "194_U1_1",  cameraTimelineType = 0,  enableCameraBlur = false,  focusPoint = 0,  followTargetRotation = false}',
          datatype = "DWCommon.LaunchCamera"
        } }
    }, {
      actConditionn = {
        campType = 1
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 6.633333,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Idle_Loop.anim",
        animationname = "An_B_194_Idle_Loop",
        animatorname = "Skill",
        during = 2
      },
      contidion = {
        FunctionName = "a_skill_13194_02_part1_check"
      },
      keyFrameDatas = { {
          DuringS = 6.633333,
          data = '{  sameFuncAsVideo = true,  timelineA = {    during = 6.633333333332,    timelinePath = "Content/Character/Hero/Kyle_Rayner/TimeLine/U2_1/194_U2_1"  }}',
          datatype = "DWCommon.TimelineData"
        }, {
          DuringS = 0.1,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOn",  LuaName = "ActiveSkills/13194",  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          TriggerS = 6.333333,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_kyleRayner_Skill_U1_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.2666667,
        MoveID = 10108,
        moveOffsetDis = -8
      },
      actConditionn = {
        campType = 2
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 2.966667,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Skill_U_01_2.anim",
        animationname = "An_B_194_Skill_U_01_2",
        animatorname = "Skill",
        during = 2.966667
      },
      contidion = {
        FunctionName = "a_skill_13194_02_part2_check"
      },
      keyFrameDatas = { {
          TriggerS = 1.333333,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          DuringS = 0.1,
          TriggerS = 0.5,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill2_U1_01.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.8333333,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill2_U1_02.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.8,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill2_U1_04.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 1,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill_N_06.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.03333334,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOn",  LuaName = "ActiveSkills/13194",  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 1,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill2_U1_05.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_kyleRayner_Skill_U2_U1",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        }, {
          TriggerS = 0.2666667,
          data = '{  TotalS = 2.7,  cameraBlur = {    blurRadius = 1,    centerIntensity = 1,    centerX = 0,    centerY = 0,    edgeIntensity = 1,    scaleX = 1,    scaleY = 1  },  cameraBlurDelay = 0,  cameraPrefabName = "194_U1_2",  cameraTimelineType = 0,  enableCameraBlur = false,  focusPoint = 0,  followTargetRotation = false}',
          datatype = "DWCommon.LaunchCamera"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.2,
        MoveID = 10108,
        moveOffsetDis = -8
      },
      actConditionn = {
        campType = 1
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 7.633333,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Idle_Loop.anim",
        animationname = "An_B_194_Idle_Loop",
        animatorname = "Skill",
        during = 2
      },
      contidion = {
        FunctionName = "a_skill_13194_02_part2_check"
      },
      keyFrameDatas = { {
          DuringS = 7.633333,
          data = '{  sameFuncAsVideo = true,  timelineA = {    during = 7.633333333332,    timelinePath = "Content/Character/Hero/Kyle_Rayner/TimeLine/U2_2/194_U2_2"  }}',
          datatype = "DWCommon.TimelineData"
        }, {
          DuringS = 0.1,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOn",  LuaName = "ActiveSkills/13194",  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          TriggerS = 0.06666667,
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_kyleRayner_Skill_U2_CG",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 1.833333,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Skill_U_03.anim",
        animationname = "An_B_194_Skill_U_03",
        animatorname = "Skill",
        during = 1.833333
      },
      contidion = {
        FunctionName = "a_skill_13194_02_part1_check"
      },
      keyFrameDatas = { {
          TriggerS = 0.5333334,
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 2}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 0.9333333,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          TriggerS = 0.8333333,
          contidion = {
            FunctionName = "a_skill_13194_energyReturn_check"
          },
          data = "{  cSVSkillAssociate = 5,  energyDataType = 2}",
          datatype = "DWCommon.EnergyData",
          targetsSelections = {
            castTarget = 2
          }
        }, {
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131940201,  StartBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.6666667,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell"
        }, {
          DuringS = 0.1,
          TriggerS = 1.5,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOff",  LuaName = "ActiveSkills/13194",  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.2,
          data = "{  hitType = 0}",
          datatype = "DWCommon.HitData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.4,
          data = "{  hitType = 0}",
          datatype = "DWCommon.HitData"
        }, {
          DuringS = 0.1,
          data = "{  hitType = 0}",
          datatype = "DWCommon.HitData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U3_03.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U3_01.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.1,
          data = '{  CameraShakeName = "CameraShakeCfg_U_jiguangshexian",  IsShake = true,  clipduring = 0,  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_kyleRayner_Skill_U1_U3",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.2,
        MoveID = 10103,
        isMoveBack = true,
        triggerTimeS = 2
      },
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 2.8,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Skill_U_03_2.anim",
        animationname = "An_B_194_Skill_U_03_2",
        animatorname = "Skill",
        during = 2.8
      },
      contidion = {
        FunctionName = "a_skill_13194_02_part2_check"
      },
      keyFrameDatas = { {
          TriggerS = 0.5,
          data = "{  Sender = {    IDS = { {        ID = 162,        Param = 2      } }  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 1}",
          datatype = "DWCommon.DamageData"
        }, {
          TriggerS = 2,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          TriggerS = 1.9,
          contidion = {
            FunctionName = "a_skill_13194_energyReturn_check"
          },
          data = "{  cSVSkillAssociate = 5,  energyDataType = 2}",
          datatype = "DWCommon.EnergyData",
          targetsSelections = {
            castTarget = 2
          }
        }, {
          DuringS = 0.1,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill2_U3_01.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 2.5,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_edgeShowOff",  LuaName = "ActiveSkills/13194",  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.4,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill2_U3_04.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = "a_skill_13194_02_overkill_dmg_check"  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.5,
          data = '{  DuringS = 0,  FunctionName = "a_skill_13194_02_overkill_AOE",  LuaName = "ActiveSkills/13194.lua",  preCondition = {    FunctionName = "a_skill_13194_02_overkill_dmg_check"  },  triggerS = 0}',
          datatype = "DWCommon.LuaData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.5,
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  appearAnimPath = "",  binding = 0,  disappearAnimPath = "",  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill2_U3_03.prefab",  fieldData = {    placeType = 0  },  preCondition = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.5,
          data = '{  CameraShakeName = "CameraShakeCfg_zuihouzadi",  IsShake = true,  clipduring = 0,  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          DuringS = 0.1,
          TriggerS = 1.4,
          data = '{  CameraShakeName = "CameraShakeCfg_U_jiguangshexian",  IsShake = true,  clipduring = 0,  preCondition = {    FunctionName = "a_skill_13194_02_overkill_dmg_check"  },  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.7333333,
          data = '{  CameraShakeName = "CameraShakeCfg_zuihouzadi",  IsShake = true,  clipduring = 0,  preCondition = {    FunctionName = ""  },  triggerS = 0}',
          datatype = "DWCommon.CameraData"
        }, {
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_kyleRayner_Skill_U2_U3",  triggerS = 0}',
          datatype = "DWCommon.SoundData"
        } }
    }, {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Idle_Loop.anim",
        animationname = "An_B_194_Idle_Loop",
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
      Num = 1,
      conditionDirection = 3,
      measureType = 2,
      tSFilter = {
        PropertyID = 301,
        conditionFilter = 2,
        conditionFilterDirection = 1
      }
    }
  }
}
BattleDefaultTypesOpt.SetDefault(skill_131940201, SkillTemplateNew_Default, "SkillTemplateNew")