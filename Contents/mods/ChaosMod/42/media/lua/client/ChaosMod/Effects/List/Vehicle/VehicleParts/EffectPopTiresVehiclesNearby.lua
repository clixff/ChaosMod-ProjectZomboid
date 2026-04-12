EffectPopTiresVehiclesNearby = ChaosEffectBase:derive("EffectPopTiresVehiclesNearby", "pop_tires_vehicles_nearby")

function EffectPopTiresVehiclesNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectPopTiresVehiclesNearby] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, 40)

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            local didPop = false
            for _, tireId in ipairs(VEHICLE_TIRES) do
                local part = vehicle:getPartById(tireId)
                if part then
                    local wheelId = part:getWheelIndex()
                    if wheelId >= 0 then
                        local roll = ZombRand(0, 2)
                        if roll == 0 then
                            part:setContainerContentAmount(0, true, true)
                            vehicle:setTireInflation(wheelId, 0)
                            vehicle:transmitPartModData(part)
                            didPop = true
                        end
                    end
                end
            end
            if didPop then
                local vehicleSquare = vehicle:getSquare()
                if vehicleSquare then
                    vehicleSquare:playSound("VehicleTireExplode")
                end
                vehicle:updatePartStats()
            end
        end
    end
end
