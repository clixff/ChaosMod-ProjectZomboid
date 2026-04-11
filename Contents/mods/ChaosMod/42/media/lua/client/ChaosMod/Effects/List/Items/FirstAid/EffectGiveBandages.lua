EffectGiveBandages = ChaosEffectBase:derive("EffectGiveBandages", "give_bandages")

function EffectGiveBandages:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBandages] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local amount = math.floor(ZombRand(1, 5 + 1))

    for i = 1, amount do
        local item = inventory:AddItem("Base.Bandage")
        if i == amount then
            ChaosPlayer.SayLineNewItem(player, item, amount)
        end
    end
end
