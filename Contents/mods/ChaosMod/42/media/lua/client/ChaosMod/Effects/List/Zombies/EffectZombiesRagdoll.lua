EffectZombiesRagdoll = ChaosEffectBase:derive("EffectZombiesRagdoll", "zombies_ragdoll")

function EffectZombiesRagdoll:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()
    local z1 = square:getZ()

    local counter = 0

    ChaosZombie.ForEachZombieInRange(x1, y1, 40, function(zombie)
        if zombie and zombie:isAlive() then
            ChaosVehicle.ExitVehicle(zombie)
            zombie:clearVariable("BumpFallType")
            zombie:setBumpStaggered(true)
            zombie:setBumpType("stagger")
            zombie:setBumpFall(true)
            zombie:setBumpFallType("pushedBehind")
        end
    end, false, nil)
end
