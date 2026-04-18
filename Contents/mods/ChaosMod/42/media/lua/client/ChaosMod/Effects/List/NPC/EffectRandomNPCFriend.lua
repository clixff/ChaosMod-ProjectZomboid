EffectRandomZombieFriend = ChaosEffectBase:derive("EffectRandomZombieFriend", "random_zombie_friend")

function EffectRandomZombieFriend:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRandomZombieFriend] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local nearestZombie = ChaosZombie.GetNearestZombie(player:getX(), player:getY(), true)
    if not nearestZombie then return end


    local npc = ChaosNPC:new(nearestZombie)
    npc:initializeHuman()

    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    local nickname = ChaosNicknames.ensureZombieNicknameAndColor(nearestZombie)

    if nickname then
        player:Say(string.format(ChaosLocalization.GetString("misc", "npc_friend"), nickname))
    end
end
