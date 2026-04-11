EffectKillNearbyZombies = ChaosEffectBase:derive("EffectKillNearbyZombies", "kill_nearby_zombies")

function EffectKillNearbyZombies:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()

    local zombies = getCell():getZombieList()
    if not zombies then return end

    print("[EffectKillNearbyZombies] Killing nearby zombies. Total before killing: " .. tostring(zombies:size()))

    local killedZombies = 0
    ---@type HandWeapon?
    local weapon = player:getPrimaryHandItem()
    if not weapon or not weapon:IsWeapon() then
        weapon = instanceItem("Base.BareHands")
    end

    ChaosZombie.ForEachZombieInRange(x1, y1, 35, function(zombie)
        if zombie and zombie:isAlive() then
            zombie:setHealth(0)
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:DoDeath(weapon, player)
            killedZombies = killedZombies + 1
        end
    end, false, nil)

    print("[EffectKillNearbyZombies] Killed zombies: " .. tostring(killedZombies))
end
