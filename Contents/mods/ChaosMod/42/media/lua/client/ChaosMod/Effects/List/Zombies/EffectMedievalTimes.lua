EffectMedievalTimes = ChaosEffectBase:derive("EffectMedievalTimes", "medieval_times")

local RADIUS = 90
local HELMET_FULL_TYPE = "Base.Hat_MetalHelmet"

function EffectMedievalTimes:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local updatedCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, RADIUS, function(zombie)
        if zombie:isDead() then return end
        if zombie:isReanimatedPlayer() then return end

        local visual = ChaosZombie.AddZombieClothes(zombie, HELMET_FULL_TYPE)
        if not visual then return end

        updatedCount = updatedCount + 1
    end, true, z)

    print("[EffectMedievalTimes] Added helmets to " .. tostring(updatedCount) .. " zombies")
end
