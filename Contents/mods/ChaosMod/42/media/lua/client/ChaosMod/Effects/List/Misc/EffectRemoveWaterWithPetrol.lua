EffectReplaceWaterWithPetrol = ChaosEffectBase:derive("EffectReplaceWaterWithPetrol", "replace_water_with_petrol")

---@param item InventoryItem
---@return boolean
local function handleItem(item)
    if not item then return false end
    if item:IsInventoryContainer() then return false end

    local fluidContainer = item:getFluidContainer()
    if not fluidContainer then return false end

    if fluidContainer:isWaterSource() then
        local amount = fluidContainer:getAmount()
        fluidContainer:Empty()
        fluidContainer:addFluid(FluidType.Petrol, amount)
        return true
    end

    return false
end


function EffectReplaceWaterWithPetrol:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectReplaceWaterWithPetrol] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local itemsList = inventory:getItems()
    if not itemsList then return end

    local count = 0

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if handleItem(item) then
            count = count + 1
        end
    end)

    player:Say(string.format("Replaced %d water containers with petrol", count))
end
