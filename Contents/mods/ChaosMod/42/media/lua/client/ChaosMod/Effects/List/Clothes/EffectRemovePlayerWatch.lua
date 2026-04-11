EffectRemovePlayerWatch = ChaosEffectBase:derive("EffectRemovePlayerWatch", "remove_player_watch")

function EffectRemovePlayerWatch:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePlayerWatch] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local itemsList = inventory:getItems()
    if not itemsList then return end

    local watchSubstring = "Base.WristWatch"

    --- clear equipped watches first
    local leftWatch = player:getWornItem(ItemBodyLocation.LEFT_WRIST)
    if leftWatch then
        player:removeWornItem(leftWatch)
    end

    local rightWatch = player:getWornItem(ItemBodyLocation.RIGHT_WRIST)
    if rightWatch then
        player:removeWornItem(rightWatch)
    end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if not item then return end
        if string.find(item:getFullType(), watchSubstring, 1, true) then
            pcall(function() item:Remove() end)
        end
    end)

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)
end
