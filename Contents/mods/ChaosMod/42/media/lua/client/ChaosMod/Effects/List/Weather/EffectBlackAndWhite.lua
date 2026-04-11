EffectBlackAndWhite = ChaosEffectBase:derive("EffectBlackAndWhite", "black_and_white")

function EffectBlackAndWhite:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectBlackAndWhite] OnStart" .. tostring(self.effectId))
end

function EffectBlackAndWhite:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DESATURATION, true, 1.0)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DAYLIGHT_STRENGTH, true, 1.0)
end

function EffectBlackAndWhite:OnEnd()
    ChaosEffectBase:OnEnd()
    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DESATURATION, false, 0.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DAYLIGHT_STRENGTH, false, 0.0)
end
