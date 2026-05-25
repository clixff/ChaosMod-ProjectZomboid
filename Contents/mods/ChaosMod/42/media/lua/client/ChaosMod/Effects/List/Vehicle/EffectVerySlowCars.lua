---@class EffectVerySlowCars : ChaosEffectBase
---@field originalStats table<BaseVehicle, { maxSpeed: number, quality: integer, loudness: integer, power: integer }>
EffectVerySlowCars = ChaosEffectBase:derive("EffectVerySlowCars", "very_slow_cars")

function EffectVerySlowCars:OnStart()
    ChaosEffectBase:OnStart()

    self.originalStats = {}
end

---@param deltaMs integer
function EffectVerySlowCars:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local vehicle = player:getVehicle()
    if not vehicle then return end

    if not self.originalStats[vehicle] then
        self.originalStats[vehicle] = {
            maxSpeed = vehicle:getMaxSpeed(),
            quality = vehicle:getEngineQuality(),
            loudness = vehicle:getEngineLoudness(),
            power = vehicle:getEnginePower(),
        }
    end

    vehicle:setMaxSpeed(20)
    vehicle:setEngineFeature(vehicle:getEngineQuality(), vehicle:getEngineLoudness(), 500)
    vehicle:updateBulletStats()
end

function EffectVerySlowCars:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.originalStats then
        for vehicle, data in pairs(self.originalStats) do
            if vehicle then
                vehicle:setMaxSpeed(data.maxSpeed)
                vehicle:setEngineFeature(data.quality, data.loudness, data.power)
                vehicle:updateBulletStats()
            end
        end
        self.originalStats = {}
    end
end
