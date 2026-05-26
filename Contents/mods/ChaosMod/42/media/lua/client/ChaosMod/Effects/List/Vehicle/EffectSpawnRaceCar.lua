---@class EffectSpawnRaceCar : ChaosEffectBase
EffectSpawnRaceCar = ChaosEffectBase:derive("EffectSpawnRaceCar", "spawn_race_car")

local RACE_CAR_IDS = {
    "Base.RaceCar12",
    "Base.RaceCar58",
    "Base.RaceCar34",
}

function EffectSpawnRaceCar:OnStart()
    ChaosEffectBase:OnStart()
    local scriptName = RACE_CAR_IDS[ChaosUtils.RandArrayIndex(RACE_CAR_IDS)]
    if not scriptName then return end
    local vehicle = ChaosVehicle.spawnVehicleNearPlayer(scriptName, 10, 50, true, true)
    if vehicle then
        ChaosVehicle.SetRandomVehicleColors(vehicle)
    end
end

function EffectSpawnRaceCar:OnEnd()
    ChaosEffectBase:OnEnd()
end
