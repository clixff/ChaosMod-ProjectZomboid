---@class EffectZombiesRain : ChaosEffectBase
---@field spawnTimerMs integer
EffectZombiesRain = ChaosEffectBase:derive("EffectZombiesRain", "zombies_rain")

local SPAWN_INTERVAL_MS = 2000
local MIN_SPAWN_RADIUS = 6
local MAX_SPAWN_RADIUS = 25

---@param player IsoPlayer
function EffectZombiesRain:SpawnZombieAroundPlayer(player)
    local angle = ChaosUtils.RandFloat(0, math.pi * 2)
    local radius = ChaosUtils.RandFloat(MIN_SPAWN_RADIUS, MAX_SPAWN_RADIUS)
    local x = player:getX() + math.cos(angle) * radius
    local y = player:getY() + math.sin(angle) * radius
    local z = player:getZ()
    local zombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist", 50)

    if zombies and zombies:size() > 0 then
        local zombie = zombies:getFirst()
        if zombie then
            zombie:setZ(zombie:getZ() + 3)
            zombie:setTarget(player)
            zombie:setTurnAlertedValues(math.floor(player:getX()), math.floor(player:getY()))
        end
    end
end

function EffectZombiesRain:OnStart()
    ChaosEffectBase:OnStart()
    self.spawnTimerMs = 0
end

---@param deltaMs integer
function EffectZombiesRain:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    self.spawnTimerMs = self.spawnTimerMs + deltaMs
    while self.spawnTimerMs >= SPAWN_INTERVAL_MS do
        self.spawnTimerMs = self.spawnTimerMs - SPAWN_INTERVAL_MS
        self:SpawnZombieAroundPlayer(player)
    end
end

function EffectZombiesRain:OnEnd()
    ChaosEffectBase:OnEnd()
end
