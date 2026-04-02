-- Buff配置合并文件
-- 生成时间: 2026-03-31 14:58:00
-- 合并数量: 240
-- 说明: 此文件包含所有在res_buff_template.json中定义的Buff的视觉配置
--       提取参数: effectpath, binding, target, duringS, BoneName, AttachType,
--                 RelativePoint, RelativePointName, offset, scale, soundid
--       31个只有Lua配置的Buff仍保留在单独文件中

return {
  [10001] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10001.prefab",
        target = 2,
      },
    },
  [10002] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10002.prefab",
        target = 2,
      },
    },
  [10003] = {},
  [10004] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10004.prefab",
        target = 2,
      },
    },
  [10005] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10005.prefab",
        target = 2,
      },
    },
  [10006] = {
      SEstart = {
        BoneData = {
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10007.prefab",
        target = 2,
      },
    },
  [10007] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10011.prefab",
        target = 2,
      },
    },
  [10008] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10008.prefab",
        target = 2,
      },
    },
  [10009] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_Treat_End.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10009_01.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10009.prefab",
        target = 2,
      },
    },
  [10010] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10010.prefab",
        target = 2,
      },
    },
  [10011] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10006.prefab",
        target = 2,
      },
    },
  [10013] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10013.prefab",
        target = 2,
      },
    },
  [10014] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10012.prefab",
        target = 2,
      },
    },
  [10015] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10015.prefab",
        target = 2,
      },
    },
  [20001] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20001.prefab",
        target = 2,
      },
    },
  [20002] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20002.prefab",
        target = 2,
      },
    },
  [20003] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20007.prefab",
        target = 2,
      },
    },
  [20004] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20004.prefab",
        target = 2,
      },
    },
  [20005] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20005.prefab",
        target = 2,
      },
    },
  [20006] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20013.prefab",
        target = 2,
      },
    },
  [20007] = {},
  [20008] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20008_01.prefab",
        target = 2,
      },
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20008.prefab",
        target = 2,
      },
    },
  [20009] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20009_01.prefab",
        target = 2,
      },
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20009.prefab",
        target = 2,
      },
    },
  [20010] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20010_01.prefab",
        target = 2,
      },
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20010.prefab",
        target = 2,
      },
    },
  [20011] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20011.prefab",
        target = 2,
      },
    },
  [20013] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20006.prefab",
        target = 2,
      },
    },
  [20014] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20014.prefab",
        target = 2,
      },
    },
  [20015] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Raven/FX_B_136_Skill_S02_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Raven/FX_B_136_Skill_S02_03.prefab",
        target = 2,
      },
    },
  [30001] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_Stun.prefab",
        target = 2,
      },
    },
  [30004] = {},
  [30007] = {
      SEend = {
        binding = 1,
        effectpath = "FX_Common/FX_Hit/FX_B_Common_Hit_Frozen_02",
        target = 1,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_MisterFreeze/FX_B_153_Skill_U3_EmptyBuff.prefab",
        target = 1,
      },
      SEstart = {
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Hit/FX_B_Common_Hit_Frozen_01.prefab",
        target = 1,
      },
    },
  [90000] = {},
  [90001] = {},
  [90002] = {},
  [90004] = {},
  [90005] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10005.prefab",
        target = 2,
      },
    },
  [90006] = {},
  [101501] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Boss_002.prefab",
        target = 2,
      },
    },
  [101921] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_10018.prefab",
        target = 2,
      },
    },
  [101922] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20301/An_B_21301_Skill_N_01_08.prefab",
        target = 2,
      },
    },
  [101923] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20301/An_B_21301_Skill_N_01_09.prefab",
        target = 2,
      },
    },
  [101924] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20301/An_B_21301_Skill_N_01_10.prefab",
        target = 2,
      },
    },
  [101930] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Bip001 L Hand",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21302/FX_Mon_21302_Skill_02.prefab",
        target = 2,
      },
    },
  [101931] = {
      SEstart = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20019.prefab",
        target = 2,
      },
    },
  [101932] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20017.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Common_Buff_20018.prefab",
        target = 2,
      },
    },
  [101933] = {},
  [101934] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Common/FX_Buff/FX_B_Boss_006.prefab",
        target = 2,
      },
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21301/An_B_21301_Skill_N_01_06.prefab",
        target = 2,
      },
    },
  [141001] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_01_05.prefab",
        target = 2,
      },
    },
  [141002] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_01_05.prefab",
        target = 2,
      },
    },
  [171101] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Pandora/FX_B_187_Skill_S04_04.prefab",
        target = 2,
      },
    },
  [171102] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Pandora/FX_B_187_Skill_S04_04.prefab",
        target = 2,
      },
    },
  [171103] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Pandora/FX_B_187_Skill_S04_04.prefab",
        target = 2,
      },
    },
  [1010201] = {},
  [1010202] = {},
  [1010203] = {},
  [1040201] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Flash/FX_B_104_Skill_U3_02.prefab",
        target = 2,
      },
    },
  [1040202] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Flash/FX_B_104_Skill_U3_02.prefab",
        target = 2,
      },
    },
  [1040203] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Flash/FX_B_104_Skill_U3_02.prefab",
        target = 2,
      },
    },
  [1060201] = {
      SEloop = {
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Manhunter/FX_B_106_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1060202] = {
      SEloop = {
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Manhunter/FX_B_106_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1060203] = {
      SEloop = {
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Manhunter/FX_B_106_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1060401] = {},
  [1080401] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Doctor_Fate/FX_B_108_Skill_S02_01.prefab",
        target = 2,
      },
    },
  [1080501] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Doctor_Fate/FX_B_108_Skill_S03_01.prefab",
        target = 2,
      },
    },
  [1080502] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Doctor_Fate/FX_B_108_Skill_S03_01.prefab",
        target = 2,
      },
    },
  [1080503] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Doctor_Fate/FX_B_108_Skill_S03_01.prefab",
        target = 2,
      },
    },
  [1130201] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Cyborg/FX_B_113_Skill_S03_01.prefab",
        target = 2,
      },
    },
  [1130202] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Cyborg/FX_B_113_Skill_S03_01.prefab",
        target = 2,
      },
    },
  [1130203] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Bip001 Spine",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
          offset = {
            x = -0.29300001263619,
            y = -1.2369999885559,
            z = 0.0080000003799796,
          },
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Cyborg/FX_B_113_Skill_U03_05.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Cyborg/FX_B_113_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1130204] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Bip001 Spine",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Cyborg/FX_B_113_Skill_U03_05.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Cyborg/FX_B_113_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1140301] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_01_02.prefab",
        target = 2,
      },
    },
  [1140302] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_01_03.prefab",
        target = 2,
      },
    },
  [1140303] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_01_04.prefab",
        target = 2,
      },
    },
  [1140304] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Constantine/FX_B_Constantine_M01_Skill_C_01_01_06.prefab",
        target = 2,
      },
    },
  [1150201] = {},
  [1180201] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Bip001 Head",
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_FireStorm/FX_A_118_Skill_U3_06.prefab",
        target = 1,
      },
    },
  [1180301] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_FireStorm/FX_B_118_Skill_S01_02.prefab",
        target = 2,
      },
    },
  [1180302] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_FireStorm/FX_B_118_Skill_S01_02.prefab",
        target = 2,
      },
    },
  [1180303] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_FireStorm/FX_B_118_Skill_S01_02.prefab",
        target = 2,
      },
    },
  [1180401] = {},
  [1180402] = {},
  [1180403] = {},
  [1180404] = {},
  [1180601] = {},
  [1270201] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Bip001 R Forearm",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Cheetah/FX_B_127_Skill_U3_Buff.prefab",
        target = 2,
      },
    },
  [1280201] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Huntress/FX_B_128_Skill_U3_02.prefab",
        target = 2,
      },
    },
  [1280202] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Huntress/FX_B_128_Skill_U3_02.prefab",
        target = 2,
      },
    },
  [1280203] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Huntress/FX_B_128_Skill_U3_02.prefab",
        target = 2,
      },
    },
  [1310201] = {
      SDend = {
        soundid = "SE_Hero_Luthor_Skill_U_P2",
      },
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_131@Skill_U3_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_131@Skill_U3_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_131@Skill_U3_01.prefab",
        target = 2,
      },
    },
  [1310202] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_131@Skill_U3_02.prefab",
        target = 2,
      },
    },
  [1310203] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_131@Skill_U3_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_131@Skill_U3_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_131@Skill_U3_01.prefab",
        target = 2,
      },
    },
  [1310402] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_04.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_02.prefab",
        target = 2,
      },
    },
  [1310403] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_04.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_02.prefab",
        target = 2,
      },
    },
  [1310404] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_04.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_02.prefab",
        target = 2,
      },
    },
  [1310405] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_04.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Luthor/FX_B_Luthor_M01_Skill_S_02_02.prefab",
        target = 2,
      },
    },
  [1330401] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Sinestro/FX_B_133_Skill_S02_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Sinestro/FX_B_133_Skill_S02_02.prefab",
        target = 2,
      },
    },
  [1330402] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Sinestro/FX_B_133_Skill_S02_02.prefab",
        target = 2,
      },
    },
  [1340201] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_BlackAdam/FX_B_134_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1340202] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_BlackAdam/FX_B_134_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1340203] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_BlackAdam/FX_B_134_Skill_U03_04.prefab",
        target = 2,
      },
    },
  [1350404] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit1",
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bizarro/FX_B_135_Skill_S02_06.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit1",
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bizarro/FX_B_135_Skill_S02_05.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit1",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Bizarro/FX_B_135_Skill_S02_04.prefab",
        target = 2,
      },
    },
  [1360301] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Raven/FX_B_136_Skill_S01_04.prefab",
        target = 2,
      },
    },
  [1370301] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1370302] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1370303] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1370401] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137@Skill_S_01_01_02.prefab",
        target = 2,
      },
    },
  [1370402] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137@Skill_S_01_01_02.prefab",
        target = 2,
      },
    },
  [1370403] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Captain_Cold/FX_B_137@Skill_S_01_01_02.prefab",
        target = 2,
      },
    },
  [1380801] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21301/An_B_21301_Skill_N_01_03.prefab",
        target = 2,
      },
    },
  [1380802] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21301/An_B_21301_Skill_N_01_03.prefab",
        target = 2,
      },
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21301/An_B_21301_Skill_N_01_03.prefab",
        target = 2,
      },
    },
  [1380803] = {},
  [1390301] = {},
  [1400301] = {},
  [1400302] = {},
  [1400303] = {},
  [1410201] = {
      ChgModelInfo = true,
      SEend = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Killer_Frost/FX_B_141_Skill_U03_02.prefab",
        target = 2,
      },
      SEloop = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Killer_Frost/FX_B_141_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1410202] = {
      ChgModelInfo = true,
      SEend = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Killer_Frost/FX_B_141_Skill_U03_02.prefab",
        target = 2,
      },
      SEloop = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Killer_Frost/FX_B_141_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1480301] = {},
  [1480302] = {},
  [1480303] = {},
  [1480304] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "wp_fire01",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Penguin/FX_B_148_Skill_S01_01.prefab",
        target = 2,
      },
    },
  [1500201] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_DeadShot/FX_B_150_Skill_U03_02.prefab",
        target = 1,
      },
    },
  [1500202] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_DeadShot/FX_B_150_Skill_U03_02.prefab",
        target = 1,
      },
    },
  [1500203] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_DeadShot/FX_B_150_Skill_U03_02.prefab",
        target = 1,
      },
    },
  [1510201] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_DeathStroke/FX_B_151_Skill_U3_Buff.prefab",
        target = 2,
      },
    },
  [1510202] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_DeathStroke/FX_B_151_Skill_U3_Buff.prefab",
        target = 2,
      },
    },
  [1510203] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_DeathStroke/FX_B_151_Skill_U3_Buff.prefab",
        target = 2,
      },
    },
  [1520101] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_04.prefab",
        target = 2,
      },
    },
  [1530201] = {
      SEend = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_MisterFreeze/FX_B_153_Skill_U3_01.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_MisterFreeze/FX_B_153_Skill_U3_IceBuff.prefab",
        target = 2,
      },
    },
  [1530202] = {
      SEend = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_MisterFreeze/FX_B_153_Skill_U3_01.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_MisterFreeze/FX_B_153_Skill_U3_IceBuff.prefab",
        target = 2,
      },
    },
  [1700201] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_Jessica/FX_B_170_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1700203] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_Jessica/FX_B_170_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1700204] = {},
  [1700301] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_Jessica/FX_B_170_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1700302] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_Jessica/FX_B_170_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1700303] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_Jessica/FX_B_170_Skill_U03_01.prefab",
        target = 2,
      },
    },
  [1700401] = {},
  [1700402] = {},
  [1730201] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Clayface/FX_B_173_Skill_U3_01.prefab",
        target = 2,
      },
    },
  [1730202] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Clayface/FX_B_173_Skill_U3_01.prefab",
        target = 2,
      },
    },
  [1730203] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Clayface/FX_B_173_Skill_U3_01.prefab",
        target = 2,
      },
    },
  [1850201] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_04.prefab",
        target = 1,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_02.prefab",
        target = 2,
      },
    },
  [1850202] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_04.prefab",
        target = 1,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_02.prefab",
        target = 2,
      },
    },
  [1850203] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_04.prefab",
        target = 1,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_U03_02.prefab",
        target = 2,
      },
    },
  [1850301] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_01.prefab",
        target = 2,
      },
    },
  [1850302] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_01.prefab",
        target = 2,
      },
    },
  [1850303] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_PhantomStranger/FX_B_185_Skill_S01_01.prefab",
        target = 2,
      },
    },
  [1870301] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Pandora/FX_B_187_Skill_S04_04.prefab",
        target = 2,
      },
    },
  [1870302] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Pandora/FX_B_187_Skill_S04_04.prefab",
        target = 2,
      },
    },
  [1870303] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Pandora/FX_B_187_Skill_S04_04.prefab",
        target = 2,
      },
    },
  [1870304] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_Pandora/FX_B_187_Skill_S04_04.prefab",
        target = 2,
      },
    },
  [1940101] = {
      ChgModelInfo = true,
    },
  [1940102] = {
      ChgModelInfo = true,
    },
  [1950201] = {},
  [1950202] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "FX_WP_R",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_11_02.prefab",
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "FX_WP_R",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_11_01.prefab",
      },
    },
  [1950203] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Bone041",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_01_02.prefab",
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Bone041",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_01_01.prefab",
      },
    },
  [1950204] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Bone041",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_JohnStewart/FX_B_195_Skill_U01_15.prefab",
      },
    },
  [1950401] = {},
  [1950402] = {},
  [1960301] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_S01_04.prefab",
        target = 1,
      },
    },
  [1960302] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_S01_04.prefab",
        target = 1,
      },
    },
  [1960303] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_StarSapphire/FX_B_196_Skill_S01_04.prefab",
        target = 1,
      },
    },
  [2010202] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20102/FX_B_20102_U_04.prefab",
        target = 2,
      },
    },
  [2020201] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_Ideal_04.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_Ideal_03.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_Ideal_02.prefab",
        target = 2,
      },
    },
  [2020202] = {},
  [2020203] = {},
  [2020204] = {},
  [2020401] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_Ideal_01.prefab",
        target = 2,
      },
    },
  [2020501] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop001",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop001",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_01.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop001",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_02.prefab",
      },
    },
  [2020502] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop006",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop006",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_01.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop006",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_02.prefab",
      },
    },
  [2020503] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop002",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop002",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_01.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop002",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_02.prefab",
      },
    },
  [2020504] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop005",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop005",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_01.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop005",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_02.prefab",
      },
    },
  [2020505] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop003",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop003",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_01.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop005",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_02.prefab",
      },
    },
  [2020506] = {
      SEend = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop004",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_03.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop004",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_01.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 1,
          BoneName = "Dummy_prop004",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21202/FX_B_21202_prop_02.prefab",
      },
    },
  [2040102] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20401/FX_B_20401_Skill_U1_02_start&buff.prefab",
        target = 2,
      },
    },
  [2040202] = {
      SDend = {
        soundid = "SE_Villian_Mech_Assist_Skill_U_Stop",
      },
      SDstart = {
        soundid = "SE_Villian_Mech_Assist_Skill_U",
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20402/FX_B_20402_Skill_U1_04.prefab",
        target = 2,
      },
    },
  [2040203] = {},
  [2100102] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21001/FX_B_21001_U_02.prefab",
        target = 2,
      },
    },
  [2100202] = {},
  [2130101] = {
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_20301/An_B_21301_Skill_N_01_06.prefab",
        target = 2,
      },
    },
  [3020201] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C202_Aircraft/FX_B_C202_Skill_06.prefab",
        target = 2,
      },
    },
  [3020202] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C202_Aircraft/FX_B_C202_Skill_06.prefab",
        target = 2,
      },
    },
  [3020203] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C202_Aircraft/FX_B_C202_Skill_06.prefab",
        target = 2,
      },
    },
  [3020204] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C202_Aircraft/FX_B_C202_Skill_06.prefab",
        target = 2,
      },
    },
  [3020205] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C202_Aircraft/FX_B_C202_Skill_07.prefab",
        target = 1,
      },
    },
  [3020301] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
          offset = {
            x = 0,
            y = 0.80000001192093,
            z = 0,
          },
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C203_Parallax/FX_B_C203_Skill_U3_07.prefab",
        target = 2,
      },
    },
  [3020302] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
          offset = {
            x = 0,
            y = 0.80000001192093,
            z = 0,
          },
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C203_Parallax/FX_B_C203_Skill_U3_07.prefab",
        target = 2,
      },
    },
  [3020303] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
          offset = {
            x = 0,
            y = 0.80000001192093,
            z = 0,
          },
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C203_Parallax/FX_B_C203_Skill_U3_07.prefab",
        target = 2,
      },
    },
  [3020304] = {},
  [3020305] = {},
  [3020306] = {},
  [3020501] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
          offset = {
            x = 0,
            y = 0.80000001192093,
            z = 0,
          },
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_04.prefab",
        target = 2,
      },
    },
  [3020502] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
          offset = {
            x = 0,
            y = 0.80000001192093,
            z = 0,
          },
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_04.prefab",
        target = 2,
      },
    },
  [3020503] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
          offset = {
            x = 0,
            y = 0.80000001192093,
            z = 0,
          },
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_04.prefab",
        target = 2,
      },
    },
  [3020504] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_05.prefab",
      },
    },
  [3020505] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_05.prefab",
      },
    },
  [3020506] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Collection/FX_C205_GreenLantern/FX_B_C205_Skill_N_05.prefab",
      },
    },
  [11940101] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_B_Hero_ice_01.prefab",
      },
    },
  [11940201] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_weiji_effiect_fire_xiaosan.prefab",
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_weiji_effiect_fire_chixu.prefab",
      },
    },
  [11940301] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_weiji_effiect_fire_xiaosan.prefab",
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_weiji_effiect_fire_zhantai.prefab",
      },
    },
  [11940401] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_weiji_003/FX_B_Hero_ice_02.prefab",
      },
    },
  [16100021] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/ChaosCrysta/FX_B_ChaosCrystal_02.prefab",
        target = 2,
      },
    },
  [16100022] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit3",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/ChaosCrysta/FX_B_ChaosCrystal_02.prefab",
        target = 2,
      },
    },
  [16100101] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/BowofRa/FX_B_BowofRa_01.prefab",
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/BowofRa/FX_B_BowofRa_01.prefab",
      },
    },
  [16100102] = {
      SEend = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/BowofRa/FX_B_BowofRa_01.prefab",
      },
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Artifact/BowofRa/FX_B_BowofRa_01.prefab",
      },
    },
  [21218051] = {
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        binding = 4,
        effectpath = "Assets/Content/Prefab/SFX/FX_Hero/FX_Hero_GreenLantern_HalJordan/FX_B_152_Skill_S01_04.prefab",
        target = 2,
      },
    },
  [22120101] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_05.prefab",
        target = 2,
      },
    },
  [22120102] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_04.prefab",
        target = 2,
      },
    },
  [22120103] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_03.prefab",
        target = 2,
      },
    },
  [22120104] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_02.prefab",
        target = 2,
      },
    },
  [22120105] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_01.prefab",
        target = 2,
      },
    },
  [22120107] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_05_01.prefab",
        target = 2,
      },
    },
  [22120108] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_04_01.prefab",
        target = 2,
      },
    },
  [22120109] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_03_01.prefab",
        target = 2,
      },
    },
  [22120110] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_02_01.prefab",
        target = 2,
      },
    },
  [22120111] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_NWFF_01_01.prefab",
        target = 2,
      },
    },
  [22120112] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_02.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_01.prefab",
        target = 2,
      },
    },
  [22120113] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_04.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_03.prefab",
        target = 2,
      },
    },
  [22120114] = {},
  [22120301] = {
      SEend = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21203/FX_B_21203_Skill_S01_02.prefab",
        target = 2,
      },
      SEloop = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21203/FX_B_21203_Skill_S01_01.prefab",
        target = 2,
      },
    },
  [22120302] = {
      SEend = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21204/FX_B_21204_02.prefab",
        target = 2,
      },
      SEloop = {
        BoneData = {
          AttachType = 1,
          BoneName = "Hit2",
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21204/FX_B_21204_03.prefab",
        target = 2,
      },
      SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21204/FX_B_21204_01.prefab",
        target = 2,
      },
    },
  [22120303] = {
      SEloop = {
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21203/FX_B_21203_Skill_S02_08.prefab",
        target = 2,
      },
    },
  [22120502] = {
      SEend = {
        BoneData = {
          AttachType = 3,
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21205/FX_B_21205_Skill_U_06_03.prefab",
        target = 6,
      },
      SEloop = {
        BoneData = {
          AttachType = 3,
        },
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21205/FX_B_21205_Skill_U_06_02.prefab",
        target = 6,
      },
    },
  [22120601] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_04.prefab",
        target = 2,
      },
      SEstart = {
        BoneData = {
          AttachType = 2,
          BoneName = "Hit2",
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 2,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_PD_21201/FX_21201_BUFF_03.prefab",
        target = 2,
      },
    },
  [22120602] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21206/FX_B_21206_Skill_S02_02.prefab",
        target = 2,
      },
    },
  [22120701] = {},
  [22120702] = {},
  [22120703] = {},
  [22120704] = {},
  [22120705] = {},
  [22120706] = {},
  [22120707] = {},
  [22120708] = {},
  [22120709] = {},
  [22120710] = {},
  [22120711] = {},
  [22120712] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 6,
          RelativePointName = "Cha_RP_top",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21207/FX_B_21207_Skill_S02_02.prefab",
        target = 2,
      },
    },
  [22120713] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 2,
          RelativePointName = "Cha_RP_center",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21207/FX_B_21207_Skill_S03_01.prefab",
        target = 2,
      },
    },
  [22120799] = {
      SEloop = {
        BoneData = {
          AttachType = 2,
          RelativePoint = 1,
          RelativePointName = "Cha_RP_down",
        },
        binding = 1,
        effectpath = "Assets/Content/Prefab/SFX/FX_Mon/FX_Mon_21207/FX_B_21207_Skill_S01_03.prefab",
        target = 8,
      },
    },
}
