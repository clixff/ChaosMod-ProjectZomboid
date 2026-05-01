---@class EffectNPCDuel : ChaosEffectBase
EffectNPCDuel = ChaosEffectBase:derive("EffectNPCDuel", "npc_duel")

local NPC_COUNT = 2

function EffectNPCDuel:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ---@type ChaosNPC[]
    local spawnedNpcs = {}

    for i = 1, NPC_COUNT do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 5, 50, true, true, false)
        if randomSquare then
            local x = randomSquare:getX()
            local y = randomSquare:getY()
            local z = randomSquare:getZ()

            local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist", 50)
            local zombie = newZombies:getFirst()
            if zombie then
                local npc = ChaosNPC:new(zombie)
                zombie:dressInRandomOutfit()
                npc:initializeHuman()
                npc.npcGroup = ChaosNPCGroupID.COMPANIONS
                table.insert(spawnedNpcs, npc)
            end
        end
    end

    if #spawnedNpcs < 2 then return end

    local npcA = spawnedNpcs[1]
    local npcB = spawnedNpcs[2]
    if not npcA or not npcB then return end
    if not npcA.zombie or not npcB.zombie then return end


    ChaosNPCRelations.SetNPCRelationToCharacterId(npcA, npcB.zombie:getID(), ChaosNPCRelationType.ATTACK)
    ChaosNPCRelations.SetNPCRelationToCharacterId(npcB, npcA.zombie:getID(), ChaosNPCRelationType.ATTACK)

    npcA.enemy = nil
    npcB.enemy = nil
    npcA.findEnemyTimeoutMs = CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS
    npcB.findEnemyTimeoutMs = CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS
end
