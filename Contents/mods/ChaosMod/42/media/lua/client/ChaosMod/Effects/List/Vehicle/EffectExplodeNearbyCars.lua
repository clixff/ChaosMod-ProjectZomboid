EffectExplodeNearbyCars = ChaosEffectBase:derive("EffectExplodeNearbyCars", "explode_nearby_cars")

local VEHICLE_RADIUS = 30
local EXPLOSION_RADIUS = 5

function EffectExplodeNearbyCars:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectExplodeNearbyCars] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, VEHICLE_RADIUS)

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            ---@type VehiclePart
            local part = vehicle:getPartById("Engine")
            if part then
                part:damage(35)
                vehicle:transmitEngine()
            end

            vehicle:updatePartStats()

            local vehicleSquare = vehicle:getSquare()
            if vehicleSquare then
                ChaosUtils.TriggerExplosionAt(vehicleSquare, EXPLOSION_RADIUS)
            end
        end
    end
end
