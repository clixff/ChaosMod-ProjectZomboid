EffectGiveBaseballBat = ChaosEffectBase:derive("EffectGiveBaseballBat", "give_baseball_bat")

function EffectGiveBaseballBat:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBaseballBat] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local newItem = inventory:AddItem("Base.BaseballBat")


    if newItem then
        ChaosPlayer.EquipWeapon(player, newItem)
        ChaosPlayer.SayLineNewItem(player, newItem)
    end
end
