---@class EffectKnockbackHits : ChaosEffectBase
EffectKnockbackHits = ChaosEffectBase:derive("EffectKnockbackHits", "knockback_hits")

local KNOCKBACK_IMPULSE = 70.0

---@param attacker IsoGameCharacter
---@return boolean
local function IsAllowedAttacker(attacker)
    if not attacker then return false end
    if instanceof(attacker, "IsoPlayer") then return true end
    if instanceof(attacker, "IsoZombie") then
        ---@cast attacker IsoZombie
        return ChaosNPCUtils.IsNPC(attacker)
    end
    return false
end

---@param attacker IsoGameCharacter
---@param target IsoGameCharacter
---@param weapon HandWeapon
---@param damage number
local function OnHit(attacker, target, weapon, damage)
    if not attacker or not target then return end
    if not instanceof(target, "IsoZombie") then return end
    if not IsAllowedAttacker(attacker) then return end

    ---@cast target IsoZombie
    if target:isDead() then return end

    ChaosPhysics.KnockbackCharacter(target, attacker:getX(), attacker:getY(), KNOCKBACK_IMPULSE,
        attacker:isHitFromBehind())
end

function EffectKnockbackHits:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnWeaponHitCharacter.Add(OnHit)
end

---@param deltaMs integer
function EffectKnockbackHits:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectKnockbackHits:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnWeaponHitCharacter.Remove(OnHit)
end
