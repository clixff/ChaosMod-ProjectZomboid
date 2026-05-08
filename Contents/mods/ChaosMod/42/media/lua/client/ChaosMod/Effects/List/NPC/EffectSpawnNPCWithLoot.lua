---@class EffectSpawnNPCWithLoot : ChaosEffectBase
---@field npc? ChaosNPC
---@field fleeSquare? IsoGridSquare
EffectSpawnNPCWithLoot = ChaosEffectBase:derive("EffectSpawnNPCWithLoot", "spawn_npc_with_loot")

---@param player IsoPlayer
---@param zombie IsoZombie
---@return IsoGridSquare?
local function getFleeSquare(player, zombie)
    if not player or not zombie then return nil end

    local dx = zombie:getX() - player:getX()
    local dy = zombie:getY() - player:getY()
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then
        dx = 1
        dy = 0
        len = 1
    end

    local radius = ChaosUtils.RandIntegerRange(12, 21)
    local targetX = math.floor(zombie:getX() + (dx / len) * radius)
    local targetY = math.floor(zombie:getY() + (dy / len) * radius)
    local targetZ = math.floor(zombie:getZ())

    local result = nil
    ChaosUtils.SquareRingSearchTile_2D(targetX, targetY, function(square)
        result = square
        return true
    end, 0, 4, true, false, false, targetZ, targetZ)

    return result
end

function EffectSpawnNPCWithLoot:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local spawnSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, 5, 10, 50, true, false, false)
    if not spawnSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        spawnSquare:getX(),
        spawnSquare:getY(),
        spawnSquare:getZ(),
        1,
        "Classy",
        0
    )
    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.ROBBER
    npc:AddTag("effect_move_to_square")
    self.npc = npc

    for _ = 1, 3 do
        local itemId = GetRandomLootboxItem()
        if itemId then
            local item = instanceItem(itemId)
            if item then
                zombie:addItemToSpawnAtDeath(item)
            end
        end
    end

    self.fleeSquare = getFleeSquare(player, zombie)
    npc.effectMoveTargetLocation = self.fleeSquare
    if self.fleeSquare then
        npc:MoveToLocation(self.fleeSquare)
    end
end

---@param _deltaMs integer
function EffectSpawnNPCWithLoot:OnTick(_deltaMs)
    if not self.npc or not self.npc.zombie then return end

    local player = getPlayer()
    if not player then return end

    local zombie = self.npc.zombie
    local zombieSquare = zombie:getSquare()
    if not zombieSquare then return end

    if not self.fleeSquare then
        self.fleeSquare = getFleeSquare(player, zombie)
        self.npc.effectMoveTargetLocation = self.fleeSquare
        if not self.fleeSquare then return end
    end

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), player:getX(), player:getY())
    local reachedSquare = zombieSquare:getX() == self.fleeSquare:getX() and
        zombieSquare:getY() == self.fleeSquare:getY() and
        zombieSquare:getZ() == self.fleeSquare:getZ()

    if reachedSquare or dist < 4.0 then
        self.fleeSquare = getFleeSquare(player, zombie)
        self.npc.effectMoveTargetLocation = self.fleeSquare
        if self.fleeSquare then
            self.npc:StopMoving(true, "npc_with_loot_new_flee_square")
            self.npc:MoveToLocation(self.fleeSquare)
        end
    end
end

function EffectSpawnNPCWithLoot:OnEnd()
    ChaosEffectBase:OnEnd()
    if self.npc and self.npc.zombie then
        self.npc:Destroy()
    end
    self.npc = nil
    self.fleeSquare = nil
end
