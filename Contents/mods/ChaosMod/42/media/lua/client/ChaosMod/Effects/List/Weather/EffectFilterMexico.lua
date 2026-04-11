EffectFilterMexico = ChaosEffectBase:derive("EffectFilterMexico", "filter_mexico")

function EffectFilterMexico:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectFilterMexico] OnStart" .. tostring(self.effectId))
end

function EffectFilterMexico:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if not cm then return end

    local globalLight = cm:getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT)
    if not globalLight then return end

    globalLight:setEnableOverride(true)
    local colorInfo = ClimateColorInfo.new()
    colorInfo:setExterior(0, 0.36, 1.0, 1.0)
    colorInfo:setInterior(0, 0.36, 1.0, 1.0)
    globalLight:setOverride(colorInfo, 1.0)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_AMBIENT, true, 1.0)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DAYLIGHT_STRENGTH, true, 0.0)
end

function EffectFilterMexico:OnEnd()
    ChaosEffectBase:OnEnd()
    local cm = ClimateManager.getInstance()
    if not cm then return end

    local globalLight = cm:getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT)
    if not globalLight then return end

    globalLight:setEnableOverride(false)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_AMBIENT, false, 0.0)
end
