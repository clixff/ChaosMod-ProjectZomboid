---@class EffectZombiesAreComing : ChaosEffectBase
---@field timerMs integer
EffectZombiesAreComing = ChaosEffectBase:derive("EffectZombiesAreComing", "zombies_are_coming")

local SOUND_INTERVAL_MS = 1000

local function emitSoundAndAggro()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    ---@diagnostic disable-next-line: param-type-mismatch
    addSound(nil, px, py, pz, 180, 180)
end

function EffectZombiesAreComing:OnStart()
    ChaosEffectBase:OnStart()

    self.timerMs = 0

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    ChaosZombie.ForEachZombieInRange(px, py, 120, function(zombie)
        if zombie and zombie:isAlive() then
            ChaosZombie.MoveToPlayerSpotted(zombie, player)
        end
    end, true, nil)

    emitSoundAndAggro()
end

function EffectZombiesAreComing:OnTick(deltaMs)
    self.timerMs = (self.timerMs or 0) + (deltaMs or 0)
    while self.timerMs >= SOUND_INTERVAL_MS do
        self.timerMs = self.timerMs - SOUND_INTERVAL_MS
        emitSoundAndAggro()
    end
end
