---@class EffectSpawnZombiesNearby : ChaosEffectBase
---@field spawnTimer integer
---@field spawnIntervalMs integer
EffectSpawnZombiesNearby = ChaosEffectBase:derive("EffectSpawnZombiesNearby", "spawn_zombies_nearby")

local BASE_SPAWN_INTERVAL_MS = 8000
local MIN_SPAWNS_PER_DURATION = 5
local ZOMBIES_PER_SPAWN = 1

function EffectSpawnZombiesNearby:SpawnZombies()
    local player = getPlayer()
    if not player then return end

    local x1 = math.floor(player:getX())
    local y1 = math.floor(player:getY())

    for i = 1, ZOMBIES_PER_SPAWN do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 5, 10, 50, true, true, false)
        if randomSquare then
            local x = randomSquare:getX()
            local y = randomSquare:getY()
            local z = randomSquare:getZ()
            local zombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
            local zombie = zombies and zombies:getFirst() or nil
            if zombie then
                zombie:dressInRandomOutfit()
                ChaosZombie.MoveToPlayerSpotted(zombie, player)
            end
        end
    end
end

function EffectSpawnZombiesNearby:OnStart()
    ChaosEffectBase:OnStart()
    self.spawnTimer = 0
    local durationMs = math.floor((self.duration or 0) * 1000)
    local spawnCount = math.max(MIN_SPAWNS_PER_DURATION, math.floor(durationMs / BASE_SPAWN_INTERVAL_MS))
    self.spawnIntervalMs = spawnCount > 0 and math.floor(durationMs / spawnCount) or BASE_SPAWN_INTERVAL_MS
    self:SpawnZombies()
end

---@param deltaMs integer
function EffectSpawnZombiesNearby:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    self.spawnTimer = (self.spawnTimer or 0) + deltaMs
    if self.spawnTimer >= self.spawnIntervalMs then
        self.spawnTimer = self.spawnTimer - self.spawnIntervalMs
        self:SpawnZombies()
    end
end
