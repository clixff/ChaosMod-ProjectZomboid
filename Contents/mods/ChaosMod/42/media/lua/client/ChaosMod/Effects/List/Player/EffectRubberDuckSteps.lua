local SOUND_NAME = "chaos_duck_footstep_01"
local MIN_DISTANCE = 0.85
local MIN_DELAY_MS_WALK = 500
local MIN_DELAY_MS_RUN = 350
local SOUND_RADIUS = 8.0
local SOUND_MAX_GAIN = 0.25
local SOUND_PITCH_VAR = 0.1
local ZOMBIE_HEARING_RADIUS = 15
local ZOMBIE_HEARING_VOLUME = 8

---@class EffectRubberDuckSteps : ChaosEffectBase
---@field lastX number | nil
---@field lastY number | nil
---@field lastTimeMs integer | nil
---@field onPlayerUpdate fun(player: IsoPlayer) | nil
EffectRubberDuckSteps = ChaosEffectBase:derive("EffectRubberDuckSteps", "rubber_duck_steps")

---@param player IsoPlayer
function EffectRubberDuckSteps:HandlePlayerUpdate(player)
    if not player or player:isDead() then return end
    if not player:isPlayerMoving() then return end

    local sq = player:getCurrentSquare()
    if not sq then return end

    local isRunning = player:isRunning()

    local maxDelay = isRunning and MIN_DELAY_MS_RUN or MIN_DELAY_MS_WALK

    local now = getTimestampMs()
    if self.lastTimeMs and now - self.lastTimeMs < maxDelay then
        return
    end

    local px, py, pz = player:getX(), player:getY(), player:getZ()

    if self.lastX and self.lastY then
        local dx = px - self.lastX
        local dy = py - self.lastY
        if dx * dx + dy * dy < MIN_DISTANCE * MIN_DISTANCE then
            return
        end
    end

    self.lastX = px
    self.lastY = py
    self.lastTimeMs = now

    ChaosUtils.PlayUISound(SOUND_NAME, true, 0.5)

    getWorldSoundManager():addSound(
        player,
        math.floor(px),
        math.floor(py),
        math.floor(pz),
        ZOMBIE_HEARING_RADIUS,
        ZOMBIE_HEARING_VOLUME,
        false
    )
end

function EffectRubberDuckSteps:OnStart()
    ChaosEffectBase:OnStart()

    self.lastX = nil
    self.lastY = nil
    self.lastTimeMs = nil

    self.onPlayerUpdate = function(player)
        self:HandlePlayerUpdate(player)
    end

    Events.OnPlayerUpdate.Add(self.onPlayerUpdate)
end

---@param deltaMs integer
function EffectRubberDuckSteps:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectRubberDuckSteps:OnEnd()
    ChaosEffectBase:OnEnd()
    if self.onPlayerUpdate then
        Events.OnPlayerUpdate.Remove(self.onPlayerUpdate)
        self.onPlayerUpdate = nil
    end
end
