--lua export version 2
spell_131940201 = {
  MotionEffectPath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Kyle_Rayner/FX_B_194_Skill1_U3_02.prefab",
  MotionType = 14,
  NewAttackDrop = {
    healData = {
      attributeType = 0
    }
  },
  TargetEffect = {
    BoneData = {
      BoneName = "Hit2"
    },
    target = 1
  },
  Trigger = {
    healData = {
      attributeType = 0
    }
  }
}
BattleDefaultTypesOpt.SetDefault(spell_131940201, SpellTemplate_Default, "SpellTemplate")