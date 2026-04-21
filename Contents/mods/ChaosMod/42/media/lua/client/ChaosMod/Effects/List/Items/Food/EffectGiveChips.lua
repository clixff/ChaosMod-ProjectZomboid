EffectGiveChips = ChaosEffectBase:derive("EffectGiveChips", "give_chips")

function EffectGiveChips:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveChips] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local amount = math.floor(ZombRand(1, 2 + 1))

    for i = 1, amount do
        local item = inventory:AddItem("Base.Crisps")
        if item and i == 1 then
            ChaosPlayer.SayLineNewItem(player, item, amount)
        end
    end
end
