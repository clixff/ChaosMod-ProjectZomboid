EffectRefillCarFuel = ChaosEffectBase:derive("EffectRefillCarFuel", "refill_car_fuel")

function EffectRefillCarFuel:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRefillCarFuel] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    ChaosVehicle.setFuelPercent(vehicle, 1.0)

    local gasTankPart = vehicle:getPartById("GasTank")
    if gasTankPart then
        local maxValue = math.floor(gasTankPart:getContainerCapacity())
        local currentValue = math.floor(gasTankPart:getContainerContentAmount())
        ChaosPlayer.SayLineByColor(player, "New fuel: " .. currentValue .. "/" .. maxValue .. "L",
            ChaosPlayerChatColors.green)
    end
end
