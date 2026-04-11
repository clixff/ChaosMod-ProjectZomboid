---@class EffectStopRain : ChaosEffectBase
EffectStopRain = ChaosEffectBase:derive("EffectStopRain", "stop_rain")

function EffectStopRain:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectStopRain] OnStart" .. tostring(self.effectId))

    local cm = ClimateManager.getInstance()
    if not cm then return end

    cm:stopWeatherAndThunder()
end
