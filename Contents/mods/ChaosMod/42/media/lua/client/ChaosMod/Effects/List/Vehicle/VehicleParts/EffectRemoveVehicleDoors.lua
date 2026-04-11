EffectRemoveVehicleDoors = ChaosEffectBase:derive("EffectRemoveVehicleDoors", "remove_vehicle_doors")

function EffectRemoveVehicleDoors:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveVehicleDoors] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    local partCount = vehicle:getPartCount()

    ---@type table<string, boolean>
    local allowedPartIds = {
        ["DoorFrontLeft"] = true,
        ["DoorFrontRight"] = true,
        ["DoorMiddleLeft"] = true,
        ["DoorMiddleRight"] = true,
        ["DoorRearLeft"] = true,
        ["DoorRearRight"] = true,

        ["WindowFrontLeft"] = true,
        ["WindowFrontRight"] = true,
        ["WindowMiddleLeft"] = true,
        ["WindowMiddleRight"] = true,
        ["WindowRearLeft"] = true,
        ["WindowRearRight"] = true,
    }

    -- backward loop
    for i = partCount - 1, 0, -1 do
        local part = vehicle:getPartByIndex(i)
        if part and (part:getDoor() or part:getWindow()) then
            local partId = part:getId()
            if allowedPartIds[partId] then
                ---@diagnostic disable-next-line: param-type-mismatch
                part:setInventoryItem(nil, 10)
                vehicle:transmitPartItem(part)
            end
        end
    end
    vehicle:updatePartStats()
end
