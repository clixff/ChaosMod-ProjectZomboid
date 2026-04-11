EffectGiveRandomFood = ChaosEffectBase:derive("EffectGiveRandomFood", "give_random_food")

function EffectGiveRandomFood:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomFood] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local foodId = ChaosItems.GetRandomFoodItemId()
    if not foodId then return end

    local newItem = inventory:AddItem(foodId)
    if not newItem then return end

    ChaosPlayer.SayLineNewItem(player, newItem)
end
