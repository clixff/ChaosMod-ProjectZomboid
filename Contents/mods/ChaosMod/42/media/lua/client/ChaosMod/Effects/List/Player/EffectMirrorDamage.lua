EffectMirrorDamage = ChaosEffectBase:derive("EffectMirrorDamage", "mirror_damage")

---@param attacker IsoGameCharacter
---@param weapon HandWeapon
---@param target IsoGameCharacter
---@param damage number
local function OnHitDamage(attacker, target, weapon, damage)
    if not target then return end
    if damage == nil or damage <= 0 then return end

    if not instanceof(target, "IsoZombie") then return end
    if not instanceof(attacker, "IsoPlayer") then return end


    attacker:setHitFromBehind(false)
    attacker:setVariable("hitpvp", false)
    attacker:setHitReaction("")
    attacker:setHitReaction("HitReaction")
    -- attacker:reportEvent("washitpvp")

    attacker:getBodyDamage():ReduceGeneralHealth(damage)
    ChaosPlayer.SetRandomBodyDamageByMeleeWeapon(attacker, damage, weapon)

    attacker:Say(string.format("Mirror damage: %.2f", damage))
end

function EffectMirrorDamage:OnStart()
    ChaosEffectBase:OnStart()

    Events.OnWeaponHitCharacter.Add(OnHitDamage)
end

function EffectMirrorDamage:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnWeaponHitCharacter.Remove(OnHitDamage)
end
