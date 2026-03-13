--lua export version 2
spell_131950201 = {
  CameraData = { {
      CameraShakeName = "CameraShakeCfg_U_Skill",
      IsShake = true
    } },
  IsMoveToTarget = true,
  MotionEffectPath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_08.prefab",
  MotionType = 3,
  MoveID = 10101,
  NewAttackDrop = {
    healData = {
      attributeType = 0
    }
  },
  TargetEffect = {
    BoneData = {
      AttachType = 1,
      BoneName = "Hit2"
    },
    effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_09.prefab",
    target = 1
  },
  Trigger = {
    healData = {
      attributeType = 0
    }
  }
}
BattleDefaultTypesOpt.SetDefault(spell_131950201, SpellTemplate_Default, "SpellTemplate")