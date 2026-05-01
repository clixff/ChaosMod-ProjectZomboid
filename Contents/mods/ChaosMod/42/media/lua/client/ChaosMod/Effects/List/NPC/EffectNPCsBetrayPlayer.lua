---@class EffectNPCsBetrayPlayer : ChaosEffectBase
EffectNPCsBetrayPlayer = ChaosEffectBase:derive("EffectNPCsBetrayPlayer", "npcs_betray_player")

function EffectNPCsBetrayPlayer:OnStart()
    ChaosEffectBase:OnStart()

    local changed = 0
    local npcList = ChaosNPCUtils.npcList
    for i = 0, npcList:size() - 1 do
        ---@type ChaosNPC
        local npc = npcList:get(i)
        if npc and npc.zombie and npc.zombie:isAlive() then
            local isFriendlyGroup = npc.npcGroup == ChaosNPCGroupID.COMPANIONS or
                npc.npcGroup == ChaosNPCGroupID.FOLLOWERS
            if isFriendlyGroup then
                npc.npcGroup = ChaosNPCGroupID.RAIDERS
                npc.DamageMultiplier = 0.5
                npc.CanAddWounds = false
                npc.enemy = nil
                npc.findEnemyTimeoutMs = CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS
                changed = changed + 1
            end
        end
    end

    print("[EffectNPCsBetrayPlayer] Friendly NPC turned hostile: " .. tostring(changed))
end
