EffectTeleportToRandomVehicle = ChaosEffectBase:derive("EffectTeleportToRandomVehicle", "teleport_to_random_vehicle")

function EffectTeleportToRandomVehicle:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTeleportToRandomVehicle] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), 80)

    for i = 0, vehicles:size() - 1 do
        local randIndex = math.floor(ZombRand(vehicles:size()))
        local vehicle = vehicles:get(randIndex)

        if vehicle then
            local seat = ChaosVehicle.FindFreeSeat(vehicle, true)

            if seat > 0 then
                vehicle:enter(seat, player)
                return
            end
        end
    end

    player:Say("No vehicles nearby")
end
