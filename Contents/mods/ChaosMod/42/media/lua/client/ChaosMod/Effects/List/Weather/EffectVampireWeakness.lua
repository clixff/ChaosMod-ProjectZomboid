---@class EffectVampireWeakness : ChaosEffectBase
---@field elapsedMs integer
EffectVampireWeakness = ChaosEffectBase:derive("EffectVampireWeakness", "vampire_weakness")

local DAMAGE_DELAY_MS = 5000
local DAMAGE_PER_SECOND = 100.0 / (4 * 60)

function EffectVampireWeakness:OnStart()
    ChaosEffectBase:OnStart()
    self.elapsedMs = 0
end

---@param deltaMs integer
function EffectVampireWeakness:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    self.elapsedMs = self.elapsedMs + deltaMs
    if self.elapsedMs < DAMAGE_DELAY_MS then return end
    if not getGameTime():isDay() then return end

    local sq = player:getCurrentSquare()
    local inRoom = sq and sq:isInARoom() or false
    local underRoof = sq and sq:haveRoofFull() or false
    local openSky = sq and not inRoom and not underRoof or false
    if not openSky then return end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end

    bodyDamage:ReduceGeneralHealth((deltaMs / 1000) * DAMAGE_PER_SECOND)
end

function EffectVampireWeakness:OnEnd()
    ChaosEffectBase:OnEnd()
end
