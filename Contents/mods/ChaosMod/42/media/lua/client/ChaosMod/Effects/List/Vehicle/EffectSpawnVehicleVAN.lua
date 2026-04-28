EffectSpawnVehicleVAN = ChaosEffectBase:derive("EffectSpawnVehicleVAN", "spawn_vehicle_van")

function EffectSpawnVehicleVAN:OnStart()
    ChaosEffectBase:OnStart()
    local vehicle = ChaosVehicle.spawnVehicleNearPlayer("Base.Van", 10, 50, true, true)
    if vehicle then
        ChaosVehicle.SetRandomVehicleColors(vehicle)
    end
end
