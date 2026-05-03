EffectRemovePlayerHat = ChaosEffectBase:derive("EffectRemovePlayerHat", "remove_player_hat")

function EffectRemovePlayerHat:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemovePlayerHat] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local playerInventory = player:getInventory()
    if not playerInventory then return end

    local tagsToRemove = { ItemBodyLocation.HAT, ItemBodyLocation.FULLHAT }

    local wornItems = player:getWornItems()
    if not wornItems then return end

    for _, tag in ipairs(tagsToRemove) do
        local item = wornItems:getItem(tag)

        if item then
            ChaosPlayer.SayLineRemovedItem(player, item)
            ---@diagnostic disable-next-line: param-type-mismatch
            pcall(function() wornItems:setItem(tag, nil) end)
            playerInventory:Remove(item)
            pcall(function() item:removeFromWorld() end)
        end
    end

    player:onWornItemsChanged()
    player:resetModelNextFrame()
end
