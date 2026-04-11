EffectRemovePants = ChaosEffectBase:derive("EffectRemovePants", "remove_pants")

function EffectRemovePants:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePants] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local playerInventory = player:getInventory()
    if not playerInventory then return end

    local tagsToRemove = { ItemBodyLocation.PANTS, ItemBodyLocation.LEGS1, ItemBodyLocation.LEGS5, ItemBodyLocation
        .SHORTS_SHORT, ItemBodyLocation.SHORT_PANTS, ItemBodyLocation.PANTS_EXTRA, ItemBodyLocation.PANTS_SKINNY }

    local wornItems = player:getWornItems()
    if not wornItems then return end

    for _, tag in ipairs(tagsToRemove) do
        local item = wornItems:getItem(tag)

        if item then
            ---@diagnostic disable-next-line: param-type-mismatch
            pcall(function() wornItems:setItem(tag, nil) end)
            playerInventory:Remove(item)
            pcall(function() item:removeFromWorld() end)
        end
    end


    player:onWornItemsChanged()
    player:resetModelNextFrame()
end
