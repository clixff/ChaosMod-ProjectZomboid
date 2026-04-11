EffectLaunchPlayerUp = ChaosEffectBase:derive("EffectLaunchPlayerUp", "launch_player_up")

function EffectLaunchPlayerUp:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)


    player:setZ(player:getZ() + 3)
end
