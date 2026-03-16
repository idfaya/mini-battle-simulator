skill_131520101 = {
  Class = 2,
  LuaFile = "13152",
  actData = { {
      LaunchMove = {
        MLimitTimeS = 0.4166667,
        MoveID = 10108,
        isMoveBack = false,
        moveOffsetDis = -3,
        triggerTimeS = 0.75
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
        TotalS = 1.9,
        animationPath = "Assets/Content/Character/Hero/Haljordan/Ani/An_B_152_Skill_N_01.anim",
        animationname = "An_B_152_Skill_N_01",
        animatorname = "Skill",
        during = 1.9,
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
        FunctionName = "a_skill_13152_01_First"
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 1.366667,
          contidion = {
            FunctionName = ""
          },
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 1.366667,
          contidion = {
            FunctionName = ""
          },
          data = '{  CameraShakeName = "CameraShakeCfg_N_jian",  IsShake = true,  clipduring = 0,  triggerS = 0}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 1.366667,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
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
          TriggerS = 1.233333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 0.2333333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          data = '{  DuringS = 0,  FunctionName = "a_skill_13152_on",  LuaName = "13152",  triggerS = 0}',
          datatype = "DWCommon.LuaData",
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
          TriggerS = 0.7166666,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "FX_Body",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_HalJordan_Skill_N",  triggerS = 0}',
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
        } },
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
            buffMainType = 0,
            conditionFilter = 0,
            conditionFilterDirection = 0,
            wpType = 0
          }
        }
      }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.5,
        MoveID = 10108,
        isMoveBack = false,
        moveOffsetDis = -3,
        triggerTimeS = 1.833333
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
        TotalS = 3.666667,
        animationPath = "Assets/Content/Character/Hero/Haljordan/Ani/An_B_152_Skill_S_01.anim",
        animationname = "An_B_152_Skill_S_01",
        animatorname = "Skill",
        during = 3.666667,
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
        FunctionName = "a_skill_13152_01_S"
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 2.433333,
          contidion = {
            FunctionName = ""
          },
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 3.033333,
          contidion = {
            FunctionName = ""
          },
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 1,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 2.433333,
          contidion = {
            FunctionName = ""
          },
          data = '{  CameraShakeName = "CameraShakeCfg_N_jian",  IsShake = true,  clipduring = 0,  triggerS = 0}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 3.033333,
          contidion = {
            FunctionName = ""
          },
          data = '{  CameraShakeName = "CameraShakeCfg_N_jian",  IsShake = true,  clipduring = 0,  triggerS = 0}',
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
                buffMainType = 0,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0.1,
          TriggerS = 0.5333334,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 1.333333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 2.433333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
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
          TriggerS = 3.033333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Hit2",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
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
          TriggerS = 2.266667,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_03.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 1.8,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "FX_Body",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          data = '{  DuringS = 0,  FunctionName = "a_skill_13152_on",  LuaName = "13152",  triggerS = 0}',
          datatype = "DWCommon.LuaData",
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_HalJordan_Skill_S",  triggerS = 0}',
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
        } },
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
            buffMainType = 0,
            conditionFilter = 0,
            conditionFilterDirection = 0,
            wpType = 0
          }
        }
      }
    }, {
      LaunchMove = {
        MLimitTimeS = 0.4333333,
        MoveID = 10103,
        isMoveBack = true,
        moveOffsetDis = 0,
        triggerTimeS = 0.01666667
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
        TotalS = 1.116667,
        animationPath = "Assets/Content/Character/Hero/Haljordan/Ani/An_B_152_Skill_N_01_Bwd.anim",
        animationname = "An_B_152_Skill_N_01_Bwd",
        animatorname = "MoveBwd_Start",
        during = 1.166667,
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
        FunctionName = "a_skill_13152_01_N"
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.5333334,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0,
          TriggerS = 0.03333334,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 1,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 1,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
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
          TriggerS = 0.4666667,
          contidion = {
            FunctionName = ""
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13152_off",  LuaName = "13152",  triggerS = 0}',
          datatype = "DWCommon.LuaData",
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
          TriggerS = 0.08333334,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "FX_Body",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
        MLimitTimeS = 0.4333333,
        MoveID = 10103,
        isMoveBack = true,
        moveOffsetDis = 0,
        triggerTimeS = 0.01666667
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
        TotalS = 1.033333,
        animationPath = "Assets/Content/Character/Hero/Haljordan/Ani/An_B_152_Skill_S_01_Bwd.anim",
        animationname = "An_B_152_Skill_S_01_Bwd",
        animatorname = "MoveBwd_Start",
        during = 1.033334,
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
        FunctionName = "a_skill_13152_01_S"
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.03333334,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = "a_skill_13152_01_Shield1"  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 3,    markForDel = false,    tSConditions = {      Num = 9,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 3,      heroId = 0,      measureType = 2,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
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
          DuringS = 0,
          TriggerS = 0.5333334,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0,
          TriggerS = 0.05,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = "a_skill_13152_01_Shield2"  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 1,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 3,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
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
          TriggerS = 0.4666667,
          contidion = {
            FunctionName = ""
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13152_off",  LuaName = "13152",  triggerS = 0}',
          datatype = "DWCommon.LuaData",
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
          TriggerS = 0.08333334,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "FX_Body",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_N01_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
    } },
  extraTargetsSelections = { {
      NoInheritWhenEmpty = false,
      castTarget = 1,
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
          PropertyID = 1,
          buffMainType = 0,
          conditionFilter = 0,
          conditionFilterDirection = 0,
          wpType = 0
        }
      }
    } },
  keepRotation = false,
  seqAsTarget = false,
  targetsSelections = {
    NoInheritWhenEmpty = false,
    castTarget = 1,
    markForDel = true,
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
        buffMainType = 0,
        conditionFilter = 0,
        conditionFilterDirection = 0,
        wpType = 0
      }
    }
  }
}