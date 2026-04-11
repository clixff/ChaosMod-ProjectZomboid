EffectDuplicateItems = ChaosEffectBase:derive("EffectDuplicateItems", "duplicate_items")

function EffectDuplicateItems:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectDuplicateItems] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local square = player:getSquare()
    if not square then return end


    ChaosPlayer.RecursiveInventoryLookup(inventory, false, false, function(oldItem)
        local fullType = oldItem:getFullType()
        if fullType then
            local oldFluid = oldItem:getFluidContainerFromSelfOrWorldItem()
            local x = ZombRandFloat(0.15, 0.85)
            local y = ZombRandFloat(0.15, 0.85)
            local newItem = square:AddWorldInventoryItem(fullType, x, y, 0.0)
            if newItem then
                newItem:copyConditionStatesFrom(oldItem)
                newItem:CopyModData(oldItem:getModData())
                local newFluid = newItem:getFluidContainerFromSelfOrWorldItem()

                if newFluid and oldFluid then
                    newFluid:copyFluidsFrom(oldFluid)
                end
            end
        end
    end)
end
