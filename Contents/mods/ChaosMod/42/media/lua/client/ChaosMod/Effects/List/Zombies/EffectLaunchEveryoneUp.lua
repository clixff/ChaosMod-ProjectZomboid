EffectLaunchEveryoneUp = ChaosEffectBase:derive("EffectLaunchEveryoneUp", "launch_everyone_up")

function EffectLaunchEveryoneUp:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    player:setZ(player:getZ() + 1.25)
    player:addStiffness(BodyPartType.Foot_L, 100)

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()

    local zombies = getCell():getZombieList()
    if not zombies then return end

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie and zombie:isAlive() then
            local x2 = zombie:getX()
            local y2 = zombie:getY()

            if ChaosUtils.isInRange(x1, y1, x2, y2, 30) then
                ChaosVehicle.ExitVehicle(zombie)
                zombie:setZ(zombie:getZ() + 3)
            end
        end
    end
end
