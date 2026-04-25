---@class EffectEnableRain : ChaosEffectBase
---@field previousPrecipitationIsSnow boolean
EffectEnableRain = ChaosEffectBase:derive("EffectEnableRain", "enable_rain")

function EffectEnableRain:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectEnableRain] OnStart" .. tostring(self.effectId))

    local cm = ClimateManager.getInstance()
    if not cm then return end

    self.previousPrecipitationIsSnow = cm:getPrecipitationIsSnow()

    cm:setPrecipitationIsSnow(false)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
end

function EffectEnableRain:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
end

function EffectEnableRain:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectEnableRain] OnEnd" .. tostring(self.effectId))

    local cm = ClimateManager.getInstance()
    if not cm then return end

    cm:setPrecipitationIsSnow(self.previousPrecipitationIsSnow or false)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)
end
