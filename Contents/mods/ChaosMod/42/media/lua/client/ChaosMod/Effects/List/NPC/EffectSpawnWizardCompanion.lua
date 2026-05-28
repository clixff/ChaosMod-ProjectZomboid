---@class EffectSpawnWizardCompanion : ChaosEffectBase
EffectSpawnWizardCompanion = ChaosEffectBase:derive("EffectSpawnWizardCompanion", "spawn_wizard_companion")

function EffectSpawnWizardCompanion:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnWizardCompanion] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

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

    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)

    npc:SetWeapon("Base.LongStick")

    ChaosZombie.AddZombieClothes(zombie, "Base.Hat_Wizard", nil, nil, false)
    ChaosZombie.AddZombieClothes(zombie, "Base.BlackRobe", nil, nil, true)

    ChaosZombie.SetHairstyleAndBeard(zombie, {
        hairModel = "Messy",
        beardModel = "LongScruffy",
        useHairColorForBeard = true,
        hairColor = ChaosUtils.MakeRGB(255, 255, 255, true),
    })

    npc:EnterPlayerVehicle(player)
end

function EffectSpawnWizardCompanion:OnEnd()
    ChaosEffectBase:OnEnd()
end
