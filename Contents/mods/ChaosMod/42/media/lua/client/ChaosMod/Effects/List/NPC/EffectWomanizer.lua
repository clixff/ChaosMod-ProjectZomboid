---@class EffectWomanizer : ChaosEffectBase
EffectWomanizer = ChaosEffectBase:derive("EffectWomanizer", "womanizer")

local NPC_COUNT = 2

function EffectWomanizer:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local nicknameAssigned = false
    for i = 1, NPC_COUNT do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)
        if randomSquare then
            local x = randomSquare:getX()
            local y = randomSquare:getY()
            local z = randomSquare:getZ()

            local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist", 100)
            local zombie = newZombies:getFirst()
            if zombie then
                local nickname = (not nicknameAssigned) and self.effectNickname or nil
                local npc = ChaosNPC:new(zombie, nickname)
                nicknameAssigned = true
                zombie:dressInRandomOutfit()
                npc:initializeHuman()
                npc.npcGroup = ChaosNPCGroupID.RAIDERS
                npc:EnterPlayerVehicle(player)
            end
        end
    end
end
