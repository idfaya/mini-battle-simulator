--lua export version 2
buff_3020505 = {
  SEIntervals = {
    appearAnimPath = "",
    disappearAnimPath = ""
  },
  SEend = {
    BoneData = {
      AttachType = 2,
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    appearAnimPath = "",
    binding = 2,
    disappearAnimPath = ""
  },
  SEloop = {
    BoneData = {
      AttachType = 2,
      BoneName = "Hit2",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    appearAnimPath = "",
    binding = 4,
    disappearAnimPath = "",
    effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_05.prefab"
  },
  SEstart = {
    BoneData = {
      BoneName = "Hit2",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    appearAnimPath = "",
    disappearAnimPath = "",
    target = 0
  }
}BattleDefaultTypesOpt.SetDefault(buff_3020505, BuffTemplateShow_Default, "BuffTemplateShow")