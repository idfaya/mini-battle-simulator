skill_212110701 = {
  Class = 512,
  LuaFile = "21211",
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
        TotalS = 2.933333,
        animationPath = "Assets/Content/Character/Mon/21203/Ani/An_B_21203_Idle_Loop_Spec_Return.anim",
        animationname = "An_B_21203_Idle_Loop_Spec_Return",
        animatorname = "Skill",
        during = 2.933333,
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
              conditionFilterDirection = 0,
              wpType = 0
            }
          }
        },
        triggerS = 0
      },
      contidion = {
        FunctionName = "a_skill_21211_07_animationCheck"
      },
      keyFrameDatas = { {
          DuringS = 0,
          TriggerS = 1.366667,
          contidion = {
            FunctionName = ""
          },
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Ultraman_State_Weak_Stop",  triggerS = 0}',
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
        animationPath = "Assets/Content/Character/Mon/21203/Ani/An_B_21203_Idle_Loop.anim",
        animationname = "An_B_21203_Idle_Loop",
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
          TriggerS = 0,
          contidion = {
            FunctionName = ""
          },
          data = "{  TokenAssociate = 1}",
          datatype = "DWCommon.TokenData",
          targetsSelections = {
            NoInheritWhenEmpty = false,
            castTarget = 15,
            markForDel = false,
            tSConditions = {
              Num = 3,
              autoFullNum = false,
              buffSubType = 0,
              conditionDirection = 2,
              heroId = 0,
              measureType = 2,
              tSFilter = {
                BuffSubType = 0,
                PropertyID = 1,
                conditionFilter = 0,
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 0.03333334,
          contidion = {
            FunctionName = ""
          },
          data = '{  AssociateBuff = 1,  preContidion = {    FunctionName = ""  },  targetsSelections = {    NoInheritWhenEmpty = false,    castTarget = 4,    markForDel = false,    tSConditions = {      Num = 3,      autoFullNum = false,      buffSubType = 0,      conditionDirection = 3,      heroId = 0,      measureType = 2,      tSFilter = {        BuffSubType = 0,        PropertyID = 1,        conditionFilter = 0,        conditionFilterDirection = 0,        wpType = 0      }    }  }}',
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
                conditionFilterDirection = 0,
                wpType = 0
              }
            }
          }
        }, {
          DuringS = 0,
          TriggerS = 3.608225e-16,
          contidion = {
            FunctionName = "a_skill_21211_07_tokensAddAttr"
          },
          data = "{  cSVSkillAssociate = 0}",
          datatype = "DWCommon.ActionforceData",
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
          data = '{  duringS = 0,  preContidion = {    FunctionName = ""  },  soundid = "SE_Hero_Ultraman_Skill_S",  triggerS = 0}',
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
        animationPath = "Assets/Content/Character/Mon/21203/Ani/An_B_21203_Idle_Loop.anim",
        animationname = "An_B_21203_Idle_Loop",
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
              conditionFilter = 0,
              conditionFilterDirection = 0,
              wpType = 0
            }
          }
        },
        triggerS = 3.608225e-16
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
            conditionFilterDirection = 0,
            wpType = 0
          }
        }
      }
    } },
  keepRotation = false,
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
        conditionFilterDirection = 0,
        wpType = 0
      }
    }
  }
}