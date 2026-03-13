--lua export version 2
buff_16100102 = {
  SEIntervals = {
    BoneData = {
      AttachType = 2,
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    binding = 2
  },
  SEend = {
    BoneData = {
      AttachType = 2,
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    binding = 2,
    disappearAnimPath = "FX_Ain_BowofRa_04",
    effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/BowofRa/FX_B_BowofRa_01.prefab"
  },
  SEloop = {
    BoneData = {
      AttachType = 2,
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    binding = 2,
    effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/BowofRa/FX_B_BowofRa_01.prefab"
  },
  SEstart = {
    effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/BowofRa/FX_B_BowofRa_02.prefab"
  }
}
BattleDefaultTypesOpt.SetDefault(buff_16100102, BuffTemplateShow_Default, "BuffTemplateShow")