--lua export version 2
buff_1940101 = {
  ChgModelInfo = { {
      AttachType = 1,
      BoneName = "Hero_S_WhiteLantern_M03"
    } },
  HideChgModelInfo = { {
      AttachType = 1,
      BoneName = "Hero_B_WhiteLantern_M02"
    } },
  SEend = {
    BoneData = {
      AttachType = 1,
      BoneName = "Hit2",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    binding = 1
  },
  SEloop = {
    BoneData = {
      BoneName = "Hit2"
    }
  },
  SEstart = {
    BoneData = {
      BoneName = "Hit2",
      RelativePoint = 1,
      RelativePointName = "Cha_RP_down"
    },
    target = 0
  }
}
BattleDefaultTypesOpt.SetDefault(buff_1940101, BuffTemplateShow_Default, "BuffTemplateShow")