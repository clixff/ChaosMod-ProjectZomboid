---@class EffectSpawnStalker : ChaosEffectBase
EffectSpawnStalker = ChaosEffectBase:derive("EffectSpawnStalker", "spawn_stalker")

function EffectSpawnStalker:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = ChaosPlayer.GetRandomSquareAroundPlayer(
        player, 0, 15, 20, 20, true, false, false)
    if not square then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        square:getX(), square:getY(), square:getZ(), 1, "Classy", 0)
    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.STALKER
    npc:AddTag("stalker")
    self.npc = npc
end
