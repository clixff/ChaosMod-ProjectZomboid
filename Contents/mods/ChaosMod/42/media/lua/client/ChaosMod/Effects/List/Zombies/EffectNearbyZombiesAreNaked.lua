EffectNearbyZombiesAreNaked = ChaosEffectBase:derive("EffectNearbyZombiesAreNaked", "nearby_zombies_are_naked")

function EffectNearbyZombiesAreNaked:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectNearbyZombiesAreNaked] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()

    local strippedZombies = 0

    ChaosZombie.ForEachZombieInRange(x1, y1, 30, function(zombie)
        if not zombie or not zombie:isAlive() then return end

        zombie:setReanimatedPlayer(true)
        zombie:getHumanVisual():getBodyVisuals():clear()
        zombie:clearWornItems()
        zombie:resetModelNextFrame()

        strippedZombies = strippedZombies + 1
    end, false, nil)

    print("[EffectNearbyZombiesAreNaked] Stripped zombies: " .. tostring(strippedZombies))
end
