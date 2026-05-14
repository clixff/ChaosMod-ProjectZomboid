---@class EffectSpawnSprinterZombies : ChaosEffectBase
EffectSpawnSprinterZombies = ChaosEffectBase:derive("EffectSpawnSprinterZombies", "spawn_sprinter_zombies")

function EffectSpawnSprinterZombies:SpawnSprinter()
    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 8, 10, 50, true, true, false)
    if not randomSquare then return end

    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()
    local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
    local zombie = newZombies and newZombies:getFirst() or nil
    if zombie then
        zombie:doZombieSpeed(1)
        zombie:dressInRandomOutfit()
        ChaosZombie.MoveToPlayerSpotted(zombie, player)
    end
end

function EffectSpawnSprinterZombies:OnStart()
    ChaosEffectBase:OnStart()
    self:SpawnSprinter()
end

function EffectSpawnSprinterZombies:OnEnd()
    ChaosEffectBase:OnEnd()
    self:SpawnSprinter()
end
