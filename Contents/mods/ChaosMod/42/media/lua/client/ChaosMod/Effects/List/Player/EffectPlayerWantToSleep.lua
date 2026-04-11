---@class EffectPlayerWantToSleep : ChaosEffectBase
EffectPlayerWantToSleep = ChaosEffectBase:derive("EffectPlayerWantToSleep", "player_want_to_sleep")

function EffectPlayerWantToSleep:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    stats:set(CharacterStat.FATIGUE, 0.8)
end

function EffectPlayerWantToSleep:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
end
