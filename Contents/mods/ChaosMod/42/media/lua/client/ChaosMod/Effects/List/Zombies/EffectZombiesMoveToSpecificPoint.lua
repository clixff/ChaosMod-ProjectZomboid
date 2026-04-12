---@class EffectZombiesMoveToSpecificPoint : ChaosEffectBase
EffectZombiesMoveToSpecificPoint = ChaosEffectBase:derive("EffectZombiesMoveToSpecificPoint",
    "zombies_move_to_specific_point")

function EffectZombiesMoveToSpecificPoint:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, 20, 60, 50, false, true, false)
    if not sq then return end

    local tx = sq:getX()
    local ty = sq:getY()
    local tz = sq:getZ()

    local px = square:getX()
    local py = square:getY()

    local counter = 0

    ChaosZombie.ForEachZombieInRange(px, py, 60, function(zombie)
        zombie:getPathFindBehavior2():cancel()
        zombie:getPathFindBehavior2():reset()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setPath2(nil)
        zombie:setTurnAlertedValues(tx, ty)
        zombie:getPathFindBehavior2():pathToLocation(tx, ty, tz)
        counter = counter + 1
    end, true, nil)

    print("[EffectZombiesMoveToSpecificPoint] Zombies redirected: " .. tostring(counter))
end
