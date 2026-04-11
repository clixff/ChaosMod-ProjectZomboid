EffectSpawnVehicleNearby = ChaosEffectBase:derive("EffectSpawnVehicleNearby", "spawn_vehicle_nearby")

function EffectSpawnVehicleNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnVehicleNearby] OnStart" .. tostring(self.effectId))

    local vehicle = ChaosVehicle.spawnVehicleNearPlayer(ChaosVehicle.GetRandomVehicleName(), 10, 50, true, true)
    if vehicle then
        print("[EffectSpawnVehicleNearby] Vehicle spawned: " .. tostring(vehicle))

        ChaosVehicle.SetRandomVehicleColors(vehicle)
    end
end
