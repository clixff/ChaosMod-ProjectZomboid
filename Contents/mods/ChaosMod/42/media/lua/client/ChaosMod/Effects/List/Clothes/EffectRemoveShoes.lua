EffectRemoveShoes = ChaosEffectBase:derive("EffectRemoveShoes", "remove_shoes")

function EffectRemoveShoes:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveShoes] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local playerInventory = player:getInventory()
    if not playerInventory then return end

    local shoes = player:getWornItem(ItemBodyLocation.SHOES)
    print("[EffectRemoveShoes] Shoes: " .. tostring(shoes))

    if shoes then
        playerInventory:Remove(shoes)
        pcall(function() shoes:removeFromWorld() end)

        player:onWornItemsChanged()
        local worn = player:getWornItems()

        ---@diagnostic disable-next-line: param-type-mismatch
        pcall(function() worn:setItem(ItemBodyLocation.SHOES, nil) end)
    end

    player:resetModelNextFrame()
end
