EffectGiveChickenHat = ChaosEffectBase:derive("EffectGiveChickenHat", "give_chicken_hat")

function EffectGiveChickenHat:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveChickenHat] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local itemsList = inventory:getItems()
    if not itemsList then return end


    local chickenHat = inventory:AddItem("Base.Hat_Jay")

    local oldHat = player:getWornItem(ItemBodyLocation.HAT)
    if oldHat then
        player:removeWornItem(oldHat)
        player:getInventory():Remove(oldHat)
        local sq = player:getSquare()
        if sq then sq:AddWorldInventoryItem(oldHat, 0, 0, 0) end
    end

    player:setClothingItem_Head(chickenHat)

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)

    ChaosPlayer.SayLineNewItem(player, chickenHat)
end
