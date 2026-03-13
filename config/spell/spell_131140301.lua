spell_131140301 = {
  CameraData = { {
      CameraShakeName = "CameraShakeCfg_N_Skill",
      IsShake = true,
      clipduring = 0,
      triggerS = 0
    } },
  IconTexture = {
    IconPath = ""
  },
  IntervalTimeS = 1,
  IsHitExplosion = true,
  IsMoveToTarget = true,
  MotionEffectPath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_02_02.prefab",
  MotionType = 3,
  MoveID = 1311403,
  Name = "小招魔法弹",
  NewAttackDrop = {
    actionforceData = {
      cSVSkillAssociate = 0
    },
    damageData = {
      Sender = {
        IDS = {}
      },
      Target = {
        IDS = {}
      },
      attackType = 1,
      cSVSkillAssociate = 0,
      damageType = 1,
      hitType = 0
    },
    dispelData = {
      associate = 0,
      primaryType = 0
    },
    energyData = {
      cSVSkillAssociate = 0,
      energyDataType = 0
    },
    healData = {
      Sender = {
        IDS = {}
      },
      Target = {
        IDS = {}
      },
      attributeType = 9,
      cSVSkillAssociate = 0,
      healType = 0
    },
    preContidion = {
      FunctionName = ""
    },
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
    triggerType = 0
  },
  NewHitDuringTimeS = 0,
  NewIntervalTimeS = 0,
  SoundData = {
    duringS = 0,
    preContidion = {
      FunctionName = ""
    },
    soundid = "",
    triggerS = 0
  },
  TargetEffect = {
    ArenaCoordinate = {
      x = 0,
      y = 0,
      z = 0
    },
    BoneData = {
      AttachType = 2,
      BoneName = "",
      RelativePoint = 2,
      RelativePointName = "Cha_RP_center",
      fieldData = {
        placeType = 0
      },
      offset = {
        x = 0,
        y = 0,
        z = 0
      }
    },
    binding = 0,
    duringS = 0,
    effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_02_03.prefab",
    fieldData = {
      placeType = 0
    },
    preContidion = {
      FunctionName = ""
    },
    scale = {
      x = 0,
      y = 0,
      z = 0
    },
    soundData = {
      duringS = 0,
      preContidion = {
        FunctionName = ""
      },
      soundid = "",
      triggerS = 0
    },
    target = 1,
    triggerS = 0
  },
  Title = "小招魔法弹",
  Trigger = {
    actionforceData = {
      cSVSkillAssociate = 0
    },
    damageData = {
      Sender = {
        IDS = {}
      },
      Target = {
        IDS = {}
      },
      attackType = 2,
      cSVSkillAssociate = 2,
      damageType = 1,
      hitType = 0
    },
    dispelData = {
      associate = 0,
      primaryType = 0
    },
    energyData = {
      cSVSkillAssociate = 0,
      energyDataType = 0
    },
    healData = {
      Sender = {
        IDS = {}
      },
      Target = {
        IDS = {}
      },
      attributeType = 9,
      cSVSkillAssociate = 0,
      healType = 0
    },
    preContidion = {
      FunctionName = "a_skill_13114_03_dispel_onhit"
    },
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
    triggerType = 1
  },
  VoiceData = {
    duringS = 0,
    preContidion = {
      FunctionName = ""
    },
    soundid = "",
    triggerS = 0
  },
  flip = false,
  launchBuff = {
    AssociateBuff = 0,
    preContidion = {
      FunctionName = ""
    },
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
  }
}