---@class EffectSpawnSportsCar : ChaosEffectBase
EffectSpawnSportsCar = ChaosEffectBase:derive("EffectSpawnSportsCar", "spawn_sports_car")

function EffectSpawnSportsCar:OnStart()
    ChaosEffectBase:OnStart()
    local vehicle = ChaosVehicle.spawnVehicleNearPlayer("Base.SportsCar", 10, 50, true, true)
    if vehicle then
        ChaosVehicle.SetRandomVehicleColors(vehicle)
    end
end

function EffectSpawnSportsCar:OnEnd()
    ChaosEffectBase:OnEnd()
end
