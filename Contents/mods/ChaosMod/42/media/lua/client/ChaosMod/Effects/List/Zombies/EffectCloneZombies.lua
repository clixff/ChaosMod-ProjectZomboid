EffectCloneZombies = ChaosEffectBase:derive("EffectCloneZombies", "clone_zombies")

function EffectCloneZombies:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local radius = 35

    local cloneCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, radius, function(zombie)
        local zx = zombie:getX()
        local zy = zombie:getY()
        local zz = zombie:getZ()
        local femaleChance = zombie:isFemale() and 100 or 0
        local clones = ChaosZombie.SpawnZombieAt(zx, zy, zz, 1, "Tourist", femaleChance)
        if clones and clones:size() > 0 then
            local clone = clones:getFirst()
            if clone then
                ChaosZombie.CopyCharacterVisualsAndClothes(zombie, clone)
                cloneCount = cloneCount + 1
                clone:setReanimatedPlayer(true)
            end
        end
    end, true, z)

    print("[EffectCloneZombies] Cloned " .. tostring(cloneCount) .. " zombies")
end
