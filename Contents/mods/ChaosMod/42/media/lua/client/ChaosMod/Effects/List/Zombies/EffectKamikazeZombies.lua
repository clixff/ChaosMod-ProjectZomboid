---@class EffectKamikazeZombies : ChaosEffectBase
---@field explodedZombies table<IsoZombie, boolean>
EffectKamikazeZombies = ChaosEffectBase:derive("EffectKamikazeZombies", "kamikaze_zombies")

local TRIGGER_RADIUS = 2
local EXPLOSION_RADIUS = 3

function EffectKamikazeZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.explodedZombies = {}
end

---@param _deltaMs integer
function EffectKamikazeZombies:OnTick(_deltaMs)
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    ChaosZombie.ForEachZombieInRange(px, py, TRIGGER_RADIUS, function(zombie)
        if not zombie then return end
        if zombie:isDead() then return end
        if self.explodedZombies[zombie] then return end

        local dist = ChaosUtils.distTo(px, py, zombie:getX(), zombie:getY())
        if dist >= TRIGGER_RADIUS then return end

        local zombieSquare = zombie:getSquare()
        if not zombieSquare then return end
        if math.abs(zombie:getZ() - pz) > 0.5 then return end

        self.explodedZombies[zombie] = true
        ChaosUtils.TriggerExplosionAt(zombieSquare, EXPLOSION_RADIUS)
    end, true, nil)
end

function EffectKamikazeZombies:OnEnd()
    ChaosEffectBase:OnEnd()
    self.explodedZombies = {}
end
