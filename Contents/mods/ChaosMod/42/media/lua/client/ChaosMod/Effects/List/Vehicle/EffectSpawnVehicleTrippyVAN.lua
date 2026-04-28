EffectSpawnVehicleTrippyVAN = ChaosEffectBase:derive("EffectSpawnVehicleTrippyVAN", "spawn_vehicle_trippy_van")

function EffectSpawnVehicleTrippyVAN:OnStart()
    ChaosEffectBase:OnStart()
    local vehicle = ChaosVehicle.spawnVehicleNearPlayer("Base.VanSeats_Trippy", 10, 50, true, true)
    if vehicle then
        ChaosVehicle.SetRandomVehicleColors(vehicle)
    end
end
