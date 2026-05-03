EffectSetRandomVehicleColors = ChaosEffectBase:derive("EffectSetRandomVehicleColors", "set_random_vehicle_colors")

function EffectSetRandomVehicleColors:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetRandomVehicleColors] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), 40)

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            local randomIndex = ChaosUtils.RandArrayIndex(VEHICLE_COLORS)
            local color = VEHICLE_COLORS[randomIndex]
            if color then
                vehicle:setColorHSV(color.hue, color.sat, color.val)
            end
        end
    end
end
