-- 运行技能战斗测试
package.path = package.path
    .. ";./?.lua"
    .. ";./core/?.lua"
    .. ";./modules/?.lua"
    .. ";./config/?.lua"
    .. ";./utils/?.lua"
    .. ";./test/?.lua"

local BattleWithSkills = require("test.test_battle_with_skills")
BattleWithSkills.Run()
