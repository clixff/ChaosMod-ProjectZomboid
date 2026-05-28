---@class EffectSpawnJaysEmployee : ChaosEffectBase
EffectSpawnJaysEmployee = ChaosEffectBase:derive("EffectSpawnJaysEmployee", "spawn_jays_employee")

function EffectSpawnJaysEmployee:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnJaysEmployee] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 4, 50, true, true, false)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Naked",
        50
    )

    local zombie = newZombies and newZombies:getFirst() or nil
    if not zombie then return end

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    ChaosZombie.HumanizeZombie(zombie)

    npc:SetWeapon("Base.GridlePan")

    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.Shoes_TrainerTINT", tint = { r = 255, g = 255, b = 255, normalize = true }, alternativeTint = true },
        { type = "Base.Socks_Ankle_White" },
        { type = "Base.Trousers_Suit" },
        { type = "Base.Tshirt_WhiteTINT",  tint = { r = 255, g = 255, b = 255, normalize = true }, alternativeTint = true },
        { type = "Base.Apron_Jay" },
        { type = "Base.Hat_Jay" },
    })
end

function EffectSpawnJaysEmployee:OnEnd()
    ChaosEffectBase:OnEnd()
end
