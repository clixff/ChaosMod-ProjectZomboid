EffectGiveM9Pistol = ChaosEffectBase:derive("EffectGiveM9Pistol", "give_m9_pistol")

function EffectGiveM9Pistol:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveM9Pistol] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem("Base.Pistol")
    ---@type HandWeapon
    local handWeapon = item

    handWeapon:setCurrentAmmoCount(handWeapon:getMaxAmmo() - 1)
    handWeapon:setRoundChambered(true)

    ChaosPlayer.SayLineNewItem(player, item, 1)
end
