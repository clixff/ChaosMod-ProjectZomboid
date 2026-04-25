EffectSpoilPlayerFood = ChaosEffectBase:derive("EffectSpoilPlayerFood", "spoil_player_food")


function EffectSpoilPlayerFood:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local itemsSpoiled = 0

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if not item then return end
        if not item:isFood() then return end
        -- Non-perishable items use huge OffAgeMax values.
        if item:getOffAgeMax() >= 1000000000 then
            return
        end
        item:setAge(item:getOffAgeMax() + 1)
        item:updateAge()
        itemsSpoiled = itemsSpoiled + 1
    end)

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString("Base.Bread")
    local str = string.format(ChaosLocalization.GetString("misc", "food_spoiled"), imgCode, itemsSpoiled)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
end
