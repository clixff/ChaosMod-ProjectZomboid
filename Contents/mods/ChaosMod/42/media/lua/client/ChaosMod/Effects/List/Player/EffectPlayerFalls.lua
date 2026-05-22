---@class EffectPlayerFalls : ChaosEffectBase
---@field lastFallTimeMs integer | nil
---@field onPlayerUpdate fun(player: IsoPlayer) | nil
EffectPlayerFalls = ChaosEffectBase:derive("EffectPlayerFalls", "player_falls")

local FALL_COOLDOWN_MS = 10000

local function triggerFall(player)
    player:clearVariable("BumpFallType")
    player:setBumpStaggered(true)
    player:setBumpType("stagger")
    player:setBumpFall(true)
    player:setBumpFallType("pushedBehind")
end

---@param player IsoPlayer
function EffectPlayerFalls:HandlePlayerUpdate(player)
    if not player or player:isDead() then return end
    if not player:isPlayerMoving() then return end

    local now = getTimestampMs()
    if self.lastFallTimeMs and now - self.lastFallTimeMs < FALL_COOLDOWN_MS then
        return
    end

    self.lastFallTimeMs = now
    triggerFall(player)
end

function EffectPlayerFalls:OnStart()
    ChaosEffectBase:OnStart()

    self.lastFallTimeMs = nil

    self.onPlayerUpdate = function(player)
        self:HandlePlayerUpdate(player)
    end

    Events.OnPlayerUpdate.Add(self.onPlayerUpdate)
end

function EffectPlayerFalls:OnEnd()
    ChaosEffectBase:OnEnd()
    if self.onPlayerUpdate then
        Events.OnPlayerUpdate.Remove(self.onPlayerUpdate)
        self.onPlayerUpdate = nil
    end
end
