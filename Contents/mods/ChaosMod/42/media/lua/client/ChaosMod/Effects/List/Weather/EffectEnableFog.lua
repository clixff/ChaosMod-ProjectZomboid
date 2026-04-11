EffectEnableFog = ChaosEffectBase:derive("EffectEnableFog", "enable_fog")

function EffectEnableFog:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectEnableFog] OnStart" .. tostring(self.effectId))

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_FOG_INTENSITY, true, 1.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 0.0)
end

function EffectEnableFog:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectEnableFog] OnEnd" .. tostring(self.effectId))

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_FOG_INTENSITY, false, 0.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)
end
