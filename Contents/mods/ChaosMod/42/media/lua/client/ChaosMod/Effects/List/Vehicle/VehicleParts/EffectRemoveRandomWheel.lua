EffectRemoveRandomWheel = ChaosEffectBase:derive("EffectRemoveRandomWheel", "remove_random_wheel")

function EffectRemoveRandomWheel:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveRandomWheel] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    ---@type integer
    local maxWheels = #VEHICLE_TIRES + 1

    for i = 1, maxWheels do
        ---@type string
        local wheelName = VEHICLE_TIRES[i]
        local part = vehicle:getPartById(wheelName)
        if part then
            if part:getInventoryItem() then
                local wheelId = part:getWheelIndex()
                if wheelId then
                    vehicle:setTireRemoved(wheelId, true)
                end
                ---@diagnostic disable-next-line: param-type-mismatch
                part:setInventoryItem(nil, 10)
                vehicle:transmitPartItem(part)
                vehicle:updatePartStats()

                return
            end
        end
    end
end
