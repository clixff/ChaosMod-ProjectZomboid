EffectLaunchPlayerUp = ChaosEffectBase:derive("EffectLaunchPlayerUp", "launch_player_up")

local function triggerFall(player)
    ChaosVehicle.ExitVehicle(player)
    player:clearVariable("BumpFallType")
    player:setBumpStaggered(true)
    player:setBumpType("stagger")
    player:setBumpFall(true)
    player:setBumpFallType("pushedBehind")
end


function EffectLaunchPlayerUp:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)


    triggerFall(player)
    player:setZ(player:getZ() + 1.25)
end
