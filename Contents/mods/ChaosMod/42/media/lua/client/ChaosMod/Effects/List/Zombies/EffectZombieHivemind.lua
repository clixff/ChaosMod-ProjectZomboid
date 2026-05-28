---@class EffectZombieHivemind : ChaosEffectBase
---@field throttleTimer ChaosManualTimer
EffectZombieHivemind = ChaosEffectBase:derive("EffectZombieHivemind", "zombie_hivemind")

local THROTTLE_MS = 500
local RADIUS = 50

function EffectZombieHivemind:OnStart()
    ChaosEffectBase:OnStart()
    self.throttleTimer = ChaosManualTimer.new(THROTTLE_MS)
end

function EffectZombieHivemind:UpdateHivemind()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    ---@type table<integer, IsoZombie>
    local candidates = {}
    local anyZombieTargetsPlayer = false

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie or not zombie:isAlive() then return end

        local target = zombie:getTarget()
        if target == player then
            anyZombieTargetsPlayer = true
        elseif not target then
            table.insert(candidates, zombie)
        end
    end, true, nil)

    if not anyZombieTargetsPlayer then return end

    for _, zombie in ipairs(candidates) do
        ChaosZombie.MoveToSound(zombie, px, py, pz)
    end
end

---@param deltaMs integer
function EffectZombieHivemind:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    self.throttleTimer:add(deltaMs)
    if self.throttleTimer:isEnded() then
        self.throttleTimer:reset()
        self:UpdateHivemind()
    end
end

function EffectZombieHivemind:OnEnd()
    ChaosEffectBase:OnEnd()
end
