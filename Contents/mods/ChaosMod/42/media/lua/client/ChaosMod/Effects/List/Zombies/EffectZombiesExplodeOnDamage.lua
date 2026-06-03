---@class EffectZombiesExplodeOnDamage : ChaosEffectBase
---@field soundCooldownTimer ChaosManualTimer
EffectZombiesExplodeOnDamage = ChaosEffectBase:derive("EffectZombiesExplodeOnDamage", "zombies_explode_on_damage")

local SOUND_COOLDOWN_MS = 2500

---@type EffectZombiesExplodeOnDamage | nil
local activeEffect = nil

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

    local playSound = true
    if activeEffect and activeEffect.soundCooldownTimer then
        playSound = activeEffect.soundCooldownTimer:isEnded()
        if playSound then
            activeEffect.soundCooldownTimer:reset()
        end
    end

    ChaosUtils.TriggerExplosionAt(square, 5, true, not playSound)
    print("[EffectZombiesExplodeOnDamage] Zombie exploded on damage")
end

function EffectZombiesExplodeOnDamage:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectZombiesExplodeOnDamage] OnStart" .. tostring(self.effectId))

    self.soundCooldownTimer = ChaosManualTimer.new(SOUND_COOLDOWN_MS)
    self.soundCooldownTimer:add(SOUND_COOLDOWN_MS) -- first explosion always plays the sound
    activeEffect = self

    Events.OnWeaponHitCharacter.Add(OnZombieDamaged)
end

---@param deltaMs integer
function EffectZombiesExplodeOnDamage:OnTick(deltaMs)
    if self.soundCooldownTimer then
        self.soundCooldownTimer:add(deltaMs)
    end
end

function EffectZombiesExplodeOnDamage:OnEnd()
    ChaosEffectBase:OnEnd()
    activeEffect = nil
    Events.OnWeaponHitCharacter.Remove(OnZombieDamaged)
end
