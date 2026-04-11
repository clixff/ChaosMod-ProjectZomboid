EffectRemovePlayerFood = ChaosEffectBase:derive("EffectRemovePlayerFood", "remove_player_food")

---@param item InventoryItem
local function handleItemRemove(item)
    if not item then return end
    if not item:isFood() then return end
    item:Remove()
end

function EffectRemovePlayerFood:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemRemove)
end
