EffectGiveFlashlight = ChaosEffectBase:derive("EffectGiveFlashlight", "give_flashlight")

function EffectGiveFlashlight:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveFlashlight] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem("Base.HandTorch")
    if item then
        ChaosPlayer.SayLineNewItem(player, item)
    end
end
