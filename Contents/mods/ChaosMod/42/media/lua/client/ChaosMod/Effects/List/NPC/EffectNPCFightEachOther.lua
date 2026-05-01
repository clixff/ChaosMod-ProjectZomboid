---@class EffectNPCFightEachOther : ChaosEffectBase
EffectNPCFightEachOther = ChaosEffectBase:derive("EffectNPCFightEachOther", "npc_fight_each_other")

function EffectNPCFightEachOther:OnStart()
    ChaosEffectBase:OnStart()

    local npcList = ChaosNPCUtils.npcList
    for i = 0, npcList:size() - 1 do
        ---@type ChaosNPC
        local npc = npcList:get(i)
        if npc and npc.zombie and npc.zombie:isAlive() then
            for j = 0, npcList:size() - 1 do
                if i ~= j then
                    ---@type ChaosNPC
                    local otherNpc = npcList:get(j)
                    if otherNpc and otherNpc.zombie and otherNpc.zombie:isAlive() then
                        ChaosNPCRelations.SetNPCRelationToCharacterId(
                            npc,
                            otherNpc.zombie:getID(),
                            ChaosNPCRelationType.ATTACK
                        )
                    end
                end
            end

            npc.enemy = nil
            npc.findEnemyTimeoutMs = CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS
        end
    end
end
