local RunShopGoods = {}

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

RunShopGoods.GOODS = {
    [101001] = {
        id = 101001,
        goodsType = "relic",
        refId = 101001,
        price = 68,
        rarity = "common",
    },
    [101002] = {
        id = 101002,
        goodsType = "relic",
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
        goodsType = "recruit",
        refId = 900001,
        price = 78,
        rarity = "common",
    },
    [101005] = {
        id = 101005,
        goodsType = "recruit",
        refId = 900007,
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
            value = 0.45,
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
            healPct = 0.60,
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
