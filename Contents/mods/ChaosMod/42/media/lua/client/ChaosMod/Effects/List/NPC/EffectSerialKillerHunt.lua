---@class EffectSerialKillerHunt : ChaosEffectBase
EffectSerialKillerHunt = ChaosEffectBase:derive("EffectSerialKillerHunt", "serial_killer_hunt")

function EffectSerialKillerHunt:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSerialKillerHunt] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

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

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.RAIDERS
    npc.CanAddWounds = false
    npc.DamageMultiplier = 0.5

    npc:SetWeapon("Base.HuntingKnife")

    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.Shirt_Crafted_Cotton" },
        { type = "Base.Dungarees" },
        { type = "Base.Shoes_WorkBoots" },
        { type = "Base.Gloves_LeatherGlovesBrown" },
        { type = "Base.Hat_HeadSack_Burlap" },
    })

    for _ = 1, 10 do
        local walletItem = instanceItem("Base.Wallet")
        zombie:addItemToSpawnAtDeath(walletItem)
    end
end

function EffectSerialKillerHunt:OnEnd()
    ChaosEffectBase:OnEnd()
end
