EffectGiveSledgehammer = ChaosEffectBase:derive("EffectGiveSledgehammer", "give_sledgehammer")

function EffectGiveSledgehammer:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveSledgehammer] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    inventory:AddItem("Base.Sledgehammer")
end
