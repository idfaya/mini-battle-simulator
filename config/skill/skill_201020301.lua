skill_201020301 = {
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
        TotalS = 2.3,
        animationPath = "Assets/Content/Character/Mon/20102/Ani/An_B_20102_Skill_S_01.anim",
        animationname = "An_B_20102_Skill_S_01",
        animatorname = "Skill",
        during = 2.3,
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
              buffMainType = 0,
              conditionFilter = 0,
              conditionFilterDirection = 0,
              wpType = 0
            }
          }
        },
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.825,
          contidion = {
            FunctionName = ""
          },
          data = '{  HitBoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 201020101,  StartBoneData = {    AttachType = 1,    BoneName = "Bone036",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.627,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 2,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Bone036",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20102/FX_B_20102_N_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Bip001 R Finger2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20102/FX_B_20102_N_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 0.825,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20102/FX_B_20102_N_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0.6}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Villain_Warrior_Assist_Skill_S",  triggerS = 0}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 1.466667,
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
            buffMainType = 0,
            conditionFilter = 0,
            conditionFilterDirection = 0,
            wpType = 0
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
        TotalS = 2,
        animationPath = "Assets/Content/Character/Mon/20102/Ani/An_B_20102_Idle_Loop.anim",
        animationname = "An_B_20102_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2,
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
              buffMainType = 0,
              conditionFilter = 0,
              conditionFilterDirection = 0,
              wpType = 0
            }
          }
        },
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
            buffMainType = 0,
            conditionFilter = 0,
            conditionFilterDirection = 0,
            wpType = 0
          }
        }
      }
    } },
  keepRotation = false,
  seqAsTarget = false,
  targetsSelections = {
    NoInheritWhenEmpty = false,
    castTarget = 4,
    markForDel = false,
    tSConditions = {
      Num = 1,
      autoFullNum = false,
      buffSubType = 0,
      conditionDirection = 3,
      heroId = 0,
      measureType = 2,
      tSFilter = {
        BuffSubType = 0,
        PropertyID = 301,
        buffMainType = 0,
        conditionFilter = 2,
        conditionFilterDirection = 1,
        wpType = 0
      }
    }
  }
}