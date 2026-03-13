--lua export version 2
buff_1950202 = {
  SEend = {
    BoneData = {
      AttachType = 1,
      BoneName = "FX_WP_R"
    },
    binding = 2,
    effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_11_02.prefab"
  },
  SEloop = {
    BoneData = {
      AttachType = 1,
      BoneName = "FX_WP_R",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    binding = 2,
    effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_11_01.prefab"
  },
  SEstart = {
    BoneData = {
      AttachType = 1,
      BoneName = "FX_WP_R"
    },
    binding = 2,
    effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_11.prefab"
  }
}
BattleDefaultTypesOpt.SetDefault(buff_1950202, BuffTemplateShow_Default, "BuffTemplateShow")