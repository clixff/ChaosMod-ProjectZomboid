---@class EffectPlayerCantSleep : ChaosEffectBase
EffectPlayerCantSleep = ChaosEffectBase:derive("EffectPlayerCantSleep", "player_cant_sleep")

function EffectPlayerCantSleep:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectPlayerCantSleep] OnStart")
end

---@param _deltaMs integer
function EffectPlayerCantSleep:OnTick(_deltaMs)
    local player = getPlayer()
    if not player then return end

    if not player:isAsleep() then return end

    ChaosUtils.ForceWakeUpPlayer(player)
end

function EffectPlayerCantSleep:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectPlayerCantSleep] OnEnd")
end
