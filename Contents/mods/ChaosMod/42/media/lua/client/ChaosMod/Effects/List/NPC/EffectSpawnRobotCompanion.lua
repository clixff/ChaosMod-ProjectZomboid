---@class EffectSpawnRobotCompanion : ChaosEffectBase
EffectSpawnRobotCompanion = ChaosEffectBase:derive("EffectSpawnRobotCompanion", "spawn_robot_companion")

function EffectSpawnRobotCompanion:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnRobotCompanion] OnStart" .. tostring(self.effectId))
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
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    --- Hair / beard
    local humanVisual = zombie:getHumanVisual()
    humanVisual:setHairModel("")
    ---@diagnostic disable-next-line: param-type-mismatch
    humanVisual:setBeardModel("")

    --- Skin texture
    zombie:getHumanVisual():setSkinTextureName("ChaosRobotMaleBody01")

    --- Remove default clothes
    zombie:getItemVisuals():clear()
    zombie:clearWornItems()

    zombie:resetModelNextFrame()
end

function EffectSpawnRobotCompanion:OnEnd()
    ChaosEffectBase:OnEnd()
end
