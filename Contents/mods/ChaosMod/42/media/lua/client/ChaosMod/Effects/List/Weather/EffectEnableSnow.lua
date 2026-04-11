---@class EffectEnableSnow : ChaosEffectBase
---@field previousPrecipitationIsSnow boolean
---@field forceSnowBeforeStart boolean
EffectEnableSnow = ChaosEffectBase:derive("EffectEnableSnow", "enable_snow")

local TEMP_WINTER_VALUE = -5.0

function EffectEnableSnow:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectEnableSnow] OnStart" .. tostring(self.effectId))

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_TEMPERATURE, true, TEMP_WINTER_VALUE)

    self.previousPrecipitationIsSnow = cm:getPrecipitationIsSnow()


    local isSnow = cm:getClimateBool(ClimateManager.BOOL_IS_SNOW)
    isSnow:setEnableModded(true)
    isSnow:setModdedValue(true)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)


    -- Snowstorn
    cm:triggerWinterIsComingStorm()
    -- Load snow on ground
    cm:postCellLoadSetSnow()

    self.forceSnowBeforeStart = getCore():isForceSnow() or false

    getCore():setForceSnow(true)
end

function EffectEnableSnow:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_TEMPERATURE, false, 0.0)
end

function EffectEnableSnow:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectEnableSnow] OnEnd" .. tostring(self.effectId))

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_TEMPERATURE, false, 0.0)

    local isSnow = cm:getClimateBool(ClimateManager.BOOL_IS_SNOW)
    if isSnow then
        isSnow:setEnableModded(false)
    end


    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)

    getCore():setForceSnow(self.forceSnowBeforeStart)
end
