EffectSpawnGrieferSanta = ChaosEffectBase:derive("EffectSpawnGrieferSanta", "spawn_griefer_santa")

local SANTA_OUTFIT = {
    { type = "Base.Hat_SantaHat" },
    { type = "Base.JacketLong_Santa" },
    { type = "Base.Trousers_Santa" },
    { type = "Base.Gloves_LongWomenGloves" },
    { type = "Base.Shoes_BlackBoots" },
}

function EffectSpawnGrieferSanta:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnGrieferSanta] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local x1 = playerSquare:getX()
    local y1 = playerSquare:getY()
    local z1 = playerSquare:getZ()

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)

    if not randomSquare then return end

    local x2 = randomSquare:getX()
    local y2 = randomSquare:getY()
    local z2 = randomSquare:getZ()

    local newZombies = ChaosZombie.SpawnZombieAt(x2, y2, z2, 1, "Naked", 0)

    local zombie = newZombies:getFirst()
    if not zombie then return end


    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()

    npc.npcGroup = ChaosNPCGroupID.RAIDERS

    -- npc:SetWeapon("Base.Sledgehammer")
    npc:EnterPlayerVehicle(player)

    npc:SetWeapon("Base.Pistol")

    ChaosZombie.SetHairstyleAndBeard(zombie, {
        hairModel = "Messy",
        beardModel = "LongScruffy",
        useHairColorForBeard = true,
        hairColor = ChaosUtils.MakeRGB(255, 255, 255, true),
    })

    ChaosZombie.AddZombieClothesBatch(zombie, SANTA_OUTFIT)
end
