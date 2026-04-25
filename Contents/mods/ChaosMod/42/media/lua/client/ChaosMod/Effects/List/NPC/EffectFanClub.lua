---@class EffectFanClub : ChaosEffectBase
EffectFanClub = ChaosEffectBase:derive("EffectFanClub", "fan_club")

function EffectFanClub:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    for i = 1, 3 do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 4, 50, true, true, false)
        if randomSquare then
            local x = randomSquare:getX()
            local y = randomSquare:getY()
            local z = randomSquare:getZ()

            local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist", 50)
            local zombie = newZombies:getFirst()
            if zombie then
                local npc = ChaosNPC:new(zombie)
                zombie:dressInRandomOutfit()
                npc:initializeHuman()
                npc.npcGroup = ChaosNPCGroupID.FOLLOWERS
                npc:AddTag("adoring_fan")
            end
        end
    end
end
