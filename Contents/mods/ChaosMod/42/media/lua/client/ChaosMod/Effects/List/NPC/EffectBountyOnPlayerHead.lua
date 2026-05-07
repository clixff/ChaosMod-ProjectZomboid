---@class EffectBountyOnPlayerHead : ChaosEffectBase
---@field npcs ChaosNPC[]
---@field spawnElapsedMs integer
EffectBountyOnPlayerHead = ChaosEffectBase:derive("EffectBountyOnPlayerHead", "bounty_on_player_head")

local SPAWN_INTERVAL_MS = 30000

---@param effect EffectBountyOnPlayerHead
local function spawnAttacker(effect)
    local player = getPlayer()
    if not player then return end

    local spawnSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)
    if not spawnSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        spawnSquare:getX(),
        spawnSquare:getY(),
        spawnSquare:getZ(),
        1,
        "MannequinLeather",
        0
    )
    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.RAIDERS

    npc:SetWeapon("Base.BaseballBat")

    table.insert(effect.npcs, npc)
end

function EffectBountyOnPlayerHead:OnStart()
    ChaosEffectBase:OnStart()
    self.npcs = {}
    self.spawnElapsedMs = 0
    spawnAttacker(self)
end

---@param deltaMs integer
function EffectBountyOnPlayerHead:OnTick(deltaMs)
    self.spawnElapsedMs = self.spawnElapsedMs + deltaMs
    while self.spawnElapsedMs >= SPAWN_INTERVAL_MS do
        self.spawnElapsedMs = self.spawnElapsedMs - SPAWN_INTERVAL_MS
        spawnAttacker(self)
    end
end

function EffectBountyOnPlayerHead:OnEnd()
    ChaosEffectBase:OnEnd()
    if self.npcs then
        for i = 1, #self.npcs do
            local npc = self.npcs[i]
            if npc and npc.zombie then
                npc:Destroy()
            end
        end
    end

    self.npcs = nil
    self.spawnElapsedMs = 0
end
