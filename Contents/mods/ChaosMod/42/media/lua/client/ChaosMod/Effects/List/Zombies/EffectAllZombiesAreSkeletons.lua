EffectAllZombiesAreSkeletons = ChaosEffectBase:derive("EffectAllZombiesAreSkeletons", "all_zombies_are_skeletons")

function EffectAllZombiesAreSkeletons:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local radius = 80
    local updatedCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, radius, function(zombie)
        if zombie:isDead() then return end
        ChaosZombie.MakeZombieSkeleton(zombie)
        updatedCount = updatedCount + 1
    end, false, z)

    print("[EffectAllZombiesAreSkeletons] Updated " .. tostring(updatedCount) .. " zombies")
end
