EffectGiveDogFood = ChaosEffectBase:derive("EffectGiveDogFood", "give_dog_food")

function EffectGiveDogFood:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveDogFood] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local amount = math.floor(ZombRand(1, 2 + 1))

    ChaosPlayer.SayLineNewItemByString(player, "Base.Dogfood", amount)

    for i = 1, amount do
        local item = inventory:AddItem("Base.Dogfood")
    end
end
