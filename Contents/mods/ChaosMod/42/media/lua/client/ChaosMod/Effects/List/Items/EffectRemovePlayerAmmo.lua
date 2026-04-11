EffectRemovePlayerAmmo = ChaosEffectBase:derive("EffectRemovePlayerAmmo", "remove_player_ammo")


---@param item InventoryItem
local function handleItemRemove(item)
    if not item then return end

    if item:getCategory() == "Ammo" or item:getDisplayCategory() == "Ammo" then
        item:Remove()
        return
    end

    if item:IsWeapon() then
        ---@class HandWeapon
        local handWeapon = item

        if not handWeapon.isRanged then
            return
        end

        if not handWeapon:isRanged() then
            return
        end

        -- Clear loaded rounds
        if handWeapon:getCurrentAmmoCount() > 0 then
            handWeapon:setCurrentAmmoCount(0)
        end

        -- Clear chambered round
        if handWeapon:isRoundChambered() then
            handWeapon:setRoundChambered(false)
        end

        -- Remove inserted magazine
        if handWeapon:isContainsClip() then
            handWeapon:setContainsClip(false)
        end
    end
end

function EffectRemovePlayerAmmo:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePlayerAmmo] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemRemove)
end
