skill_192290101 = {
  Class = 2,
  LuaFile = "",
  actData = { {
      LaunchMove = {
        MLimitTimeS = 0.495,
        MoveID = 10101,
        isMoveBack = false,
        moveOffsetDis = -2.2,
        triggerTimeS = 0.132
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
        TotalS = 1.6,
        animationPath = "Assets/Content/Character/Villain/King_Shark/Ani/An_B_129_Skill_N_01.anim",
        animationname = "An_B_129_Skill_N_01",
        animatorname = "Skill",
        during = 1.6,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 1,
          contidion = {
            FunctionName = ""
          },
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
          datatype = "DWCommon.DamageData",
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
          TriggerS = 0.495,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_King_Shark/FX_B_129_Skill_N_01_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0.396}',
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
          TriggerS = 1,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Hit2",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_King_Shark/FX_B_129_Skill_N_01_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
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
          DuringS = 0,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_KingShark_Skill_N",  triggerS = 0}',
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
        }, {
          DuringS = 0.1,
          TriggerS = 1,
          contidion = {
            FunctionName = ""
          },
          data = '{  CameraShakeName = "CameraShakeCfg_U_Skill",  IsShake = true,  clipduring = 0,  triggerS = 0}',
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
        MLimitTimeS = 0.3,
        MoveID = 10103,
        isMoveBack = false,
        moveOffsetDis = 0,
        triggerTimeS = 0.08
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
        TotalS = 0.7333335,
        animationPath = "Assets/Content/Character/Villain/King_Shark/Ani/An_B_129_Skill_N_01_Bwd.anim",
        animationname = "An_B_129_Skill_N_01_Bwd",
        animatorname = "MoveBwd_Start",
        during = 0.7333335,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0,
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
      Num = 0,
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