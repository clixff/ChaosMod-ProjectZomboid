EffectRemoveCarFuel = ChaosEffectBase:derive("EffectRemoveCarFuel", "remove_car_fuel")

function EffectRemoveCarFuel:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveCarFuel] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    ChaosVehicle.setFuelPercent(vehicle, 0.0)
    vehicle:updatePartStats()

    local gasTankPart = vehicle:getPartById("GasTank")
    if gasTankPart then
        local maxValue = math.floor(gasTankPart:getContainerCapacity())
        local currentValue = math.floor(gasTankPart:getContainerContentAmount())
        ChaosPlayer.SayLineByColor(player, "New fuel: " .. currentValue .. "/" .. maxValue .. "L",
            ChaosPlayerChatColors.red)
    end
end
