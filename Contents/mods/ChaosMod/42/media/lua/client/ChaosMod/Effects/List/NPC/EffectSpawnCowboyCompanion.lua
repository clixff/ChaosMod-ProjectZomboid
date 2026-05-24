---@class EffectSpawnCowboyCompanion : ChaosEffectBase
EffectSpawnCowboyCompanion = ChaosEffectBase:derive("EffectSpawnCowboyCompanion", "spawn_cowboy_companion")

function EffectSpawnCowboyCompanion:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnCowboyCompanion] OnStart" .. tostring(self.effectId))
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
        0
    )

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    npc:SetWeapon("Base.Revolver_Long")

    ChaosZombie.AddZombieClothes(zombie, "Base.Shirt_Crafted_Cotton", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Trousers_Black", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Vest_SheepSkin", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Hat_Cowboy_White", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Shoes_CowboyBoots_Fancy", nil, nil, true)
end
