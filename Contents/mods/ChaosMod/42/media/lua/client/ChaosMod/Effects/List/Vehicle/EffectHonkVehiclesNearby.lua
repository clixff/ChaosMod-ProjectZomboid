---@class EffectHonkVehiclesNearby : ChaosEffectBase
---@field vehicles table<integer, BaseVehicle>
---@field isActivated boolean
---@field currentTimeMs integer
EffectHonkVehiclesNearby = ChaosEffectBase:derive("EffectHonkVehiclesNearby", "honk_vehicles_nearby")

local MAX_TIME_MS = 3500

function EffectHonkVehiclesNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectHonkVehiclesNearby] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end


    self.vehicles = {}
    self.isActivated = true
    self.currentTimeMs = 0
    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), 70)
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            table.insert(self.vehicles, vehicle)
            vehicle:onHornStart()
        end
    end
end

function EffectHonkVehiclesNearby:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    if self.isActivated == false then return end

    local player = getPlayer()
    if not player then return end

    self.currentTimeMs = self.currentTimeMs + deltaMs
    if self.currentTimeMs >= MAX_TIME_MS then
        self.isActivated = false

        for i = 0, #self.vehicles do
            local vehicle = self.vehicles[i]
            if vehicle then
                vehicle:onHornStop()
            end
        end
    end
end

function EffectHonkVehiclesNearby:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectHonkVehiclesNearby] OnEnd" .. tostring(self.effectId))

    self.vehicles = {}
end
