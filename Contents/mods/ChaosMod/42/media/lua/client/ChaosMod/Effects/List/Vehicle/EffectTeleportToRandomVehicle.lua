EffectTeleportToRandomVehicle = ChaosEffectBase:derive("EffectTeleportToRandomVehicle", "teleport_to_random_vehicle")

function EffectTeleportToRandomVehicle:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTeleportToRandomVehicle] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local playerCar = player:getVehicle()

    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), 90)

    ---@type table<integer, BaseVehicle>
    local candidates = {}

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle and vehicle ~= playerCar then
            local seat = ChaosVehicle.FindFreeSeat(vehicle, true)
            if seat > 0 then
                table.insert(candidates, vehicle)
            end
        end
    end

    if #candidates == 0 then
        player:Say(ChaosLocalization.GetString("misc", "no_vehicles_nearby"))
        return
    end

    local randIndex = ChaosUtils.RandArrayIndex(candidates)
    local vehicle = candidates[randIndex]

    if vehicle then
        local seat = ChaosVehicle.FindFreeSeat(vehicle, true)

        if seat > 0 then
            vehicle:enter(seat, player)
            return
        end
    end

    player:Say(ChaosLocalization.GetString("misc", "no_vehicles_nearby"))
end
