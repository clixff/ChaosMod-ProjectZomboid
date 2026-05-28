---@class EffectSpawnShaunOfTheDead : ChaosEffectBase
EffectSpawnShaunOfTheDead = ChaosEffectBase:derive("EffectSpawnShaunOfTheDead", "spawn_shaun_of_the_dead")

function EffectSpawnShaunOfTheDead:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnShaunOfTheDead] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 5, 50, true, true, false)
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
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    ChaosZombie.HumanizeZombie(zombie)

    local humanVisual = zombie:getHumanVisual()
    if humanVisual then
        humanVisual:setHairModel("Recede")
        ---@diagnostic disable-next-line: param-type-mismatch
        humanVisual:setBeardModel("Goatee")

        local blondeColor = ImmutableColor.new(230 / 255, 200 / 255, 130 / 255)
        humanVisual:setHairColor(blondeColor)
        humanVisual:setNaturalHairColor(blondeColor)
        humanVisual:setBeardColor(blondeColor)
        humanVisual:setNaturalBeardColor(blondeColor)
    end

    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.Shirt_FormalTINT", tint = { r = 1, g = 1, b = 1 } },
        { type = "Base.Tie_Full",         textureChoice = 5 },
        { type = "Base.Trousers_Suit" },
        { type = "Base.Shoes_Black" },
    })

    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()

    npc:SetWeapon("Base.Plank")
end

function EffectSpawnShaunOfTheDead:OnEnd()
    ChaosEffectBase:OnEnd()
end
