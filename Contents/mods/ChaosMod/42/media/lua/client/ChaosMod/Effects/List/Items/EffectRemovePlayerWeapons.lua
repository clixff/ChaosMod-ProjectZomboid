EffectRemovePlayerWeapons = ChaosEffectBase:derive("EffectRemovePlayerWeapons", "remove_player_weapons")


---@param item InventoryItem
local function handleItemRemove(item)
    if not item then return end
    if not item:IsWeapon() then return end
    item:Remove()
end

function EffectRemovePlayerWeapons:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePlayerWeapons] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemRemove)
end
