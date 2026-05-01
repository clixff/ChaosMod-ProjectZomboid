---@class EffectKillAllFriendlyNPC : ChaosEffectBase
EffectKillAllFriendlyNPC = ChaosEffectBase:derive("EffectKillAllFriendlyNPC", "kill_all_friendly_npc")

function EffectKillAllFriendlyNPC:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ---@type HandWeapon?
    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        weapon = instanceItem("Base.BareHands")
    end

    local killed = 0
    local npcList = ChaosNPCUtils.npcList
    for i = 0, npcList:size() - 1 do
        ---@type ChaosNPC
        local npc = npcList:get(i)
        if npc and npc.zombie and npc.zombie:isAlive() then
            local isFriendlyGroup = npc.npcGroup == ChaosNPCGroupID.COMPANIONS or
                npc.npcGroup == ChaosNPCGroupID.FOLLOWERS
            if isFriendlyGroup then
                npc.zombie:setHealth(0)
                ---@diagnostic disable-next-line: param-type-mismatch
                npc.zombie:DoDeath(weapon, player)
                killed = killed + 1
            end
        end
    end

    print("[EffectKillAllFriendlyNPC] Killed friendly NPC: " .. tostring(killed))
end
