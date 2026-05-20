---@class EffectSpawnOrcFriend : ChaosEffectBase
EffectSpawnOrcFriend = ChaosEffectBase:derive("EffectSpawnOrcFriend", "spawn_orc_friend")

function EffectSpawnOrcFriend:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnOrcFriend] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

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

    local zombie = newZombies and newZombies:getFirst() or nil
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    --- Weapon
    npc:SetWeapon("Base.Cudgel_Bone")

    --- Hair style
    zombie:getHumanVisual():setHairModel("MohawkFlat")
    zombie:getHumanVisual():setHairColor(ImmutableColor.new(102 / 255, 74 / 255, 35 / 255))
    zombie:getHumanVisual():setBeardModel("")
    --- Skin texture
    zombie:getHumanVisual():setSkinTextureName("ChaosOrcMaleBody01")

    --- Remove clothes
    local visuals = zombie:getItemVisuals()

    for i = visuals:size() - 1, 0, -1 do
        local visual = visuals:get(i)
        if visual then
            visuals:clear()
            zombie:clearWornItems()
        end
    end

    --- Ad new clothes
    ChaosZombie.AddZombieClothes(zombie, "Base.Skirt_Knees_Hide", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Shoulderpad_Articulated_R_Metal", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Shoulderpad_Articulated_L_Metal", nil, nil, true)


    zombie:resetModelNextFrame()
end

function EffectSpawnOrcFriend:OnEnd()
    ChaosEffectBase:OnEnd()
end
