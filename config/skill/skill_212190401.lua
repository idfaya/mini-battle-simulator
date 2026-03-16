--lua export version 2
skill_212190401 = {
  Class = 512,
  LuaFile = "21210",
  actData = { {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 2,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Idle_Loop.anim",
        animationname = "An_B_194_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      },
      keyFrameDatas = { {
          data = "{  actionOrderRate = 1,  animatorNode = 0,  hpRate = 2}",
          datatype = "DWCommon.ReviveData",
          targetsSelections = {
            castTarget = 15,
            tSConditions = {
              Num = 4,
              conditionDirection = 3,
              measureType = 2
            }
          }
        }, {
          TriggerS = 0.2,
          contidion = {
            FunctionName = "a_skill_21210_02_afterRevive"
          },
          data = "{  cSVSkillAssociate = 0}",
          datatype = "DWCommon.ActionforceData"
        } }
    }, {
      atLeastTimeS = 0.2,
      cartoon = {
        TotalS = 0.03333334,
        animationPath = "Assets/Content/Character/Hero/Kyle_Rayner/Ani/An_B_194_Idle_Loop.anim",
        animationname = "An_B_194_Idle_Loop",
        animatorname = "Idle_Loop",
        during = 2
      },
      targetsSelections = {
        castTarget = 2
      }
    } },
  targetsSelections = {
    castTarget = 2
  }
}
BattleDefaultTypesOpt.SetDefault(skill_212190401, SkillTemplateNew_Default, "SkillTemplateNew")