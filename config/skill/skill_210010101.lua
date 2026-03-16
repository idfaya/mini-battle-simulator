skill_210010101 = {
  Class = 2,
  LuaFile = "",
  actData = { {
      LaunchMove = {
        MLimitTimeS = 0.3333333,
        MoveID = 10101,
        isMoveBack = false,
        moveOffsetDis = -3,
        triggerTimeS = 0.1
      },
      VideoData = {
        closeTimeS = 0,
        during = 0
      },
      actConditionn = {
        NotU1 = false,
        campType = 0
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.733333,
        animationPath = "Assets/Content/Character/Mon/21001/Ani/An_B_21001_Skill_N_01.anim",
        animationname = "An_B_21001_Skill_N_01",
        animatorname = "Skill",
        during = 1.733333,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 1.366667,
          contidion = {
            FunctionName = ""
          },
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData",
          targetsSelections = {
            NoInheritWhenEmpty = false,
            castTarget = 10,
            markForDel = false,
            tSConditions = {
              Num = 0,
              autoFullNum = false,
              buffSubType = 0,
              conditionDirection = 0,
              heroId = 0,
              measureType = 0,
              tSFilter = {
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 1.233333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = { {      Data = {        EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_N_01.prefab",        Sound = {          duringS = 0,          preContidion = {            FunctionName = ""          },          soundid = "",          triggerS = 0        },        minmaxValue = {          x = 1,          y = 1        }      },      hideFlags = 0,      name = "FX_B_21001_N_01"    } },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_N_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_21001_N_01.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_N_01.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
          datatype = "DWCommon.EffectData",
          targetsSelections = {
            NoInheritWhenEmpty = false,
            castTarget = 0,
            markForDel = false,
            tSConditions = {
              Num = 0,
              autoFullNum = false,
              buffSubType = 0,
              conditionDirection = 0,
              heroId = 0,
              measureType = 0,
              tSFilter = {
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0.06666667,
          TriggerS = 1.266667,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = { {      Data = {        EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_N_01.prefab",        Sound = {          duringS = 0,          preContidion = {            FunctionName = ""          },          soundid = "",          triggerS = 0        },        minmaxValue = {          x = 1,          y = 1        }      },      hideFlags = 0,      name = "FX_B_21001_N_01"    }, {      Data = {        EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_N_02.prefab",        Sound = {          duringS = 0,          preContidion = {            FunctionName = ""          },          soundid = "",          triggerS = 0        },        minmaxValue = {          x = 1,          y = 1        }      },      hideFlags = 0,      name = "FX_B_21001_N_02"    } },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_N_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_21001_N_02.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_N_02.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
          datatype = "DWCommon.EffectData",
          targetsSelections = {
            NoInheritWhenEmpty = false,
            castTarget = 0,
            markForDel = false,
            tSConditions = {
              Num = 0,
              autoFullNum = false,
              buffSubType = 0,
              conditionDirection = 0,
              heroId = 0,
              measureType = 0,
              tSFilter = {
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 1.366667,
          contidion = {
            FunctionName = ""
          },
          data = '{  CameraShakeName = "CameraShakeCfg_N_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
          datatype = "DWCommon.CameraData",
          targetsSelections = {
            NoInheritWhenEmpty = false,
            castTarget = 0,
            markForDel = false,
            tSConditions = {
              Num = 0,
              autoFullNum = false,
              buffSubType = 0,
              conditionDirection = 0,
              heroId = 0,
              measureType = 0,
              tSFilter = {
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Villain_Minison_Tank_E_Skill_N",  triggerS = 0}',
          datatype = "DWCommon.SoundData",
          targetsSelections = {
            NoInheritWhenEmpty = false,
            castTarget = 0,
            markForDel = false,
            tSConditions = {
              Num = 0,
              autoFullNum = false,
              buffSubType = 0,
              conditionDirection = 0,
              heroId = 0,
              measureType = 0,
              tSFilter = {
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        } },
      targetsSelections = {
        NoInheritWhenEmpty = false,
        castTarget = 0,
        markForDel = false,
        tSConditions = {
          Num = 0,
          autoFullNum = false,
          buffSubType = 0,
          conditionDirection = 0,
          heroId = 0,
          measureType = 0,
          tSFilter = {
            BuffSubType = 0,
            PropertyID = 1,
            conditionFilter = 0,
            conditionFilterDirection = 0
          }
        }
      }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.2666667,
        MoveID = 10101,
        isMoveBack = false,
        moveOffsetDis = 0,
        triggerTimeS = 0.1666667
      },
      VideoData = {
        closeTimeS = 0,
        during = 0
      },
      actConditionn = {
        NotU1 = false,
        campType = 0
      },
      atLeastTimeS = 0.1,
      cartoon = {
        TotalS = 1.333333,
        animationPath = "Assets/Content/Character/Mon/21001/Ani/An_B_21001_Skill_N_01_Bwd.anim",
        animationname = "An_B_21001_Skill_N_01_Bwd",
        animatorname = "MoveBwd_Start",
        during = 1.333333,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.3666667,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        } },
      targetsSelections = {
        NoInheritWhenEmpty = false,
        castTarget = 2,
        markForDel = false,
        tSConditions = {
          Num = 0,
          autoFullNum = false,
          buffSubType = 0,
          conditionDirection = 0,
          heroId = 0,
          measureType = 0,
          tSFilter = {
            BuffSubType = 0,
            PropertyID = 1,
            conditionFilter = 0,
            conditionFilterDirection = 0
          }
        }
      }
    } },
  keepRotation = false,
  targetsSelections = {
    NoInheritWhenEmpty = false,
    castTarget = 1,
    markForDel = false,
    tSConditions = {
      Num = 1,
      autoFullNum = false,
      buffSubType = 0,
      conditionDirection = 1,
      heroId = 0,
      measureType = 3,
      tSFilter = {
        BuffSubType = 0,
        PropertyID = 1,
        conditionFilter = 0,
        conditionFilterDirection = 0
      }
    }
  }
}