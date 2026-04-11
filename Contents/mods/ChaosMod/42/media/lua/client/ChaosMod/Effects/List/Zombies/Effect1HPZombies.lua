---@class Effect1HPZombies : ChaosEffectBase
Effect1HPZombies = ChaosEffectBase:derive("Effect1HPZombies", "1hp_zombies")


---
---@param attacker IsoGameCharacter
---@param target IsoGameCharacter
---@param weapon HandWeapon
---@param damage number
local function OnZombieDamaged(attacker, target, weapon, damage)
    if not target then return end
    if not target:isZombie() then return end

    target:setHealth(0)
    target:DoDeath(weapon, attacker)
end

function Effect1HPZombies:OnStart()
    ChaosEffectBase:OnStart()
    print("[Effect1HPZombies] OnStart" .. tostring(self.effectId))

    Events.OnWeaponHitCharacter.Add(OnZombieDamaged)
end

function Effect1HPZombies:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnWeaponHitCharacter.Remove(OnZombieDamaged)
end
