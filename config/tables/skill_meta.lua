local SkillConfig = require("config.tables.skills")

---@alias Skill5eMetaKind
---| "physical"
---| "spell"
---| "auto"

---@alias Skill5eSaveType
---| "fort"
---| "ref"
---| "will"

---@alias Skill5eOnSaveSuccess
---| "half"
---| "none"

---@alias Skill5eAttackMode
---| "physical_attack"
---| "spell_attack"
---| "spell_save"

---@class Skill5eMetaEntry
---@field kind Skill5eMetaKind
---@field saveType Skill5eSaveType|nil
---@field onSaveSuccess Skill5eOnSaveSuccess|nil
---@field isAOE boolean|nil
---@field hardControl boolean|nil
---@field damageDice string|nil
---@field stageDamageDice table<integer, string>|nil
---@field healDice string|nil
---@field chainDice string|nil
---@field diceScale number|nil
---@field chantTurns integer|nil
---@field concentration boolean|nil
---@field revivePct number|nil
---@field revivePenaltyTurns integer|nil
---@field revivePenaltyAtkMul number|nil
---@field revivePenaltyDefMul number|nil
---@field revivePenaltySpeedMul number|nil
---@field role string|nil
---@field notes string|nil
---@field tierNotes table<integer, string>|nil
---@field attackMode Skill5eAttackMode|nil

---@class Skill5eMetaModule
---@field Get fun(skillId: integer): Skill5eMetaEntry

---@type Skill5eMetaModule
local Skill5eMeta = {}

local DEFAULT_DICE_SCALE = 1

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for k, v in pairs(value) do
        result[k] = deepCopy(v)
    end
    return result
end

local function resolveDefault(skillId)
    local classId = math.floor((tonumber(skillId) or 0) / 100) * 100
    if classId >= 80006000 and classId <= 80009000 then
        -- Spell classes by ID range: 80006xxx..80009xxx
        return { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half" }
    end
    return { kind = "physical" }
end

function Skill5eMeta.ResolveAttackMode(meta)
    if type(meta) ~= "table" then
        return "physical_attack"
    end
    if meta.attackMode == "spell_attack" or meta.attackMode == "spell_save" or meta.attackMode == "physical_attack" then
        return meta.attackMode
    end
    if meta.kind == "spell" then
        return "spell_save"
    end
    return "physical_attack"
end

function Skill5eMeta.ResolveStageDamageDice(skillId, skillLevel)
    local meta = Skill5eMeta.Get(skillId)
    local staged = meta and meta.stageDamageDice
    if type(staged) ~= "table" then
        return meta and meta.damageDice or nil
    end
    local function getStageDice(stage)
        return staged[stage] or staged[tostring(stage)]
    end
    local level = math.max(1, math.floor(tonumber(skillLevel) or 1))
    if level <= 1 then
        return getStageDice(1) or meta.damageDice
    end
    if level == 2 then
        return getStageDice(2) or getStageDice(1) or meta.damageDice
    end
    return getStageDice(3) or getStageDice(2) or getStageDice(1) or meta.damageDice
end

function Skill5eMeta.Get(skillId)
    local id = tonumber(skillId) or 0
    local skillDef = SkillConfig.GetSkillConfig(id)
    local rawMeta = deepCopy(skillDef and skillDef.rules or nil)
    local meta = rawMeta or resolveDefault(id)
    -- Ensure defaults.
    if meta.diceScale == nil then
        meta.diceScale = DEFAULT_DICE_SCALE
    end
    if meta.chantTurns == nil then
        meta.chantTurns = 0
    end
    if meta.concentration == nil then
        meta.concentration = false
    end
    if meta.attackMode == nil then
        meta.attackMode = Skill5eMeta.ResolveAttackMode(meta)
    end
    if meta.kind == "spell" then
        if meta.isAOE == nil then meta.isAOE = false end
        if meta.hardControl == nil then meta.hardControl = false end
        if meta.onSaveSuccess == nil then
            -- Project rule: AOE defaults to half, hard control defaults to none.
            meta.onSaveSuccess = meta.isAOE and "half" or "half"
            if meta.hardControl and not meta.isAOE then
                meta.onSaveSuccess = "none"
            end
        end
        if meta.saveType == nil then
            meta.saveType = "ref"
        end
    end
    return meta
end

return Skill5eMeta
