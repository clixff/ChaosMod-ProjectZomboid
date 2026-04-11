EffectGiveWizardHat = ChaosEffectBase:derive("EffectGiveWizardHat", "give_wizard_hat")

function EffectGiveWizardHat:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveWizardHat] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local itemsList = inventory:getItems()
    if not itemsList then return end


    local wizardHat = inventory:AddItem("Base.Hat_Wizard")

    local oldHat = player:getWornItem(ItemBodyLocation.HAT)
    if oldHat then
        player:removeWornItem(oldHat)
        player:getInventory():Remove(oldHat)
        local sq = player:getSquare()
        if sq then sq:AddWorldInventoryItem(oldHat, 0, 0, 0) end
    end

    player:setClothingItem_Head(wizardHat)

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)
end
