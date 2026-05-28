EffectExplodeNearbyCars = ChaosEffectBase:derive("EffectExplodeNearbyCars", "explode_nearby_cars")

local VEHICLE_RADIUS = 45
local EXPLOSION_RADIUS = 5

function EffectExplodeNearbyCars:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectExplodeNearbyCars] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, VEHICLE_RADIUS)

    local px, py = player:getX(), player:getY()
    local sortedVehicles = {}
    for i = 0, vehicles:size() - 1 do
        local v = vehicles:get(i)
        if v then
            sortedVehicles[#sortedVehicles + 1] = {
                vehicle = v,
                dist = ChaosUtils.distTo(px, py, v:getX(), v:getY())
            }
        end
    end
    table.sort(sortedVehicles, function(a, b) return a.dist < b.dist end)

    for i = 1, #sortedVehicles do
        ---@type BaseVehicle
        local vehicle = sortedVehicles[i].vehicle
        ---@type VehiclePart
        local part = vehicle:getPartById("Engine")
        if part then
            part:damage(35)
            vehicle:transmitEngine()
        end

        vehicle:updatePartStats()

        local vehicleSquare = vehicle:getSquare()
        if vehicleSquare then
            ChaosUtils.TriggerExplosionAt(vehicleSquare, EXPLOSION_RADIUS, true, i > 2)
        end
    end
end
