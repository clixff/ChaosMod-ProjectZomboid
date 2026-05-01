EffectCureZombiesNearby = ChaosEffectBase:derive("EffectCureZombiesNearby", "cure_zombies_nearby")

local RADIUS = 12

function EffectCureZombiesNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectCureZombiesNearby] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local curedCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, RADIUS, function(zombie)
        if zombie:isDead() then return end
        if zombie:isReanimatedPlayer() then return end

        local npc = ChaosNPC:new(zombie)
        npc:initializeHuman()
        npc.npcGroup = ChaosNPCGroupID.PEDESTRIAN

        curedCount = curedCount + 1
    end, true, z)

    print("[EffectCureZombiesNearby] Cured " .. tostring(curedCount) .. " zombies")
end
