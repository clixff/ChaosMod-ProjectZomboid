EffectSpawnZombieNearby = ChaosEffectBase:derive("EffectSpawnZombieNearby", "spawn_zombie_nearby")

function EffectSpawnZombieNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnZombieNearby] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local x1 = math.floor(player:getX())
    local y1 = math.floor(player:getY())

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 5, 10, 50, true, true, false)
    if not randomSquare then return end
    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()
    local zombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
    if zombies and zombies:size() > 0 then
        local zombie = zombies:getFirst()
        if zombie then
            zombie:setTarget(player)
            zombie:setTurnAlertedValues(x1, y1)
        end
    end
end
