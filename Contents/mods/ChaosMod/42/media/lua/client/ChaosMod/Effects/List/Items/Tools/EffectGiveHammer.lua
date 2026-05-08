EffectGiveHammer = ChaosEffectBase:derive("EffectGiveHammer", "give_hammer")

function EffectGiveHammer:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveHammer] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local newItem = inventory:AddItem("Base.Hammer")
    if not newItem then return end

    ChaosPlayer.SayLineNewItem(player, newItem)
end
