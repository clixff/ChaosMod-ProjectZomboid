---@class EffectUnlockNearbyCars : ChaosEffectBase
EffectUnlockNearbyCars = ChaosEffectBase:derive("EffectUnlockNearbyCars", "unlock_nearby_cars")

local RADIUS = 80

function EffectUnlockNearbyCars:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    if not vehicles then return end

    local unlockedCount = 0

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            local didUnlock = false
            for _, doorName in ipairs(VEHICLE_DOORS) do
                if doorName ~= "EngineDoor" then
                    local part = vehicle:getPartById(doorName)
                    if part and part:getDoor() then
                        part:getDoor():setLocked(false)
                        vehicle:transmitPartDoor(part)
                        didUnlock = true
                    end
                end
            end
            if didUnlock then
                unlockedCount = unlockedCount + 1
            end
        end
    end

    if unlockedCount > 0 then
        ChaosPlayer.SayLineByColor(player, string.format("Unlocked %d cars", unlockedCount),
            ChaosPlayerChatColors.green)
    end
end

function EffectUnlockNearbyCars:OnEnd()
    ChaosEffectBase:OnEnd()
end
