---@class EffectZombiesDeadByDaylight : ChaosEffectBase
---@field tickAccumulatorMs integer
EffectZombiesDeadByDaylight = ChaosEffectBase:derive("EffectZombiesDeadByDaylight", "zombies_dead_by_daylight")

local TICK_INTERVAL_MS = 500
local RADIUS = 45
local DAMAGE_PER_TICK = 0.35

function EffectZombiesDeadByDaylight:OnStart()
    ChaosEffectBase:OnStart()
    self.tickAccumulatorMs = 0
end

---@param deltaMs integer
function EffectZombiesDeadByDaylight:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    self.tickAccumulatorMs = self.tickAccumulatorMs + deltaMs
    if self.tickAccumulatorMs < TICK_INTERVAL_MS then return end
    self.tickAccumulatorMs = 0

    if not getGameTime():isDay() then return end

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie or not zombie:isAlive() then return end

        local zsq = zombie:getSquare()
        if not zsq then return end
        if zsq:haveRoofFull() then return end

        zombie:SetOnFire()
        ChaosZombie.DamageZombie(zombie, DAMAGE_PER_TICK)

        if zombie:getHealth() <= 0 and zombie:isAlive() then
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:DoDeath(nil, nil)
        end
    end, true, nil)
end

function EffectZombiesDeadByDaylight:OnEnd()
    ChaosEffectBase:OnEnd()
end
