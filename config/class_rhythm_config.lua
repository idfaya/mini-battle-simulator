---@class ClassRhythmConfig
---@field spellDiceScalarByClass table<integer, number>
---@field physicalDiceScalarByClass table<integer, number>
---@field healScalarByClass table<integer, number>

---@type ClassRhythmConfig
local ClassRhythmConfig = {
    spellDiceScalarByClass = {
        [6] = 1.00,
        [7] = 1.00,
        [8] = 1.00,
        [9] = 1.00,
    },
    physicalDiceScalarByClass = {
        [1] = 1.00,
        [2] = 1.00,
        [3] = 1.00,
        [4] = 1.00,
        [5] = 1.00,
    },
    healScalarByClass = {
        [4] = 1.00,
        [6] = 1.00,
    },
}

return ClassRhythmConfig
