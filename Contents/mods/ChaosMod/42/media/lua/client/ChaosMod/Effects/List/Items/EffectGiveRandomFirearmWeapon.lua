---@class EffectGiveRandomFirearmWeapon : ChaosEffectBase
EffectGiveRandomFirearmWeapon = ChaosEffectBase:derive("EffectGiveRandomFirearmWeapon", "give_random_firearm_weapon")

function EffectGiveRandomFirearmWeapon:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomFirearmWeapon] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local weaponId = ChaosItems.GetRandomFirearmWeaponID()
    if not weaponId then return end

    local newItem = inventory:AddItem(weaponId)
    if not newItem then return end

    ChaosPlayer.EquipWeapon(player, newItem)

    ---@type HandWeapon
    local handWeapon = newItem

    local isFiream = handWeapon:isRanged()

    if handWeapon and isFiream then
        handWeapon:setCurrentAmmoCount(handWeapon:getMaxAmmo() - 1)
        handWeapon:setRoundChambered(true)
    end

    ChaosPlayer.SayLineNewItem(player, newItem)
end

function EffectGiveRandomFirearmWeapon:OnEnd()
    ChaosEffectBase:OnEnd()
end
