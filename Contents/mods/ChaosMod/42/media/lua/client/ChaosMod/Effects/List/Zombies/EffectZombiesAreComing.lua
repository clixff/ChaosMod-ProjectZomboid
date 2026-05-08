EffectZombiesAreComing = ChaosEffectBase:derive("EffectZombiesAreComing", "zombies_are_coming")

function EffectZombiesAreComing:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()
    local z1 = square:getZ()

    local counter = 0

    ChaosZombie.ForEachZombieInRange(x1, y1, 80, function(zombie)
        if zombie and zombie:isAlive() then
            ChaosZombie.MoveToLocation(zombie, x1, y1, z1, true, true, true, true)
            zombie:setTarget(player)
            counter = counter + 1
        end
    end, true, nil)

    print("[EffectZombiesAreComing] Zombies coming: " .. tostring(counter))
end
