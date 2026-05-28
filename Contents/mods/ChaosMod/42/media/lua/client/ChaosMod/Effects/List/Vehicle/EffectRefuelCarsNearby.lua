---@class EffectRefuelCarsNearby : ChaosEffectBase
EffectRefuelCarsNearby = ChaosEffectBase:derive("EffectRefuelCarsNearby", "refuel_cars_nearby")

local RADIUS = 60

function EffectRefuelCarsNearby:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    if not vehicles then return end

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            ChaosVehicle.setFuelPercent(vehicle, 1.0)
        end
    end
end

function EffectRefuelCarsNearby:OnEnd()
    ChaosEffectBase:OnEnd()
end
