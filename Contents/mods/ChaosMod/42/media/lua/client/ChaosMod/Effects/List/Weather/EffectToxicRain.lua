---@class EffectToxicRain : ChaosEffectBase
---@field elapsedMs integer
---@field previousPrecipitationIsSnow boolean
EffectToxicRain = ChaosEffectBase:derive("EffectToxicRain", "toxic_rain")

local DAMAGE_DELAY_MS = 5000
local DAMAGE_PER_SECOND = 0.5

function EffectToxicRain:OnStart()
    ChaosEffectBase:OnStart()
    self.elapsedMs = 0

    local cm = ClimateManager.getInstance()
    if not cm then return end

    self.previousPrecipitationIsSnow = cm:getPrecipitationIsSnow()
    cm:setPrecipitationIsSnow(false)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
end

---@param deltaMs integer
function EffectToxicRain:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if not cm then return end

    cm:setPrecipitationIsSnow(false)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)

    local player = getPlayer()
    if not player then return end

    self.elapsedMs = self.elapsedMs + deltaMs
    if self.elapsedMs < DAMAGE_DELAY_MS then return end

    local sq = player:getCurrentSquare()
    local inRoom = sq and sq:isInARoom() or false
    local underRoof = sq and sq:haveRoofFull() or false
    local openSky = sq and not inRoom and not underRoof or false
    if not openSky then return end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end

    bodyDamage:ReduceGeneralHealth((deltaMs / 1000) * DAMAGE_PER_SECOND)
end

function EffectToxicRain:OnEnd()
    ChaosEffectBase:OnEnd()

    local cm = ClimateManager.getInstance()
    if not cm then return end

    cm:setPrecipitationIsSnow(self.previousPrecipitationIsSnow or false)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)
end
