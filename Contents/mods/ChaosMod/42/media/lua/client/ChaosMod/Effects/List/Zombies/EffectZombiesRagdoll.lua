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
            local attacker = getFakeAttacker()
            local weapon = instanceItem("Base.Pistol")



            attacker:setVariable("ZombieHitReaction", "ShotChest")
            zombie:Hit(weapon, attacker, 0.0, true, 1.0, false)
            attacker:clearVariable("ZombieHitReaction")
        end
    end, false, nil)
end
