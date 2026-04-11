---@class EffectExplodeOnSleep : ChaosEffectBase
EffectExplodeOnSleep = ChaosEffectBase:derive("EffectExplodeOnSleep", "explode_on_sleep")

function EffectExplodeOnSleep:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectExplodeOnSleep] OnStart")
end

---@param _deltaMs integer
function EffectExplodeOnSleep:OnTick(_deltaMs)
    local player = getPlayer()
    if not player then return end

    if not player:isAsleep() then return end

    ChaosUtils.ForceWakeUpPlayer(player)

    local square = player:getSquare()
    if not square then return end

    ChaosUtils.TriggerExplosionAt(square, 3)
    player:setKnockedDown(true)
end

function EffectExplodeOnSleep:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectExplodeOnSleep] OnEnd")
end
