---@class EffectSpawnGrieferAlien : ChaosEffectBase
EffectSpawnGrieferAlien = ChaosEffectBase:derive("EffectSpawnGrieferAlien", "spawn_griefer_alien")

function EffectSpawnGrieferAlien:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnGrieferAlien] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)
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
    npc.npcGroup = ChaosNPCGroupID.RAIDERS
    --- Weapon

    npc:SetWeapon("Base.AnimalBone")

    --- Hair style
    zombie:getHumanVisual():setHairModel("")
    zombie:getHumanVisual():setHairColor(ImmutableColor.new(102 / 255, 74 / 255, 35 / 255))
    zombie:getHumanVisual():setBeardModel("")
    --- Skin texture
    zombie:getHumanVisual():setSkinTextureName("ChaosAlienMaleBody01")

    --- Remove clothes
    local visuals = zombie:getItemVisuals()

    for i = visuals:size() - 1, 0, -1 do
        local visual = visuals:get(i)
        if visual then
            visuals:clear()
            zombie:clearWornItems()
        end
    end

    zombie:resetModelNextFrame()
end

function EffectSpawnGrieferAlien:OnEnd()
    ChaosEffectBase:OnEnd()
end
