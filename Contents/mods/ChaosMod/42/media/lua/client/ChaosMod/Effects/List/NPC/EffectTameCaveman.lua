---@class EffectTameCaveman : ChaosEffectBase
EffectTameCaveman = ChaosEffectBase:derive("EffectTameCaveman", "tame_caveman")

function EffectTameCaveman:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTameCaveman] OnStart" .. tostring(self.effectId))
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
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    ChaosZombie.SetHairstyleAndBeard(zombie, {
        hairModel = "Fabian",
        beardModel = "LongScruffy",
        hairColor = ChaosUtils.MakeRGB(89, 56, 30, true),
        useHairColorForBeard = true
    })


    --- Remove default clothes
    zombie:getItemVisuals():clear()
    zombie:clearWornItems()

    --- Add new clothes
    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.Underpants_Hide" },
        { type = "Base.Vest_Hide" },
        { type = "Base.Skirt_Short_FaunHide" }
    })

    zombie:resetModelNextFrame()

    npc:SetWeapon("Base.LargeBoneClub")

    npc.DamageMultiplier = 1.5

    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:addLotsOfDirt(nil, 200, true)
end

function EffectTameCaveman:OnEnd()
    ChaosEffectBase:OnEnd()
end
