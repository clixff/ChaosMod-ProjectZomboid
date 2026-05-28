---@class EffectNeedForSpeed : ChaosEffectBase
---@field originalStats table<BaseVehicle, { maxSpeed: number, mass: number, quality: integer, loudness: integer, power: integer }>
EffectNeedForSpeed = ChaosEffectBase:derive("EffectNeedForSpeed", "need_for_speed")

function EffectNeedForSpeed:OnStart()
    ChaosEffectBase:OnStart()

    self.originalStats = {}
end

---@param deltaMs integer
function EffectNeedForSpeed:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local vehicle = player:getVehicle()
    if not vehicle then return end

    if not self.originalStats[vehicle] then
        self.originalStats[vehicle] = {
            maxSpeed = vehicle:getMaxSpeed(),
            mass = vehicle:getMass(),
            quality = vehicle:getEngineQuality(),
            loudness = vehicle:getEngineLoudness(),
            power = vehicle:getEnginePower(),
        }
    end

    vehicle:setMaxSpeed(500)
    vehicle:setEngineFeature(vehicle:getEngineQuality(), vehicle:getEngineLoudness(), 12000 * 1.5)
    vehicle:setMass(600)
    vehicle:updateBulletStats()
end

function EffectNeedForSpeed:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.originalStats then
        for vehicle, data in pairs(self.originalStats) do
            if vehicle then
                vehicle:setMaxSpeed(data.maxSpeed)
                vehicle:setEngineFeature(data.quality, data.loudness, data.power)
                vehicle:setMass(data.mass)
                vehicle:updateBulletStats()
            end
        end
        self.originalStats = {}
    end
end
