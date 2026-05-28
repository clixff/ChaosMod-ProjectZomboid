EffectSpiffoApocalypse = ChaosEffectBase:derive("EffectSpiffoApocalypse", "spiffo_apocalypse")

function EffectSpiffoApocalypse:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local radius = 80
    local updatedCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, radius, function(zombie)
        if zombie:isDead() then return end
        ChaosZombie.AddZombieClothesBatch(zombie, {
            { type = "Base.SpiffoSuit" },
            { type = "Base.Hat_Spiffo" },
            { type = "Base.SpiffoTail" },
        })
        updatedCount = updatedCount + 1
    end, true, z)

    ChaosPlayer.SayLineByColor(player, string.format("Updated %d zombie outfits", updatedCount), ChaosPlayerChatColors.green)
    print("[EffectSpiffoApocalypse] Updated " .. tostring(updatedCount) .. " zombies")
end

function EffectSpiffoApocalypse:OnEnd()
    ChaosEffectBase:OnEnd()
end
