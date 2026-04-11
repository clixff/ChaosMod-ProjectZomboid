EffectSetRandomCarFuel = ChaosEffectBase:derive("EffectSetRandomCarFuel", "set_random_car_fuel")

function EffectSetRandomCarFuel:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetRandomCarFuel] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    ChaosVehicle.setRandomFuelPercent(vehicle, 0.0, 0.95)
    vehicle:updatePartStats()
end
