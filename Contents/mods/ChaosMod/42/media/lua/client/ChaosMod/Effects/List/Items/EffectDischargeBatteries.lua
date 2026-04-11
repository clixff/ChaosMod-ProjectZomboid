EffectDischargeBatteries = ChaosEffectBase:derive("EffectDischargeBatteries", "discharge_batteries")

---@param item InventoryItem
local function handleItemDischarge(item)
    if not item then return end
    local fullType = item:getFullType()

    if fullType == "Base.Battery" then
        item:setCurrentUsesFloat(0)
    end

    if item:IsDrainable() then
        item:setCurrentUsesFloat(0)
    end

    if instanceof(item, "Radio") then
        item:setCurrentUsesFloat(0)
        if item:isActivated() then
            item:setActivated(false)
        end
    end
end

function EffectDischargeBatteries:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemDischarge)
end
