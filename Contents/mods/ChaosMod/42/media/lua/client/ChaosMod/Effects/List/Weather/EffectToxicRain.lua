---@class EffectToxicRain : ChaosEffectBase
---@field elapsedMs integer
---@field previousPrecipitationIsSnow boolean
---@field vehicleDamageBuffer number
EffectToxicRain = ChaosEffectBase:derive("EffectToxicRain", "toxic_rain")

local DAMAGE_DELAY_MS = 5000
local DAMAGE_PER_SECOND = 0.5
local VEHICLE_DAMAGE_RADIUS = 50
local VEHICLE_DAMAGE_PER_SECOND = 0.5

---@param square IsoGridSquare?
---@return boolean
local function IsSquareUnderOpenSky(square)
    if not square then return false end
    if square:isInARoom() then return false end
    if square:haveRoofFull() then return false end
    return true
end

function EffectToxicRain:OnStart()
    ChaosEffectBase:OnStart()
    self.elapsedMs = 0
    self.vehicleDamageBuffer = 0

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

    local playerSquare = player:getCurrentSquare()
    local deltaSeconds = deltaMs / 1000

    if not player:getVehicle() and IsSquareUnderOpenSky(playerSquare) then
        local bodyDamage = player:getBodyDamage()
        if bodyDamage then
            bodyDamage:ReduceGeneralHealth(deltaSeconds * DAMAGE_PER_SECOND)
        end
    end

    self.vehicleDamageBuffer = self.vehicleDamageBuffer + deltaSeconds * VEHICLE_DAMAGE_PER_SECOND
    local vehicleDamage = math.floor(self.vehicleDamageBuffer)
    if vehicleDamage > 0 and playerSquare then
        self.vehicleDamageBuffer = self.vehicleDamageBuffer - vehicleDamage
        local nearbyVehicles = ChaosVehicle.GetVehiclesNearby(playerSquare, VEHICLE_DAMAGE_RADIUS)
        if nearbyVehicles then
            for i = 0, nearbyVehicles:size() - 1 do
                local vehicle = nearbyVehicles:get(i)
                if vehicle and IsSquareUnderOpenSky(vehicle:getSquare()) then
                    for j = 0, vehicle:getPartCount() - 1 do
                        local part = vehicle:getPartByIndex(j)
                        if part then
                            part:damage(vehicleDamage)
                            vehicle:transmitPartCondition(part)
                        end
                    end
                    vehicle:updatePartStats()
                end
            end
        end
    end
end

function EffectToxicRain:OnEnd()
    ChaosEffectBase:OnEnd()

    local cm = ClimateManager.getInstance()
    if not cm then return end

    cm:setPrecipitationIsSnow(self.previousPrecipitationIsSnow or false)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)
end
