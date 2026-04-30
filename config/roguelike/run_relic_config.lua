local RunEquipmentConfig = require("config.roguelike.run_equipment_config")

local RunRelicConfig = {
    RELICS = RunEquipmentConfig.EQUIPMENTS,
}

function RunRelicConfig.GetRelic(relicId)
    return RunEquipmentConfig.GetEquipment(relicId)
end

return RunRelicConfig
