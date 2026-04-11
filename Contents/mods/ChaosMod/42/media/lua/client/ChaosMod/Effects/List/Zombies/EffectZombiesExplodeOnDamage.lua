EffectZombiesExplodeOnDamage = ChaosEffectBase:derive("EffectZombiesExplodeOnDamage", "zombies_explode_on_damage")


---
---@param _attacker IsoGameCharacter
---@param target IsoGameCharacter
---@param weapon HandWeapon
---@param damage number
local function OnZombieDamaged(_attacker, target, weapon, damage)
    if not target then return end
    if not target:isZombie() then return end

    print("[EffectZombiesExplodeOnDamage] Weapon: " .. weapon:getFullType())
    if weapon:getFullType() == "Base.PipeBomb" then
        local health = target:getHealth()
        print("[EffectZombiesExplodeOnDamage] Health: " .. tostring(health) .. " [damage] " .. tostring(damage))
        return
    end

    local square = target:getSquare()
    if not square then return end

    ChaosUtils.TriggerExplosionAt(square, 5)
    print("[EffectZombiesExplodeOnDamage] Zombie exploded on damage")
end

function EffectZombiesExplodeOnDamage:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectZombiesExplodeOnDamage] OnStart" .. tostring(self.effectId))

    Events.OnWeaponHitCharacter.Add(OnZombieDamaged)
end

function EffectZombiesExplodeOnDamage:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnWeaponHitCharacter.Remove(OnZombieDamaged)
end
