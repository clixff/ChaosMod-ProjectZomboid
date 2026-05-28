---@class EffectSpawnAgent47 : ChaosEffectBase
---@field npc? ChaosNPC
---@field zombie? IsoZombie
EffectSpawnAgent47 = ChaosEffectBase:derive("EffectSpawnAgent47", "spawn_agent_47")

function EffectSpawnAgent47:OnStart()
    ChaosEffectBase:OnStart()

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
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.RAIDERS

    ChaosZombie.HumanizeZombie(zombie)

    local humanVisual = zombie:getHumanVisual()
    if humanVisual then
        ---@diagnostic disable-next-line: param-type-mismatch
        humanVisual:setHairModel("")
        ---@diagnostic disable-next-line: param-type-mismatch
        humanVisual:setBeardModel("")
    end

    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.WeddingJacket" },
        { type = "Base.Shirt_FormalTINT", tint = { r = 1.0, g = 1.0, b = 1.0 } },
        { type = "Base.Gloves_WhiteTINT", tint = { r = 0, g = 0.0, b = 0.0 } },
        { type = "Base.Tie_Full",         textureChoice = 5 },
        { type = "Base.Trousers_Black" },
        { type = "Base.Shoes_Black" },
    })

    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()

    npc:SetWeapon("Base.Pistol")


    self.npc = npc
    self.zombie = zombie

    zombie:addItemToSpawnAtDeath(instanceItem("Base.Rubberducky"))
    zombie:addItemToSpawnAtDeath(instanceItem("Base.Briefcase"))
end

---@param deltaMs integer
function EffectSpawnAgent47:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectSpawnAgent47:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.npc and self.npc.zombie then
        self.npc:Destroy()
    end

    self.npc = nil
    self.zombie = nil
end
