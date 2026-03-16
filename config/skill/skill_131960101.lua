skill_131960101 = {
  Class = 2,
  LuaFile = "13196",
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
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 2,
        animationPath = "Assets/Content/Character/Hero/StarSapphire/Ani/An_B_196_Skill_N_01.anim",
        animationname = "An_B_196_Skill_N_01",
        animatorname = "Skill",
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
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 0.8333333,
          contidion = {
            FunctionName = ""
          },
          data = '{  HitBoneData = {    AttachType = 2,    BoneName = "",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  IsTargetSelect = false,  LaunchBoneData = {    AttachType = 0,    BoneName = "",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  SpellID = 131960101,  StartBoneData = {    AttachType = 1,    BoneName = "Bip001 R Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  TotalS = 0.3333333,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 0,    markForDel = false,    tSConditions = {      Num = 0,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 0,      heroId = 0,      measureType = 0,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        buffMainType = 0,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
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
          TriggerS = 0.9,
          contidion = {
            FunctionName = ""
          },
          data = "{  Sender = {    IDS = {}  },  Target = {    IDS = {}  },  attackType = 2,  attr = 0,  cSVSkillAssociate = 1,  damageType = 1,  hitType = 0}",
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
          TriggerS = 1.433333,
          data = "{  FlagType = 1}",
          datatype = "DWCommon.FlagData"
        }, {
          DuringS = 0.1,
          TriggerS = 0.2666667,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Bip001 R Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_N_01.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 0.8333333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Bip001 R Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_N_02.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 0.8666667,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 1,    BoneName = "Bip001 R Hand",    RelativePoint = 0,    RelativePointName = "",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_N_05.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 0.8333333,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Bip001 R Hand",    RelativePoint = 2,    RelativePointName = "Cha_RP_center",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_N_04.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 1,  triggerS = 0}',
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
          TriggerS = 0.9,
          contidion = {
            FunctionName = ""
          },
          data = '{  ArenaCoordinate = {    x = 0,    y = 0,    z = 0  },  BoneData = {    AttachType = 2,    BoneName = "Bip001 R Hand",    RelativePoint = 1,    RelativePointName = "Cha_RP_down",    fieldData = {      placeType = 0    },    offset = {      x = 0,      y = 0,      z = 0    }  },  binding = 0,  duringS = 0,  effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_N_06.prefab",  fieldData = {    placeType = 0  },  preContidion = {    FunctionName = ""  },  scale = {    x = 0,    y = 0,    z = 0  },  soundData = {    duringS = 0,    preContidion = {      FunctionName = ""    },    soundid = "",    triggerS = 0  },  target = 2,  triggerS = 0}',
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
          TriggerS = 1.433333,
          contidion = {
            FunctionName = ""
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13196_edgeShowOff",  LuaName = "ActiveSkills/13196",  triggerS = 0}',
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
          TriggerS = 0.2333333,
          contidion = {
            FunctionName = ""
          },
          data = '{  DuringS = 0,  FunctionName = "a_skill_13196_edgeShowOn",  LuaName = "ActiveSkills/13196",  triggerS = 0}',
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_StarSapphire_Skill_N",  triggerS = 0}',
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
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Hero/StarSapphire/Ani/An_B_196_Idle_Loop.anim",
        animationname = "An_B_196_Idle_Loop",
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
        buffMainType = 0,
        conditionFilter = 0,
        conditionFilterDirection = 0,
        wpType = 0
      }
    }
  }
}