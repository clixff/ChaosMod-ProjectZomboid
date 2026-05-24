---@class EffectBetterCallSaul : ChaosEffectBase
EffectBetterCallSaul = ChaosEffectBase:derive("EffectBetterCallSaul", "better_call_saul")

function EffectBetterCallSaul:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectBetterCallSaul] OnStart " .. tostring(self.effectId))

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
        humanVisual:setHairModel("LeftParting")
        ---@diagnostic disable-next-line: param-type-mismatch
        humanVisual:setBeardModel("")

        local hairColor = ImmutableColor.new(102 / 255, 74 / 255, 35 / 255)
        humanVisual:setHairColor(hairColor)
        humanVisual:setNaturalHairColor(hairColor)
    end

    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.WeddingJacket" },
        { type = "Base.Shirt_FormalTINT", tint = { r = 244, g = 151, b = 166, normalize = true }, },
        { type = "Base.Tie_Full",         textureChoice = 4 },
        { type = "Base.Trousers_Black" },
        { type = "Base.Shoes_Brown" },
    })


    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()

    npc:SetWeapon("Base.Gavel")

    ChaosZombie.AddNewChatLine(zombie, "Did you know that you have rights?",
        { r = 66 / 255, g = 133 / 255, b = 244 / 255 })
end

function EffectBetterCallSaul:OnEnd()
    ChaosEffectBase:OnEnd()
end
