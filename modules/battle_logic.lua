---
--- Battle Logic Compatibility Shim
--- LEGACY SHIM: 旧回合驱动已并入 BattleMain，此模块仅保留最小兼容接口。
--- 新逻辑不要继续依赖这里；仅为仍读取 BattleLogic 状态的旧代码提供转发。
---

local BattleLogic = {}

function BattleLogic.GetCurRound()
    local BattleMain = require("modules.battle_main")
    return tonumber(BattleMain.GetCurrentRound and BattleMain.GetCurrentRound()) or 0
end

function BattleLogic.GetBattleStatus()
    local BattleMain = require("modules.battle_main")
    local result = BattleMain.GetBattleResult and BattleMain.GetBattleResult() or nil
    return {
        isBattleFinish = result and result.isFinished == true or false,
        win = result and result.winner == "left" or false,
        curRound = BattleLogic.GetCurRound(),
    }
end

return BattleLogic
