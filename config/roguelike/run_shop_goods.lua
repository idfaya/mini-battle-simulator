---@alias RunShopGoodsType
---| "equipment"
---| "blessing"
---| "service"

---@alias RunShopRarity
---| "common"
---| "rare"
---| "boss"

---@alias RunShopServiceEffectType
---| "team_heal_pct"
---| "revive_one"
---| "remove_one_curse"

---@class RunShopServicePayload
---@field effectType RunShopServiceEffectType
---@field value number|nil
---@field healPct number|nil

---@class RunShopEntry
---@field id integer
---@field chapterId integer
---@field code string
---@field name string
---@field refreshCost integer
---@field maxRefresh integer
---@field stock integer[]

---@class RunGoodsEntry
---@field id integer
---@field goodsType RunShopGoodsType
---@field refId integer|nil
---@field code string|nil
---@field price integer
---@field rarity RunShopRarity
---@field payload RunShopServicePayload|nil

---@class RunShopGoodsModule
---@field SHOPS table<integer, RunShopEntry>
---@field GOODS table<integer, RunGoodsEntry>
---@field GetShop fun(shopId: integer): RunShopEntry|nil
---@field GetGoods fun(goodsId: integer): RunGoodsEntry|nil

---@type RunShopGoodsModule
local RunShopGoods = {}

---@type table<integer, RunShopEntry>
RunShopGoods.SHOPS = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        code = "ash_merchant",
        name = "Ash Merchant",
        refreshCost = 18,
        maxRefresh = 3,
        stock = {
            101001,
            101002,
            101003,
            101004,
            101005,
            101006,
            101007,
            101008,
        },
    },
}

---@type table<integer, RunGoodsEntry>
RunShopGoods.GOODS = {
    [101001] = {
        id = 101001,
        goodsType = "equipment",
        refId = 101001,
        price = 68,
        rarity = "common",
    },
    [101002] = {
        id = 101002,
        goodsType = "equipment",
        refId = 101002,
        price = 76,
        rarity = "common",
    },
    [101003] = {
        id = 101003,
        goodsType = "blessing",
        refId = 101002,
        price = 42,
        rarity = "common",
    },
    [101004] = {
        id = 101004,
        goodsType = "equipment",
        refId = 101003,
        price = 88,
        rarity = "rare",
    },
    [101005] = {
        id = 101005,
        goodsType = "equipment",
        refId = 101004,
        price = 92,
        rarity = "rare",
    },
    [101006] = {
        id = 101006,
        goodsType = "service",
        code = "team_heal_30",
        price = 28,
        rarity = "common",
        payload = {
            effectType = "team_heal_pct",
            value = 0.30,
        },
    },
    [101007] = {
        id = 101007,
        goodsType = "service",
        code = "revive_one_40",
        price = 54,
        rarity = "rare",
        payload = {
            effectType = "revive_one",
            healPct = 0.20,
        },
    },
    [101008] = {
        id = 101008,
        goodsType = "service",
        code = "remove_one_curse",
        price = 36,
        rarity = "common",
        payload = {
            effectType = "remove_one_curse",
        },
    },
}

function RunShopGoods.GetShop(shopId)
    return RunShopGoods.SHOPS[shopId]
end

function RunShopGoods.GetGoods(goodsId)
    return RunShopGoods.GOODS[goodsId]
end

return RunShopGoods
