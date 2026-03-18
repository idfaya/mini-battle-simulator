-- 运行简单战斗测试
package.path = package.path
    .. ";./?.lua"
    .. ";./core/?.lua"
    .. ";./modules/?.lua"
    .. ";./config/?.lua"
    .. ";./utils/?.lua"
    .. ";./test/?.lua"

local SimpleBattleTest = require("test.test_simple_battle")
SimpleBattleTest.Run()
