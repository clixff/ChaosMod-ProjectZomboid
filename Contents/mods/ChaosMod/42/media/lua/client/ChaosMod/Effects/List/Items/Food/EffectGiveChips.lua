EffectGiveChips = ChaosEffectBase:derive("EffectGiveChips", "give_chips")

function EffectGiveChips:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveChips] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local amount = ZombRand(1, 2 + 1)

    for i = 1, amount do
        inventory:AddItem("Base.Crisps")
    end
end
