---@class EffectCrouchMode : ChaosEffectBase
EffectCrouchMode = ChaosEffectBase:derive("EffectCrouchMode", "crouch_mode")

---@param player IsoPlayer
local function forceSneak(player)
    if player and not player:isDead() then
        player:setSneaking(true)
    end
end

function EffectCrouchMode:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnPlayerUpdate.Add(forceSneak)
end

function EffectCrouchMode:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnPlayerUpdate.Remove(forceSneak)
end
