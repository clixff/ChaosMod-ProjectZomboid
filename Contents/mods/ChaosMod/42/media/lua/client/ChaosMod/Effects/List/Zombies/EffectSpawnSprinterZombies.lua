---@class EffectSpawnSprinterZombies : ChaosEffectBase
---@field spawnTimer integer
---@field spawnIntervalMs integer
EffectSpawnSprinterZombies = ChaosEffectBase:derive("EffectSpawnSprinterZombies", "spawn_sprinter_zombies")

local BASE_SPAWN_INTERVAL_MS = 8000
local MIN_SPAWNS_PER_DURATION = 4
local ZOMBIES_PER_SPAWN = 1

function EffectSpawnSprinterZombies:SpawnSprinters()
    local player = getPlayer()
    if not player then return end

    for i = 1, ZOMBIES_PER_SPAWN do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 8, 10, 50, true, true, false)
        if randomSquare then
            local x = randomSquare:getX()
            local y = randomSquare:getY()
            local z = randomSquare:getZ()
            local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
            local zombie = newZombies:getFirst()
            if zombie then
                zombie:doZombieSpeed(1)
                zombie:dressInRandomOutfit()
                zombie:pathToCharacter(player)
                zombie:setTarget(player)
            end
        end
    end
end

function EffectSpawnSprinterZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.spawnTimer = 0
    local durationMs = math.floor((self.duration or 0) * 1000)
    local spawnCount = math.max(MIN_SPAWNS_PER_DURATION, math.floor(durationMs / BASE_SPAWN_INTERVAL_MS))
    self.spawnIntervalMs = spawnCount > 0 and math.floor(durationMs / spawnCount) or BASE_SPAWN_INTERVAL_MS
    self:SpawnSprinters()
end

---@param deltaMs integer
function EffectSpawnSprinterZombies:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    self.spawnTimer = (self.spawnTimer or 0) + deltaMs
    if self.spawnTimer >= self.spawnIntervalMs then
        self.spawnTimer = self.spawnTimer - self.spawnIntervalMs
        self:SpawnSprinters()
    end
end
