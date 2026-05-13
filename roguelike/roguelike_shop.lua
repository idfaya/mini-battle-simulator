local RunShopGoods = require("config.roguelike.run_shop_goods")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local RoguelikeRoster = require("roguelike.roguelike_roster")

local RoguelikeShop = {}

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function addUnique(list, value)
    if not contains(list, value) then
        list[#list + 1] = value
    end
end

local function applyTeamHeal(runState, healPct)
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if not hero.isDead then
            local heal = math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0))
            hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
        end
    end
end

local function reviveOne(runState, healPct)
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if hero.isDead then
            hero.isDead = false
            hero.currentHp = math.max(1, math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0)))
            return true
        end
    end
    return false
end

local function resolveShopGoodsDisplay(item)
    if not item then
        return nil, ""
    end
    if item.goodsType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(item.refId)
        return equipment and equipment.name or ("装备 " .. tostring(item.refId or item.id)), equipment and equipment.code or ""
    end
    if item.goodsType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(item.refId)
        return blessing and blessing.name or ("祝福 " .. tostring(item.refId or item.id)), blessing and blessing.description or ""
    end
    if item.goodsType == "service" then
        if item.code == "team_heal_30" then
            return "队伍治疗", "全队恢复 30% 生命"
        end
        if item.code == "revive_one_40" then
            return "战地复苏", "复活 1 名阵亡单位并恢复 20% 生命"
        end
        if item.code == "remove_one_curse" then
            return "净化仪式", "移除 1 个负面诅咒"
        end
        return "服务", item.code or ""
    end
    return tostring(item.goodsType or "商品"), item.code or ""
end

function RoguelikeShop.GetShop(shopId)
    return RunShopGoods.GetShop(shopId)
end

function RoguelikeShop.GetGoods(goodsId)
    return RunShopGoods.GetGoods(goodsId)
end

function RoguelikeShop.BuildShopState(runState, shopId)
    local shop = RoguelikeShop.GetShop(shopId)
    if not shop then
        return nil
    end

    local goods = {}
    for _, goodsId in ipairs(shop.stock or {}) do
        local item = RoguelikeShop.GetGoods(goodsId)
        if item then
            local name, description = resolveShopGoodsDisplay(item)
            goods[#goods + 1] = {
                goodsId = goodsId,
                goodsType = item.goodsType,
                refId = item.refId,
                code = item.code,
                name = name,
                description = description,
                price = item.price or 0,
                rarity = item.rarity or "common",
                sold = (runState.shopSoldMap or {})[goodsId] == true,
            }
        end
    end

    return {
        shopId = shopId,
        name = shop.name or "Shop",
        refreshCost = shop.refreshCost or 0,
        refreshCount = runState.shopRefreshCount or 0,
        maxRefresh = shop.maxRefresh or 0,
        goods = goods,
    }
end

function RoguelikeShop.Buy(runState, shopId, goodsId)
    local shop = RoguelikeShop.GetShop(shopId)
    local goods = RoguelikeShop.GetGoods(goodsId)
    if not shop or not goods then
        return false, "invalid_shop"
    end

    runState.shopSoldMap = runState.shopSoldMap or {}
    if runState.shopSoldMap[goodsId] then
        return false, "sold_out"
    end

    local price = tonumber(goods.price) or 0
    if (runState.gold or 0) < price then
        return false, "not_enough_gold"
    end
    runState.gold = (runState.gold or 0) - price
    runState.shopSoldMap[goodsId] = true

    if goods.goodsType == "equipment" then
        runState.equipmentIds = runState.equipmentIds or {}
        addUnique(runState.equipmentIds, goods.refId)
        runState.lastActionMessage = "购买装备"
        return true
    end
    if goods.goodsType == "blessing" then
        runState.blessingIds = runState.blessingIds or {}
        addUnique(runState.blessingIds, goods.refId)
        runState.lastActionMessage = "购买祝福"
        return true
    end
    if goods.goodsType == "service" then
        local payload = goods.payload or {}
        local effectType = payload.effectType
        if effectType == "team_heal_pct" then
            applyTeamHeal(runState, payload.value)
            runState.lastActionMessage = "商店治疗"
            return true
        end
        if effectType == "revive_one" then
            local revived = reviveOne(runState, payload.healPct or 0.4)
            if not revived then
                return false, "no_dead_hero"
            end
            runState.lastActionMessage = "商店复活"
            return true
        end
        if effectType == "remove_one_curse" then
            runState.lastActionMessage = "移除诅咒(占位)"
            return true
        end
        return false, "unsupported_service"
    end

    return false, "unsupported_goods"
end

function RoguelikeShop.Refresh(runState, shopId)
    local shop = RoguelikeShop.GetShop(shopId)
    if not shop then
        return false, "invalid_shop"
    end
    local maxRefresh = shop.maxRefresh or 0
    runState.shopRefreshCount = runState.shopRefreshCount or 0
    if maxRefresh > 0 and runState.shopRefreshCount >= maxRefresh then
        return false, "refresh_limit"
    end
    local cost = tonumber(shop.refreshCost) or 0
    if (runState.gold or 0) < cost then
        return false, "not_enough_gold"
    end
    runState.gold = (runState.gold or 0) - cost
    runState.shopRefreshCount = runState.shopRefreshCount + 1

    -- For vertical slice: keep the same stock but reset sold flags.
    runState.shopSoldMap = {}
    runState.lastActionMessage = "刷新商店"
    return true
end

return RoguelikeShop
