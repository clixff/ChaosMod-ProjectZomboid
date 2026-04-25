---@class EffectZombiesWalkAway : ChaosEffectBase
EffectZombiesWalkAway = ChaosEffectBase:derive("EffectZombiesWalkAway", "zombies_walk_away")

function EffectZombiesWalkAway:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    local counter = 0

    ChaosZombie.ForEachZombieInRange(px, py, 30, function(zombie)
        local zx = zombie:getX()
        local zy = zombie:getY()
        local zz = zombie:getZ()

        local dx = zx - px
        local dy = zy - py
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < 0.01 then return end

        local nx = dx / dist
        local ny = dy / dist

        local tx = math.floor(zx + nx * 30)
        local ty = math.floor(zy + ny * 30)

        ChaosZombie.MoveToLocation(zombie, tx, ty, zz, true, true, true, true)
        counter = counter + 1
    end, true, nil)

    print("[EffectZombiesWalkAway] Redirected " .. tostring(counter) .. " zombies away from player")
end
