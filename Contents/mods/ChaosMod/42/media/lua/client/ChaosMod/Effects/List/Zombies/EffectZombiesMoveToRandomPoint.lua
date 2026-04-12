---@class EffectZombiesMoveToRandomPoint : ChaosEffectBase
EffectZombiesMoveToRandomPoint = ChaosEffectBase:derive("EffectZombiesMoveToRandomPoint", "zombies_move_to_random_point")

function EffectZombiesMoveToRandomPoint:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    local counter = 0

    ChaosZombie.ForEachZombieInRange(px, py, 60, function(zombie)
        local sq = ChaosUtils.GetRandomSquareAroundPosition(zombie:getX(), zombie:getY(), 0, 20, 60)
        if sq then
            local tx = sq:getX()
            local ty = sq:getY()
            local tz = sq:getZ()
            zombie:getPathFindBehavior2():cancel()
            zombie:getPathFindBehavior2():reset()
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:setPath2(nil)
            zombie:setTurnAlertedValues(tx, ty)
            zombie:getPathFindBehavior2():pathToLocation(tx, ty, tz)
            counter = counter + 1
        end
    end, true, nil)

    print("[EffectZombiesMoveToRandomPoint] Zombies redirected: " .. tostring(counter))
end
