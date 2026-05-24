---@class EffectSpawnMysteriousStranger : ChaosEffectBase
---@field npc ChaosNPC|nil
EffectSpawnMysteriousStranger = ChaosEffectBase:derive("EffectSpawnMysteriousStranger", "spawn_mysterious_stranger")

function EffectSpawnMysteriousStranger:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnMysteriousStranger] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

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

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie, self.effectNickname)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS
    npc.maxHealth = 10.0
    zombie:setHealth(10.0)
    npc.chanceToDropWeaponOnDeath = 0.0
    npc.firearmAccuracyZombies = 100.0
    npc.DamageMultiplier = 10.0
    npc.enemyDistanceFindRadius = 20.0
    npc.canBePanicked = false
    npc:AddTag("mysterious_stranger")
    self.npc = npc

    npc:SetWeapon("Base.Revolver_Long")



    randomSquare:playSound("chaos_mysterious_stranger")

    local humanVisual = zombie:getHumanVisual()
    if not humanVisual then return end


    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.Jacket_WhiteTINT", tint = { r = 118, g = 107, b = 77, normalize = true } },
        { type = "Base.Shirt_FormalTINT", tint = { r = 1.0, g = 1.0, b = 1.0 }, },
        { type = "Base.Tie_Full",         textureChoice = 5 },
        { type = "Base.Trousers_Black" },
        { type = "Base.Shoes_Brown" },
        { type = "Base.Hat_Fedora",       textureChoice = 1 }
    })

    humanVisual:setHairModel("")
    humanVisual:setBeardModel("")

    zombie:getWornItems():setFromItemVisuals(zombie:getItemVisuals())
    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()
end

---@param deltaMs integer
function EffectSpawnMysteriousStranger:OnTick(deltaMs)
    local npc = self.npc
    if npc and npc.zombie and npc.zombie:isAlive() then
        npc.zombie:setHealth(npc.maxHealth)
    end
end

function EffectSpawnMysteriousStranger:OnEnd()
    ChaosEffectBase:OnEnd()
    local npc = self.npc
    self.npc = nil
    if npc and npc.zombie then
        npc:Destroy()
    end

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    playerSquare:playSound("chaos_mysterious_stranger_02")
end
