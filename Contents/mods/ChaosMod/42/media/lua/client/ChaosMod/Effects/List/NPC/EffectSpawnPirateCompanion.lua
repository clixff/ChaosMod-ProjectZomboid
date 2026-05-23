---@class EffectSpawnPirateCompanion : ChaosEffectBase
EffectSpawnPirateCompanion = ChaosEffectBase:derive("EffectSpawnPirateCompanion", "spawn_pirate_companion")

function EffectSpawnPirateCompanion:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnPirateCompanion] OnStart" .. tostring(self.effectId))
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

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    --- Remove default clothes
    local visuals = zombie:getItemVisuals()
    for i = visuals:size() - 1, 0, -1 do
        local visual = visuals:get(i)
        if visual then
            visuals:clear()
            zombie:clearWornItems()
        end
    end

    npc:SetWeapon("Base.CrudeSword")

    --- Pirate outfit
    ChaosZombie.AddZombieClothes(zombie, "Base.Hat_Pirate", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Glasses_Eyepatch_Left", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Shirt_Crafted_Cotton", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Vest_Waistcoat", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Trousers_Black", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Shoes_CowboyBoots", nil, nil, true)

    zombie:resetModelNextFrame()
end

function EffectSpawnPirateCompanion:OnEnd()
    ChaosEffectBase:OnEnd()
end
