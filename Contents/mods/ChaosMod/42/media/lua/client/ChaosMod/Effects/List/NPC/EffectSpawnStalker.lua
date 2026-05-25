---@class EffectSpawnStalker : ChaosEffectBase
EffectSpawnStalker = ChaosEffectBase:derive("EffectSpawnStalker", "spawn_stalker")

local STALKER_ATTACK_DELAY_MS = 90000

local function StalkerAttackTick(_deltaMs, _data) end

---@param data { npc: ChaosNPC }
---@return boolean?
local function StalkerAttackEnd(data)
    local npc = data.npc
    if not npc or not npc.zombie or not npc.zombie:isAlive() then return true end
    if not npc:HasTag("stalker") then return true end

    npc:RemoveTag("stalker")
    npc.npcGroup = ChaosNPCGroupID.RAIDERS
    return true
end

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

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.STALKER
    npc:AddTag("stalker")
    self.npc = npc

    ChaosSpecialAction.AddNewAction(
        { npc = npc },
        STALKER_ATTACK_DELAY_MS,
        StalkerAttackTick,
        StalkerAttackEnd,
        nil,
        false
    )
end
