EffectRemovePlayerClothes = ChaosEffectBase:derive("EffectRemovePlayerClothes", "remove_player_clothes")

---@param item InventoryItem
local function handleItemRemove(item)
    if not item then return end
    if not item:IsClothing() then return end
    if item:IsInventoryContainer() then return end
    item:Remove()
end


function EffectRemovePlayerClothes:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePlayerClothes] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local itemsList = inventory:getItems()
    if not itemsList then return end


    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemRemove)


    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)
end
