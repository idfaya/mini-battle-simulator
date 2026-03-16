skill_204040101 = {
  Class = 2,
  LuaFile = "",
  actData = { {
      LaunchMove = {
        MLimitTimeS = 1,
        MoveID = 0,
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
        TotalS = 1.3,
        animationPath = "Assets/Content/Character/Mon/20404/Ani/An_B_20404_Skill_N_01.anim",
        animationname = "An_B_20404_Skill_N_01",
        animatorname = "Skill",
        during = 1.3,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.462,
          contidion = {
            FunctionName = ""
          },
          data = '{  HitBoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 204040101,  StartBoneData = {    AttachType = 1,    BoneName = "Bip001 R Finger2",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.33,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        conditionFilter = 0,        conditionFilterDirection = 0      }    }  }}',
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
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 0.462,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 2,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        conditionFilter = 0,        conditionFilterDirection = 0      }    }  }}',
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
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 0.462,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = {},  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20404/FX_B_20404_Skil_N_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_20404_Skil_N_01.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20404/FX_B_20404_Skil_N_01.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Villain_Mech_Gun_Skill_N",  triggerS = 0}',
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
          DuringS = 0,
          TriggerS = 0.8,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
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
        MLimitTimeS = 1,
        MoveID = 0,
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
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Mon/20404/Ani/An_B_20404_Idle_Loop.anim",
        animationname = "An_B_20404_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = {},
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