--lua export version 2
buff_11940401 = {
  SEIntervals = {
    appearAnimPath = "",
    disappearAnimPath = ""
  },
  SEend = {
    BoneData = {
      AttachType = 1,
      BoneName = "Hit2",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    appearAnimPath = "",
    binding = 1,
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
    binding = 2,
    disappearAnimPath = "",
    effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_B_Hero_ice_02.prefab"
  },
  SEstart = {
    BoneData = {
      BoneName = "Hit2",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    appearAnimPath = "",
    disappearAnimPath = "",
    effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_B_Weiji_Skill_ice.prefab"
  }
}
BattleDefaultTypesOpt.SetDefault(buff_11940401, BuffTemplateShow_Default, "BuffTemplateShow")