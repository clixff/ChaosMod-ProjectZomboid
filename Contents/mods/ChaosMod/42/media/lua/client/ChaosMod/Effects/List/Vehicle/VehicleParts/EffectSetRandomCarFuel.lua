EffectSetRandomCarFuel = ChaosEffectBase:derive("EffectSetRandomCarFuel", "set_random_car_fuel")

function EffectSetRandomCarFuel:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetRandomCarFuel] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    local gasTankPart = vehicle:getPartById("GasTank")
    local prevValue = 0.0
    if gasTankPart then
        prevValue = gasTankPart:getContainerContentAmount()
    end

    ChaosVehicle.setRandomFuelPercent(vehicle, 0.0, 0.95)
    vehicle:updatePartStats()

    if gasTankPart then
        local maxValue = math.floor(gasTankPart:getContainerCapacity())
        local currentValue = gasTankPart:getContainerContentAmount()
        local color = currentValue >= prevValue and ChaosPlayerChatColors.green or ChaosPlayerChatColors.red
        ChaosPlayer.SayLineByColor(player, "New fuel: " .. math.floor(currentValue) .. "/" .. maxValue .. "L", color)
    end
end
