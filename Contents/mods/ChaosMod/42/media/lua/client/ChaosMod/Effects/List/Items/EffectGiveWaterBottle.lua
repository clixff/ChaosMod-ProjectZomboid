EffectGiveWaterBottle = ChaosEffectBase:derive("EffectGiveWaterBottle", "give_water_bottle")

function EffectGiveWaterBottle:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveWaterBottle] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local newItem = inventory:AddItem("Base.WaterBottle")
    if not newItem then return end

    ChaosPlayer.SayLineNewItem(player, newItem)
end
