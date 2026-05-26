---@class EffectVampireWeakness : ChaosEffectBase
---@field elapsedMs integer
---@field damageCheckTimer ChaosManualTimer
---@field doDamage boolean
EffectVampireWeakness = ChaosEffectBase:derive("EffectVampireWeakness", "vampire_weakness")

local DAMAGE_DELAY_MS = 5000
local DAMAGE_CHECK_INTERVAL_MS = 500
local DAMAGE_PER_SECOND = 100.0 / (4 * 60)

---@param player IsoPlayer
---@return boolean
local function ShouldDamagePlayer(player)
    if not getGameTime():isDay() then return false end

    local sq = player:getCurrentSquare()
    if not sq then return false end
    if sq:isInARoom() then return false end
    if sq:haveRoofFull() then return false end

    if player:getVehicle() and not ChaosVehicle.IsAnySeatWindowOpenMissingOrDestroyed(player) then
        return false
    end

    return true
end

function EffectVampireWeakness:OnStart()
    ChaosEffectBase:OnStart()
    self.elapsedMs = 0
    self.damageCheckTimer = ChaosManualTimer.new(DAMAGE_CHECK_INTERVAL_MS)
    self.doDamage = false
end

---@param deltaMs integer
function EffectVampireWeakness:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    self.elapsedMs = self.elapsedMs + deltaMs
    if self.elapsedMs < DAMAGE_DELAY_MS then return end

    self.damageCheckTimer:add(deltaMs)
    if self.damageCheckTimer:isEnded() then
        self.damageCheckTimer:reset()
        self.doDamage = ShouldDamagePlayer(player)
    end

    if not self.doDamage then return end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end

    bodyDamage:ReduceGeneralHealth((deltaMs / 1000) * DAMAGE_PER_SECOND)
end

function EffectVampireWeakness:OnEnd()
    ChaosEffectBase:OnEnd()
end
