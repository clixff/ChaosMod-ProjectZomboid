---@class EffectCantKnockdownZombies : ChaosEffectBase
---@field onHitZombie Callback_OnHitZombie
EffectCantKnockdownZombies = ChaosEffectBase:derive("EffectCantKnockdownZombies", "cant_knockdown_zombies")

---@param zombie IsoZombie
---@param wielder IsoGameCharacter
---@param _bodyPart BodyPartType
---@param _weapon HandWeapon
local function preventShoveKnockdown(zombie, wielder, _bodyPart, _weapon)
    if not zombie or not wielder then return end

    if not instanceof(wielder, "IsoPlayer") then return end
    if not instanceof(zombie, "IsoZombie") then return end

    ---@cast wielder IsoPlayer
    if wielder:isDoShove() and not wielder:isAimAtFloor() then
        wielder:setCriticalHit(false)
    end
end

function EffectCantKnockdownZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.onHitZombie = preventShoveKnockdown
    Events.OnHitZombie.Add(self.onHitZombie)
end

function EffectCantKnockdownZombies:OnEnd()
    ChaosEffectBase:OnEnd()
    if self.onHitZombie then
        Events.OnHitZombie.Remove(self.onHitZombie)
        self.onHitZombie = nil
    end
end
