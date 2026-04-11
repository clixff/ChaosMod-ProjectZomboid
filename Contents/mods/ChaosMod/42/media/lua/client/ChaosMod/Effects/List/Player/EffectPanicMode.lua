---@class EffectPanicMode : ChaosEffectBase
EffectPanicMode = ChaosEffectBase:derive("EffectPanicMode", "panic_mode")

function EffectPanicMode:OnStart()
    ChaosEffectBase:OnStart()
end

---@param _deltaMs integer
function EffectPanicMode:OnTick(_deltaMs)
    local player = getPlayer()
    if not player then return end


    local stats = player:getStats()
    stats:set(CharacterStat.PANIC, 100.0)
    stats:set(CharacterStat.STRESS, 1.0)
    stats:set(CharacterStat.DISCOMFORT, 100.0)
end

function EffectPanicMode:OnEnd()
    ChaosEffectBase:OnEnd()
end
