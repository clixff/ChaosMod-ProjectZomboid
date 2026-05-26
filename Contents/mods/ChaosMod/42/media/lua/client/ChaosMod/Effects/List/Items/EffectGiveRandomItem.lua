EffectGiveRandomItem = ChaosEffectBase:derive("EffectGiveRandomItem", "give_random_item")

function EffectGiveRandomItem:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomItem] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local amount = 3

    for i = 1, amount do
        local itemId = ChaosItems.GetRandomItemId()
        if itemId then
            local item = inventory:AddItem(itemId)
            if item then
                ChaosPlayer.SayLineNewItem(player, item)
            end
        end
    end
end
