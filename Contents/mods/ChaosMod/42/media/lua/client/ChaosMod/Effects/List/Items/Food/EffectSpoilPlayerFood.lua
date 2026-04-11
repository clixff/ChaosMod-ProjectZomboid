EffectSpoilPlayerFood = ChaosEffectBase:derive("EffectSpoilPlayerFood", "spoil_player_food")

---@param item InventoryItem
local function handleItemSpoil(item)
    if not item then return end
    if not item:isFood() then return end
    item:setAge(9999)
end

function EffectSpoilPlayerFood:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemSpoil)
end
