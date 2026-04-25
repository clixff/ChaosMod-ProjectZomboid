EffectGiveKatana = ChaosEffectBase:derive("EffectGiveKatana", "give_katana")

function EffectGiveKatana:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveKatana] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local newItem = inventory:AddItem("Base.Katana")

    if newItem then
        ChaosPlayer.EquipWeapon(player, newItem)
        ChaosPlayer.SayLineNewItem(player, newItem)
    end
end
