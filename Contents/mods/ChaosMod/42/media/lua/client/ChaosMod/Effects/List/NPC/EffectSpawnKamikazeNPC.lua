---@class EffectSpawnKamikazeNPC : ChaosEffectBase
---@field npc? ChaosNPC
---@field zombie? IsoZombie
---@field exploded boolean
EffectSpawnKamikazeNPC = ChaosEffectBase:derive("EffectSpawnKamikazeNPC", "spawn_kamikaze_npc")

local TRIGGER_RADIUS = 2
local EXPLOSION_RADIUS = 5

function EffectSpawnKamikazeNPC:OnStart()
    ChaosEffectBase:OnStart()
    self.exploded = false

    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Tourist",
        0
    )

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.RAIDERS

    self.npc = npc
    self.zombie = zombie
end

function EffectSpawnKamikazeNPC:Explode()
    if self.exploded then return end
    if not self.zombie then return end

    local square = self.zombie:getSquare()
    if not square then return end

    self.exploded = true
    ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)

    if self.npc and self.npc.zombie then
        self.npc:Destroy()
    end
end

---@param _deltaMs integer
function EffectSpawnKamikazeNPC:OnTick(_deltaMs)
    if self.exploded then return end

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end
    if not self.zombie then return end

    local zombieSquare = self.zombie:getSquare()
    if not zombieSquare then return end
    if math.abs(zombieSquare:getZ() - playerSquare:getZ()) > 0.5 then return end

    local dist = ChaosUtils.distTo(playerSquare:getX(), playerSquare:getY(), zombieSquare:getX(), zombieSquare:getY())
    if dist < TRIGGER_RADIUS then
        self:Explode()
    end
end

function EffectSpawnKamikazeNPC:OnEnd()
    ChaosEffectBase:OnEnd()
    if not self.exploded then
        self:Explode()
    end

    if self.npc and self.npc.zombie then
        self.npc:Destroy()
    end

    self.npc = nil
    self.zombie = nil
end
