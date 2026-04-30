EffectAllZombiesAreCops = ChaosEffectBase:derive("EffectAllZombiesAreCops", "all_zombies_are_cops")

function EffectAllZombiesAreCops:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local radius = 60
    local updatedCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, radius, function(zombie)
        if zombie:isDead() then return end
        if zombie:isReanimatedPlayer() then return end
        zombie:dressInPersistentOutfit("Police")
        zombie:clearAttachedItems()
        updatedCount = updatedCount + 1
    end, true, z)

    print("[EffectAllZombiesAreCops] Updated " .. tostring(updatedCount) .. " zombies")
end
