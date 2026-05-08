EffectReplaceItemsWithRocks = ChaosEffectBase:derive("EffectReplaceItemsWithRocks", "replace_items_with_rocks")

local REPLACE_CHANCE = 33
local ROCK_ITEM_ID = "Base.Stone2"

function EffectReplaceItemsWithRocks:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectReplaceItemsWithRocks] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local shouldRefreshClothes = false

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if not item then return end
        if ChaosUtils.RandInteger(100) >= REPLACE_CHANCE then return end

        local container = item:getContainer()
        if not container then return end

        local worn = player:getWornItems()
        if worn and worn:contains(item) then
            player:removeWornItem(item)
            shouldRefreshClothes = true
        end

        player:removeFromHands(item)
        ChaosPlayer.SayLineRemoveItem(player, item)

        container:Remove(item)
        container:AddItem(ROCK_ITEM_ID)
    end)

    if shouldRefreshClothes then
        player:onWornItemsChanged()
        player:resetModelNextFrame()
        triggerEvent("OnClothingUpdated", player)
    end
end
