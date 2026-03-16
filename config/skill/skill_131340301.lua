skill_131340301 = {
  Class = 8,
  LuaFile = "",
  actData = { {
      LaunchMove = {
        MLimitTimeS = 0.165,
        MoveID = 10101,
        isMoveBack = false,
        moveOffsetDis = -7.2,
        triggerTimeS = 0
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
        TotalS = 1.233333,
        animationPath = "Assets/Content/Character/Villain/Black_Adam/Ani/An_B_134_Skill_S_01_2.anim",
        animationname = "An_B_134_Skill_S_01_2",
        animatorname = "Skill",
        during = 1.233333,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.57,
          contidion = {
            FunctionName = ""
          },
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 201    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131340301,  StartBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.3,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        PropertyID = 1,        conditionFilter = 0,        conditionFilterDirection = 0      }    }  }}',
          datatype = "DWCommon.LaunchSpell",
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
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 0.57,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 2,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 3,    markForDel = false,    tSConditions = {      Num = 9,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 3,      heroId = 0,      measureType = 2,      tSFilter = {        PropertyID = 1,        conditionFilter = 2,        conditionFilterDirection = 3      }    }  }}',
          datatype = "DWCommon.LaunchBuff",
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
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 0.57,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = {},  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_BlackAdam/FX_B_134_Skill_S01_03_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_134_Skill_S01_03_01.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_BlackAdam/FX_B_134_Skill_S01_03_01.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_BlackAdam_Skill_S",  triggerS = 0}',
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
            PropertyID = 1,
            conditionFilter = 0,
            conditionFilterDirection = 0
          }
        }
      }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.363,
        MoveID = 10103,
        isMoveBack = false,
        moveOffsetDis = 0,
        triggerTimeS = 0
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
        TotalS = 1.033334,
        animationPath = "Assets/Content/Character/Villain/Black_Adam/Ani/An_B_134_Skill_S_01_2_Bwd.anim",
        animationname = "An_B_134_Skill_S_01_2_Bwd",
        animatorname = "MoveBwd_Start",
        during = 1.033334,
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
            PropertyID = 1,
            conditionFilter = 0,
            conditionFilterDirection = 0
          }
        }
      }
    } },
  targetsSelections = {
    NoInheritWhenEmpty = false,
    castTarget = 1,
    markForDel = false,
    tSConditions = {
      Num = 3,
      autoFullNum = false,
      buffSubType = 0,
      conditionDirection = 2,
      heroId = 0,
      measureType = 2,
      tSFilter = {
        PropertyID = 1,
        conditionFilter = 0,
        conditionFilterDirection = 0
      }
    }
  }
}