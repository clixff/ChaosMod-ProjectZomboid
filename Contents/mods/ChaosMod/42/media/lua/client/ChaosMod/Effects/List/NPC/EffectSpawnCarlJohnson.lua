---@class EffectSpawnCarlJohnson : ChaosEffectBase
EffectSpawnCarlJohnson = ChaosEffectBase:derive("EffectSpawnCarlJohnson", "spawn_carl_johnson")

function EffectSpawnCarlJohnson:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnCarlJohnson] OnStart" .. tostring(self.effectId))
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

    --- Hair / beard
    zombie:getHumanVisual():setHairModel("Cornrows")
    zombie:getHumanVisual():setHairColor(ImmutableColor.new(0, 0, 0))
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:getHumanVisual():setBeardModel("")
    --- Skin texture
    zombie:getHumanVisual():setSkinTextureName("ChaosCJMaleBody01")

    --- Remove clothes
    local visuals = zombie:getItemVisuals()

    for i = visuals:size() - 1, 0, -1 do
        local visual = visuals:get(i)
        if visual then
            visuals:clear()
            zombie:clearWornItems()
        end
    end

    npc:SetWeapon("Base.BaseballBat")

    ChaosZombie.AddZombieClothes(zombie, "Base.Vest_DefaultTEXTURE", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Trousers_JeanBaggy", nil, 2, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.Shoes_TrainerTINT", { r = 0.5, g = 0.5, b = 0.5 }, 0, true, true)


    zombie:addItemToSpawnAtDeath(instanceItem("Base.CigaretteRolled"))

    local itemsToAdd = 50
    local itemId = "Base.MoneyBundle"

    for i = 1, itemsToAdd do
        zombie:addItemToSpawnAtDeath(instanceItem(itemId))
    end


    zombie:resetModelNextFrame()
end

function EffectSpawnCarlJohnson:OnEnd()
    ChaosEffectBase:OnEnd()
end
