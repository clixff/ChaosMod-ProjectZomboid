---@class EffectKamikazeZombies : ChaosEffectBase
---@field explodedZombies table<IsoZombie, boolean>
---@field soundCooldownTimer ChaosManualTimer
EffectKamikazeZombies = ChaosEffectBase:derive("EffectKamikazeZombies", "kamikaze_zombies")

local TRIGGER_RADIUS = 2
local EXPLOSION_RADIUS = 3
local SOUND_COOLDOWN_MS = 2500

function EffectKamikazeZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.explodedZombies = {}
    self.soundCooldownTimer = ChaosManualTimer.new(SOUND_COOLDOWN_MS)
    self.soundCooldownTimer:add(SOUND_COOLDOWN_MS) -- first explosion always plays the sound
end

---@param deltaMs integer
function EffectKamikazeZombies:OnTick(deltaMs)
    self.soundCooldownTimer:add(deltaMs)

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

        local playSound = self.soundCooldownTimer:isEnded()
        if playSound then
            self.soundCooldownTimer:reset()
        end
        ChaosUtils.TriggerExplosionAt(zombieSquare, EXPLOSION_RADIUS, true, not playSound)
    end, true, nil)
end

function EffectKamikazeZombies:OnEnd()
    ChaosEffectBase:OnEnd()
    self.explodedZombies = {}
end
