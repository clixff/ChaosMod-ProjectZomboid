EffectGiveSpoonWeapon = ChaosEffectBase:derive("EffectGiveSpoonWeapon", "give_spoon_weapon")

function EffectGiveSpoonWeapon:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveSpoonWeapon] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local newItem = inventory:AddItem("Base.Spoon")

    if newItem then
        ChaosPlayer.EquipWeapon(player, newItem)
        ChaosPlayer.SayLineNewItem(player, newItem)
    end
end
