EffectGiveBatteries = ChaosEffectBase:derive("EffectGiveBatteries", "give_batteries")

function EffectGiveBatteries:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local amount = math.floor(ZombRand(1, 4 + 1))
    ---@type InventoryItem?
    local item = nil

    for i = 1, amount do
        item = inventory:AddItem("Base.Battery")
    end

    if item then
        ChaosPlayer.SayLineNewItem(player, item, amount)
    end
end
