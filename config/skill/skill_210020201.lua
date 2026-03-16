skill_210020201 = {
  Class = 4,
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
        NotU1 = true,
        campType = 2
      },
      atLeastTimeS = 0.693,
      cartoon = {
        TotalS = 0,
        during = 0,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0.1,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = {},  binding = 1,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Battle/FX_B_Common_Battle_DaZhao_Start.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_Common_Battle_DaZhao_Start.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Common/FX_Battle/FX_B_Common_Battle_DaZhao_Start.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Battle_Skill_U",  triggerS = 0}',
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
      atLeastTimeS = 0.5666667,
      cartoon = {
        TotalS = 2.933333,
        animationPath = "Assets/Content/Character/Mon/21002/Ani/An_B_21002_Skill_U_01.anim",
        animationname = "An_B_21002_Skill_U_01",
        animatorname = "Skill",
        during = 2.933333,
        triggerS = 0
      },
      contidion = {
        FunctionName = ""
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.8666667,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 3,    markForDel = false,    tSConditions = {      Num = 5,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 3,      heroId = 0,      measureType = 2,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        conditionFilter = 0,        conditionFilterDirection = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff",
          targetsSelections = {
            NoInheritWhenEmpty = false,
            castTarget = 3,
            markForDel = false,
            tSConditions = {
              Num = 5,
              autoFullNum = false,
              buffSubType = 0,
              conditionDirection = 3,
              heroId = 0,
              measureType = 2,
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
          TriggerS = 1.8,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0,
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 2,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 2,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        conditionFilter = 0,        conditionFilterDirection = 0      }    }  }}',
          datatype = "DWCommon.LaunchBuff",
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
        }, {
          DuringS = 0.1,
          TriggerS = 0.8,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = { {      Data = {        EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_01.prefab",        Sound = {          duringS = 0,          preContidion = {            FunctionName = ""          },          soundid = "",          triggerS = 0        },        minmaxValue = {          x = 1,          y = 1        }      },      hideFlags = 0,      name = "FX_B_21002_U_01"    } },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_21002_U_01.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_01.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 0.8,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_L_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = { {      Data = {        EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_02_L.prefab",        Sound = {          duringS = 0,          preContidion = {            FunctionName = ""          },          soundid = "",          triggerS = 0        },        minmaxValue = {          x = 1,          y = 1        }      },      hideFlags = 0,      name = "FX_B_21002_U_02_L"    } },  binding = 2,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_02_L.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_21002_U_02_L.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_02_L.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 0.8,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "FX_R_Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SfxCfgs = { {      Data = {        EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_02_L.prefab",        Sound = {          duringS = 0,          preContidion = {            FunctionName = ""          },          soundid = "",          triggerS = 0        },        minmaxValue = {          x = 1,          y = 1        }      },      hideFlags = 0,      name = "FX_B_21002_U_02_L"    }, {      Data = {        EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_02_R.prefab",        Sound = {          duringS = 0,          preContidion = {            FunctionName = ""          },          soundid = "",          triggerS = 0        },        minmaxValue = {          x = 1,          y = 1        }      },      hideFlags = 0,      name = "FX_B_21002_U_02_R"    } },  binding = 2,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_02_R.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  sfxCfgpath = "Assets/Res/War/Sfx/FX_B_21002_U_02_R.asset",  sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21002/FX_B_21002_U_02_R.prefab" },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Villain_Minison_Assist_E_Skill_U",  triggerS = 0}',
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
      atLeastTimeS = 0.5666667,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Mon/21002/Ani/An_B_21002_Idle_Loop.anim",
        animationname = "An_B_21002_Idle_Loop",
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
  keepRotation = true,
  targetsSelections = {
    NoInheritWhenEmpty = false,
    castTarget = 3,
    markForDel = false,
    tSConditions = {
      Num = 5,
      autoFullNum = false,
      buffSubType = 0,
      conditionDirection = 3,
      heroId = 0,
      measureType = 2,
      tSFilter = {
        BuffSubType = 0,
        PropertyID = 1,
        conditionFilter = 0,
        conditionFilterDirection = 0
      }
    }
  }
}