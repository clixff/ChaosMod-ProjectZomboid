EffectExitCurrentVehicle = ChaosEffectBase:derive("EffectExitCurrentVehicle", "exit_current_vehicle")

function EffectExitCurrentVehicle:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectExitCurrentVehicle] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = player:getVehicle()
    if not vehicle then return end

    local speed = vehicle:getCurrentSpeedKmHour()

    ChaosVehicle.ExitVehicle(player)

    if speed > 1 then
        player:setKnockedDown(true)
    end
end
