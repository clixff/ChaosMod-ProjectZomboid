---@class EffectTemporaryNight : ChaosEffectBase
---@field previousTime number
EffectTemporaryNight = ChaosEffectBase:derive("EffectTemporaryNight", "temporary_night")

function EffectTemporaryNight:OnStart()
    ChaosEffectBase:OnStart()

    local gameTime = GameTime:getInstance()
    if not gameTime then return end

    self.previousTime = gameTime:getTimeOfDay()
    gameTime:setTimeOfDay(3.0)
end

function EffectTemporaryNight:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_NIGHT_STRENGTH, true, 0.0)
end

function EffectTemporaryNight:OnEnd()
    ChaosEffectBase:OnEnd()

    local gameTime = GameTime:getInstance()
    if gameTime and self.previousTime then
        gameTime:setTimeOfDay(self.previousTime)
    end

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_NIGHT_STRENGTH, false, 0.0)
end
