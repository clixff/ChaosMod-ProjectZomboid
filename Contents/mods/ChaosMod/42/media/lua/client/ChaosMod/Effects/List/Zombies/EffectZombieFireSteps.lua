EffectZombieFireSteps = ChaosEffectBase:derive("EffectZombieFireSteps", "zombie_fire_steps")

local RADIUS = 30

function EffectZombieFireSteps:OnStart()
    ChaosEffectBase:OnStart()
end

---@param deltaMs integer
function EffectZombieFireSteps:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end
    local cell = getCell()
    if not cell then return end

    ChaosZombie.ForEachZombieInRange(player:getX(), player:getY(), RADIUS, function(zombie)
        if not zombie or zombie:isDead() then return end
        local currentSquare = zombie:getSquare()
        if not currentSquare then return end

        IsoFireManager.StartFire(cell, currentSquare, true, 100, 3000)
    end, true)
end

function EffectZombieFireSteps:OnEnd()
    ChaosEffectBase:OnEnd()
end
