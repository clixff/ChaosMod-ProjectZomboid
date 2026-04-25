EffectGiveM16Rifle = ChaosEffectBase:derive("EffectGiveM16Rifle", "give_m16_rifle")

function EffectGiveM16Rifle:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveM16Rifle] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    local item = inventory:AddItem("Base.AssaultRifle")
    ---@type HandWeapon
    local handWeapon = item

    handWeapon:setCurrentAmmoCount(handWeapon:getMaxAmmo() - 1)
    handWeapon:setRoundChambered(true)

    if (item) then
        ChaosPlayer.SayLineNewItem(player, item, 1)
    end
end
