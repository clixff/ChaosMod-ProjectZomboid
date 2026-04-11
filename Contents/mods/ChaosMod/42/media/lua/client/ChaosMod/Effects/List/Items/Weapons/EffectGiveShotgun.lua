EffectGiveShotgun = ChaosEffectBase:derive("EffectGiveShotgun", "give_shotgun")

function EffectGiveShotgun:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveShotgun] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end


    inventory:AddItem("Base.ShotgunShellsBox")
    local item = inventory:AddItem("Base.Shotgun")
    ---@type HandWeapon
    local handWeapon = item

    handWeapon:setCurrentAmmoCount(handWeapon:getMaxAmmo() - 1)
    handWeapon:setRoundChambered(true)

    if (item) then
        ChaosPlayer.EquipWeapon(player, item)
        ChaosPlayer.SayLineNewItem(player, item, 1)
    end
end
