EffectGiveBatteries = ChaosEffectBase:derive("EffectGiveBatteries", "give_batteries")

function EffectGiveBatteries:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local amount = ZombRand(1, 4 + 1)

    for i = 1, amount do
        inventory:AddItem("Base.Battery")
    end
end
