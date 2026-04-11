EffectRepairPlayerWeapons = ChaosEffectBase:derive("EffectRepairPlayerWeapons", "repair_player_weapons")

---@param item InventoryItem
local function handleItemRepair(item)
    if not item then return end
    if not item:IsWeapon() then return end
    item:setConditionNoSound(item:getConditionMax())
end

function EffectRepairPlayerWeapons:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemRepair)
end
