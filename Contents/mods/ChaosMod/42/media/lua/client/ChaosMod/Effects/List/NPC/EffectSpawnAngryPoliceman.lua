EffectSpawnAngryPoliceman = ChaosEffectBase:derive("EffectSpawnAngryPoliceman", "spawn_angry_policeman")

function EffectSpawnAngryPoliceman:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnAngryPoliceman] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local x1 = playerSquare:getX()
    local y1 = playerSquare:getY()
    local z1 = playerSquare:getZ()

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)

    if not randomSquare then return end

    local x2 = randomSquare:getX()
    local y2 = randomSquare:getY()
    local z2 = randomSquare:getZ()

    local newZombies = ChaosZombie.SpawnZombieAt(x2, y2, z2, 1, "Police", 0)

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()

    npc.npcGroup = ChaosNPCGroup.OUTLAW

    ChaosZombie.RemoveAllWeapons(zombie)
    npc:SetWeapon("Base.Nightstick")
end
