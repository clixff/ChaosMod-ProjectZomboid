EffectRemovePlayerGloves = ChaosEffectBase:derive("EffectRemovePlayerGloves", "remove_player_gloves")

function EffectRemovePlayerGloves:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePlayerGloves] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local itemsList = inventory:getItems()
    if not itemsList then return end

    local wornGloves = player:getClothingItem_Hands()
    if wornGloves then
        player:removeWornItem(wornGloves)
    end

    -- backward loop to avoid issues with removing items from the table while iterating
    for i = itemsList:size() - 1, 0, -1 do
        local item = itemsList:get(i)
        if item then
            if item:IsClothing() and item:getBodyLocation() == ItemBodyLocation.HANDS then
                pcall(function() inventory:Remove(item) end)
                pcall(function() item:removeFromWorld() end)

                itemsList:remove(i)
            end
        end
    end

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)
end
