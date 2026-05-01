---@class EffectWomanizer : ChaosEffectBase
EffectWomanizer = ChaosEffectBase:derive("EffectWomanizer", "womanizer")

local NPC_COUNT = 2

function EffectWomanizer:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    for i = 1, NPC_COUNT do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)
        if randomSquare then
            local x = randomSquare:getX()
            local y = randomSquare:getY()
            local z = randomSquare:getZ()

            local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist", 100)
            local zombie = newZombies:getFirst()
            if zombie then
                local npc = ChaosNPC:new(zombie)
                zombie:dressInRandomOutfit()
                npc:initializeHuman()
                npc.npcGroup = ChaosNPCGroupID.RAIDERS
            end
        end
    end
end
