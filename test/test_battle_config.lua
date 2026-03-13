---
--- Test Battle Configuration
--- 测试战斗配置文件
--- 提供完整的战斗初始状态配置，用于测试战斗系统
---

local TestBattleConfig = {}

-- ==================== 基础属性定义 ====================

--- 创建基础属性表
---@param hp number 生命值
---@param atk number 攻击力
---@param def number 防御力
---@param speed number 速度
---@return table 属性表
local function CreateAttributeMap(hp, atk, def, speed)
    return {
        [1] = hp or 1000,      -- HP
        [2] = atk or 100,      -- ATK
        [3] = def or 50,       -- DEF
        [4] = speed or 100,    -- SPEED
        [5] = 0,               -- CRIT_RATE
        [6] = 150,             -- CRIT_DAMAGE
        [7] = 100,             -- HIT_RATE
        [8] = 0,               -- DODGE_RATE
        [9] = 0,               -- DAMAGE_REDUCE
        [10] = 0,              -- DAMAGE_INCREASE
    }
end

--- 创建英雄数据
---@param configId number 配置ID
---@param name string 名称
---@param level number 等级
---@param wpType number 位置类型
---@param attributeMap table 属性表
---@param skills table 技能列表
---@return table 英雄数据
local function CreateHeroData(configId, name, level, wpType, attributeMap, skills)
    return {
        configId = configId,
        name = name,
        level = level or 1,
        wpType = wpType or 0,
        hp = attributeMap[1],
        maxHp = attributeMap[1],
        atk = attributeMap[2],
        def = attributeMap[3],
        speed = attributeMap[4],
        critRate = attributeMap[5] or 0,
        critDamage = attributeMap[6] or 150,
        hitRate = attributeMap[7] or 100,
        dodgeRate = attributeMap[8] or 0,
        damageReduce = attributeMap[9] or 0,
        damageIncrease = attributeMap[10] or 0,
        skills = skills or {1001},  -- 默认技能ID
        passiveSkills = {},
        energy = 0,
        maxEnergy = 100,
        energyType = 1,  -- E_ENERGY_TYPE.Bar
    }
end

-- ==================== 1v1 简单配置 ====================

--- 1v1 简单战斗配置
--- 左侧1个英雄 vs 右侧1个英雄
TestBattleConfig.CONFIG_1V1 = {
    max_round = 30,
    random_num = {123456789, 362436069, 521288629, 88675123},
    
    unit_status = {
        attack_units = {
            [1] = {
                config_id = 1001,
                unique_id = 1,
                level = 10,
                wp_type = 1,
                skills = {1001},
                attribute_map = CreateAttributeMap(1000, 150, 80, 120),
            },
        },
        defend_units = {
            [1] = {
                config_id = 2001,
                unique_id = 101,
                level = 10,
                wp_type = 1,
                skills = {1001},
                attribute_map = CreateAttributeMap(800, 120, 60, 100),
            },
        },
    },
}

-- ==================== 3v3 完整配置 ====================

--- 3v3 完整战斗配置
--- 左侧3个英雄 vs 右侧3个英雄
TestBattleConfig.CONFIG_3V3 = {
    max_round = 50,
    random_num = {123456789, 362436069, 521288629, 88675123},
    
    unit_status = {
        attack_units = {
            [1] = {
                config_id = 1001,
                unique_id = 1,
                level = 20,
                wp_type = 1,  -- 前排
                skills = {1001, 1002},
                attribute_map = CreateAttributeMap(2000, 200, 150, 80),
            },
            [2] = {
                config_id = 1002,
                unique_id = 2,
                level = 20,
                wp_type = 2,  -- 中排
                skills = {1001, 1003},
                attribute_map = CreateAttributeMap(1200, 300, 80, 120),
            },
            [3] = {
                config_id = 1003,
                unique_id = 3,
                level = 20,
                wp_type = 3,  -- 后排
                skills = {1001, 1004},
                attribute_map = CreateAttributeMap(1000, 250, 60, 150),
            },
        },
        defend_units = {
            [1] = {
                config_id = 2001,
                unique_id = 101,
                level = 20,
                wp_type = 1,  -- 前排
                skills = {1001, 1002},
                attribute_map = CreateAttributeMap(1800, 180, 140, 75),
            },
            [2] = {
                config_id = 2002,
                unique_id = 102,
                level = 20,
                wp_type = 2,  -- 中排
                skills = {1001, 1003},
                attribute_map = CreateAttributeMap(1100, 280, 75, 115),
            },
            [3] = {
                config_id = 2003,
                unique_id = 103,
                level = 20,
                wp_type = 3,  -- 后排
                skills = {1001, 1004},
                attribute_map = CreateAttributeMap(900, 230, 55, 145),
            },
        },
    },
}

-- ==================== 进阶配置 ====================

--- 坦克vs输出 配置
--- 测试高防御坦克 vs 高攻击输出
TestBattleConfig.CONFIG_TANK_VS_DPS = {
    max_round = 30,
    random_num = {123456789, 362436069, 521288629, 88675123},
    
    unit_status = {
        attack_units = {
            [1] = {
                config_id = 1001,
                unique_id = 1,
                level = 30,
                wp_type = 1,
                skills = {1001, 1005},  -- 坦克技能
                attribute_map = CreateAttributeMap(5000, 80, 300, 60),
            },
        },
        defend_units = {
            [1] = {
                config_id = 2001,
                unique_id = 101,
                level = 30,
                wp_type = 1,
                skills = {1001, 1006},  -- 输出技能
                attribute_map = CreateAttributeMap(1500, 400, 40, 150),
            },
        },
    },
}

--- 速度测试配置
--- 测试不同速度英雄的出手顺序
TestBattleConfig.CONFIG_SPEED_TEST = {
    max_round = 20,
    random_num = {123456789, 362436069, 521288629, 88675123},
    
    unit_status = {
        attack_units = {
            [1] = {
                config_id = 1001,
                unique_id = 1,
                level = 10,
                wp_type = 1,
                skills = {1001},
                attribute_map = CreateAttributeMap(1000, 100, 50, 200),  -- 高速
            },
            [2] = {
                config_id = 1002,
                unique_id = 2,
                level = 10,
                wp_type = 2,
                skills = {1001},
                attribute_map = CreateAttributeMap(1000, 100, 50, 100),  -- 中速
            },
            [3] = {
                config_id = 1003,
                unique_id = 3,
                level = 10,
                wp_type = 3,
                skills = {1001},
                attribute_map = CreateAttributeMap(1000, 100, 50, 50),   -- 低速
            },
        },
        defend_units = {
            [1] = {
                config_id = 2001,
                unique_id = 101,
                level = 10,
                wp_type = 1,
                skills = {1001},
                attribute_map = CreateAttributeMap(1000, 100, 50, 150),
            },
            [2] = {
                config_id = 2002,
                unique_id = 102,
                level = 10,
                wp_type = 2,
                skills = {1001},
                attribute_map = CreateAttributeMap(1000, 100, 50, 120),
            },
            [3] = {
                config_id = 2003,
                unique_id = 103,
                level = 10,
                wp_type = 3,
                skills = {1001},
                attribute_map = CreateAttributeMap(1000, 100, 50, 80),
            },
        },
    },
}

-- ==================== 公共接口 ====================

--- 获取测试战斗配置（兼容旧版格式，返回 beginState）
---@param configType string 配置类型: "1v1", "3v3", "tank_vs_dps", "speed_test"
---@return table beginState 战斗开始状态
function TestBattleConfig.GetTestBattleConfig(configType)
    configType = configType or "1v1"
    
    local config = TestBattleConfig.CONFIG_1V1
    
    if configType == "1v1" then
        config = TestBattleConfig.CONFIG_1V1
    elseif configType == "3v3" then
        config = TestBattleConfig.CONFIG_3V3
    elseif configType == "tank_vs_dps" then
        config = TestBattleConfig.CONFIG_TANK_VS_DPS
    elseif configType == "speed_test" then
        config = TestBattleConfig.CONFIG_SPEED_TEST
    end
    
    -- 转换为 beginState 格式（兼容 battle_main.lua 的接口）
    local beginState = {
        maxRound = config.max_round,
        seedArray = config.random_num,
        teamLeft = {},
        teamRight = {},
    }
    
    -- 转换攻击方（左侧队伍）
    if config.unit_status and config.unit_status.attack_units then
        for _, unit in pairs(config.unit_status.attack_units) do
            local heroData = CreateHeroData(
                unit.config_id,
                "Hero_" .. unit.config_id,
                unit.level,
                unit.wp_type,
                unit.attribute_map,
                unit.skills
            )
            heroData.uniqueId = unit.unique_id
            table.insert(beginState.teamLeft, heroData)
        end
    end
    
    -- 转换防守方（右侧队伍）
    if config.unit_status and config.unit_status.defend_units then
        for _, unit in pairs(config.unit_status.defend_units) do
            local heroData = CreateHeroData(
                unit.config_id,
                "Enemy_" .. unit.config_id,
                unit.level,
                unit.wp_type,
                unit.attribute_map,
                unit.skills
            )
            heroData.uniqueId = unit.unique_id
            table.insert(beginState.teamRight, heroData)
        end
    end
    
    return beginState
end

--- 获取简单 1v1 配置
---@return table beginState 战斗开始状态
function TestBattleConfig.Get1v1Config()
    return TestBattleConfig.GetTestBattleConfig("1v1")
end

--- 获取完整 3v3 配置
---@return table beginState 战斗开始状态
function TestBattleConfig.Get3v3Config()
    return TestBattleConfig.GetTestBattleConfig("3v3")
end

--- 获取坦克vs输出配置
---@return table beginState 战斗开始状态
function TestBattleConfig.GetTankVsDpsConfig()
    return TestBattleConfig.GetTestBattleConfig("tank_vs_dps")
end

--- 获取速度测试配置
---@return table beginState 战斗开始状态
function TestBattleConfig.GetSpeedTestConfig()
    return TestBattleConfig.GetTestBattleConfig("speed_test")
end

--- 创建自定义配置
---@param leftUnits table 左侧队伍单位列表
---@param rightUnits table 右侧队伍单位列表
---@param maxRound number 最大回合数
---@param seedArray table 随机数种子数组
---@return table beginState 战斗开始状态
function TestBattleConfig.CreateCustomConfig(leftUnits, rightUnits, maxRound, seedArray)
    local beginState = {
        maxRound = maxRound or 30,
        seedArray = seedArray or {123456789, 362436069, 521288629, 88675123},
        teamLeft = {},
        teamRight = {},
    }
    
    -- 处理左侧队伍
    if leftUnits then
        for _, unit in ipairs(leftUnits) do
            local heroData = CreateHeroData(
                unit.config_id or 1001,
                unit.name or ("Hero_" .. (unit.config_id or 1001)),
                unit.level or 1,
                unit.wp_type or 1,
                unit.attribute_map or CreateAttributeMap(1000, 100, 50, 100),
                unit.skills or {1001}
            )
            heroData.uniqueId = unit.unique_id or 1
            table.insert(beginState.teamLeft, heroData)
        end
    end
    
    -- 处理右侧队伍
    if rightUnits then
        for _, unit in ipairs(rightUnits) do
            local heroData = CreateHeroData(
                unit.config_id or 2001,
                unit.name or ("Enemy_" .. (unit.config_id or 2001)),
                unit.level or 1,
                unit.wp_type or 1,
                unit.attribute_map or CreateAttributeMap(1000, 100, 50, 100),
                unit.skills or {1001}
            )
            heroData.uniqueId = unit.unique_id or 101
            table.insert(beginState.teamRight, heroData)
        end
    end
    
    return beginState
end

return TestBattleConfig
