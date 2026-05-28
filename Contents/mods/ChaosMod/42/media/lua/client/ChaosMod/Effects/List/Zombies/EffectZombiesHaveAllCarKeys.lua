---@class EffectZombiesHaveAllCarKeys : ChaosEffectBase
EffectZombiesHaveAllCarKeys = ChaosEffectBase:derive("EffectZombiesHaveAllCarKeys", "zombies_have_all_car_keys")

local RADIUS = 70

function EffectZombiesHaveAllCarKeys:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehiclesList = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    if not vehiclesList or vehiclesList:size() == 0 then return end

    local vehicles = {}
    for i = 0, vehiclesList:size() - 1 do
        local vehicle = vehiclesList:get(i)
        if vehicle then
            table.insert(vehicles, vehicle)
        end
    end

    if #vehicles == 0 then return end

    local px = player:getX()
    local py = player:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        for _, vehicle in ipairs(vehicles) do
            local key = vehicle:createVehicleKey()
            if key then
                zombie:addItemToSpawnAtDeath(key)
            end
        end
    end)
end

function EffectZombiesHaveAllCarKeys:OnEnd()
    ChaosEffectBase:OnEnd()
end
