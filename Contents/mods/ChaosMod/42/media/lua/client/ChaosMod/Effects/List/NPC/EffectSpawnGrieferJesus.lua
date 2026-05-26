---@class EffectSpawnGrieferJesus : ChaosEffectBase
---@field npc ChaosNPC|nil
EffectSpawnGrieferJesus = ChaosEffectBase:derive("EffectSpawnGrieferJesus", "spawn_griefer_jesus")

function EffectSpawnGrieferJesus:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnGrieferJesus] OnStart" .. tostring(self.effectId))
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

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)
    npc.maxHealth = 5.0
    zombie:setHealth(npc.maxHealth)
    npc.npcGroup = ChaosNPCGroupID.RAIDERS
    npc.chanceToDropWeaponOnDeath = 0
    npc:AddTag("jesus")
    self.npc = npc

    local humanVisual = zombie:getHumanVisual()
    if humanVisual then
        humanVisual:setHairModel("Fabian")
        humanVisual:setBeardModel("Full")
        local hairColor = ImmutableColor.new(89 / 255, 73 / 255, 50 / 255)
        humanVisual:setHairColor(hairColor)
        humanVisual:setNaturalHairColor(hairColor)
        humanVisual:setBeardColor(hairColor)
        humanVisual:setNaturalBeardColor(hairColor)

        zombie:getWornItems():setFromItemVisuals(zombie:getItemVisuals())
        zombie:resetModelNextFrame()
    end

    ChaosZombie.AddZombieClothes(zombie, "Base.Dress_Long_Crafted_Burlap", nil, nil, true, false)

    npc:SetWeapon("Base.AssaultRifle")

    npc:EnterPlayerVehicle(player)
end

function EffectSpawnGrieferJesus:OnEnd()
    ChaosEffectBase:OnEnd()
    local npc = self.npc
    self.npc = nil
    if npc and npc.zombie and npc.zombie:isAlive() then
        npc:Destroy()
    end
end
