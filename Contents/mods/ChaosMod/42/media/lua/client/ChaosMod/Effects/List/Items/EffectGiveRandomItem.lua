EffectGiveRandomItem = ChaosEffectBase:derive("EffectGiveRandomItem", "give_random_item")

function EffectGiveRandomItem:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomItem] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local itemType = ChaosItems.GetRandomItemId()

    if not itemType then return end
    print("[EffectGiveRandomItem] Giving item: " .. itemType)

    local newItem = inventory:AddItem(itemType)

    if newItem then
        ChaosPlayer.SayLineNewItem(player, newItem)
    end
end
