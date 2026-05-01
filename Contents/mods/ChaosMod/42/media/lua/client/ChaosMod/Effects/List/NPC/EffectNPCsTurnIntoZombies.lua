---@class EffectNPCsTurnIntoZombies : ChaosEffectBase
EffectNPCsTurnIntoZombies = ChaosEffectBase:derive("EffectNPCsTurnIntoZombies", "npcs_turn_into_zombies")

function EffectNPCsTurnIntoZombies:OnStart()
    ChaosEffectBase:OnStart()

    local converted = 0
    local snapshot = {}
    local npcList = ChaosNPCUtils.npcList

    for i = 0, npcList:size() - 1 do
        local npc = npcList:get(i)
        if npc then
            table.insert(snapshot, npc)
        end
    end

    for i = 1, #snapshot do
        ---@type ChaosNPC
        local npc = snapshot[i]
        if npc and npc.zombie and npc.zombie:isAlive() then
            npc:setNPCAsZombie()
            converted = converted + 1
        end
    end

    print("[EffectNPCsTurnIntoZombies] NPC turned into zombies: " .. tostring(converted))
end
