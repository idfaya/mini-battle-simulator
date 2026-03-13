spell_207040201 = {
  CameraData = { {
      CameraShakeName = "CameraShakeCfg_N_Skill_small",
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
  MotionEffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20704/FX_B_20704_Skill_U_03.prefab",
  MotionType = 3,
  MoveID = 10101,
  Name = "监狱暴徒远程物理子弹",
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
      RelativePoint = 0,
      RelativePointName = "",
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
          EffectPath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20704/FX_B_20704_Skill_U_04.prefab",
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
        name = "FX_B_20704_Skill_U_04"
      } },
    binding = 0,
    duringS = 0,
    effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20704/FX_B_20704_Skill_U_04.prefab",
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
    sfxCfgpath = "Assets/Res/War/Sfx/FX_B_20704_Skill_U_04.asset",
    sfxCfgsPath = { "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20704/FX_B_20704_Skill_U_04.prefab" },
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
  Title = "监狱暴徒远程物理子弹",
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
          PropertyID = 1,
          conditionFilter = 0,
          conditionFilterDirection = 0
        }
      }
    }
  }
}