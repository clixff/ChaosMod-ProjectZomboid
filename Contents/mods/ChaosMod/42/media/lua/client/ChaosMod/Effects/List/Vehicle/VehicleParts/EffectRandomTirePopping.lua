EffectRandomTirePopping = ChaosEffectBase:derive("EffectRandomTirePopping", "random_tire_popping")

function EffectRandomTirePopping:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRandomTirePopping] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    ---@type integer
    local maxWheels = #VEHICLE_TIRES + 1

    local randomWheel = math.floor(ZombRand(1, maxWheels + 1))
    local part = vehicle:getPartById(VEHICLE_TIRES[randomWheel])

    if part then
        local wheelId = part:getWheelIndex()
        if wheelId >= 0 then
            print("[EffectRandomTirePopping] Setting tire inflation to 0 for wheel id: " .. tostring(wheelId))
            part:setContainerContentAmount(0, true, true)
            vehicle:setTireInflation(wheelId, 0)
            vehicle:transmitPartModData(part)

            local square = vehicle:getSquare()
            if square then
                square:playSound("VehicleTireExplode")
            end
        end
    end
    vehicle:updatePartStats()
end
