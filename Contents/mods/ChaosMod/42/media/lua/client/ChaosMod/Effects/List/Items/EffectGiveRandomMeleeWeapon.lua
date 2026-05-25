---@class EffectGiveRandomMeleeWeapon : ChaosEffectBase
EffectGiveRandomMeleeWeapon = ChaosEffectBase:derive("EffectGiveRandomMeleeWeapon", "give_random_melee_weapon")

function EffectGiveRandomMeleeWeapon:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomMeleeWeapon] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local weaponId = ChaosItems.GetRandomMeleeWeaponID()
    if not weaponId then return end

    local newItem = inventory:AddItem(weaponId)
    if not newItem then return end

    ChaosPlayer.EquipWeapon(player, newItem)

    ChaosPlayer.SayLineNewItem(player, newItem)
end

function EffectGiveRandomMeleeWeapon:OnEnd()
    ChaosEffectBase:OnEnd()
end
