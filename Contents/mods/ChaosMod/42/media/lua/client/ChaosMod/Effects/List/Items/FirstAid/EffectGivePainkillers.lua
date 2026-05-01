EffectGivePainkillers = ChaosEffectBase:derive("EffectGivePainkillers", "give_painkillers")

function EffectGivePainkillers:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGivePainkillers] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    inventory:AddItem("Base.Pills")
end
