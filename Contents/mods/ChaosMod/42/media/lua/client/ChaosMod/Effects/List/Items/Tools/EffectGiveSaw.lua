EffectGiveSaw = ChaosEffectBase:derive("EffectGiveSaw", "give_saw")

function EffectGiveSaw:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveSaw] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    inventory:AddItem("Base.Saw")
end
