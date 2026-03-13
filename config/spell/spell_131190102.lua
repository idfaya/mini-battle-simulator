spell_131190102 = {
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
  MotionEffectPath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Green_Arrow/FX_B_119_Skill_S01_08.prefab",
  MotionType = 3,
  MoveID = 1311901,
  Name = "绿箭侠冰冻箭",
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
      cSVSkillAssociate = 0
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
          PropertyID = 1,
          conditionFilter = 0,
          conditionFilterDirection = 0
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
      AttachType = 1,
      BoneName = "Hit2",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down",
      fieldData = {
        placeType = 0
      },
      offset = {
        x = 0,
        y = 0,
        z = 0
      }
    },
    SfxCfgs = { {
        Data = {
          EffectPath = "Assets/Content/Prefab/SFX/FX_Common/FX_Hit/FX_B_Common_Hit_Frozen_01.prefab",
          Sound = {
            duringS = 0,
            preContidion = {
              FunctionName = ""
            },
            soundid = "",
            triggerS = 0
          },
          minmaxValue = {
            x = 1,
            y = 1
          }
        },
        hideFlags = 0,
        name = "FX_B_Common_Hit_Frozen_01"
      } },
    binding = 0,
    duringS = 0,
    effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Hit/FX_B_Common_Hit_Frozen_01.prefab",
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
    sfxCfgpath = "Assets/Res/War/Sfx/FX_B_Common_Hit_Frozen_01.asset",
    sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Common/FX_Hit/FX_B_Common_Hit_Frozen_01.prefab" },
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
  Title = "绿箭侠冰冻箭",
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
      attackType = 1,
      cSVSkillAssociate = 1,
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
      cSVSkillAssociate = 0
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
          PropertyID = 1,
          conditionFilter = 0,
          conditionFilterDirection = 0
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
    AssociateBuff = 1,
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
          PropertyID = 1,
          conditionFilter = 0,
          conditionFilterDirection = 0
        }
      }
    }
  }
}