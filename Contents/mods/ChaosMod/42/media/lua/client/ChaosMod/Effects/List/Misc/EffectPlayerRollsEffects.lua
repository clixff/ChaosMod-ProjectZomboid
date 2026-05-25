---@class EffectPlayerRollsEffects : ChaosEffectBase
---@field rolledEffectId string | nil
---@field selectedEffectId string | nil
---@field rerollsLeft integer
---@field startTimeMs integer
---@field window ChaosPlayerRollsEffectsWindow | nil
EffectPlayerRollsEffects = ChaosEffectBase:derive("EffectPlayerRollsEffects", "player_rolls_effects")

local SELF_EFFECT_ID = "player_rolls_effects"
local INITIAL_REROLLS = 10
local PICK_RETRY_LIMIT = 5

---@return string | nil
function EffectPlayerRollsEffects:pickRandomEffectId()
    for _ = 1, PICK_RETRY_LIMIT do
        local ids = ChaosEffectsRegistry.GetRandomEffects(1, "default", false)
        if ids and ids[1] and ids[1] ~= SELF_EFFECT_ID then
            return ids[1]
        end
    end
    return nil
end

function EffectPlayerRollsEffects:OnStart()
    ChaosEffectBase:OnStart()
    setGameSpeed(0)

    self.rolledEffectId = nil
    self.selectedEffectId = nil
    self.rerollsLeft = INITIAL_REROLLS
    self.startTimeMs = getTimestampMs()

    self.window = ChaosPlayerRollsEffectsWindow:new(self)
    self.window:initialise()
    self.window:addToUIManager()
    self.window:setVisible(true)
end

function EffectPlayerRollsEffects:onRollPressed()
    if self.selectedEffectId then return end
    if self.rerollsLeft <= 0 then return end

    local nextId = self:pickRandomEffectId()
    if not nextId then return end

    self.rolledEffectId = nextId
    self.rerollsLeft = self.rerollsLeft - 1
end

function EffectPlayerRollsEffects:onActivatePressed()
    if self.selectedEffectId then return end
    if not self.rolledEffectId then return end

    self.selectedEffectId = self.rolledEffectId
    ChaosEffectsManager.DisableSpecificEffects({ SELF_EFFECT_ID })
end

--- Drives expiry from the window's prerender so the 60s timeout fires even while
--- the game is paused via setGameSpeed(0) — Events.OnTick does not advance reliably
--- in that state.
function EffectPlayerRollsEffects:tickExpiry()
    if self.selectedEffectId then return end
    local maxMs = math.floor((self.duration or 0) * 1000)
    if maxMs <= 0 then return end

    local elapsed = getTimestampMs() - (self.startTimeMs or 0)
    if elapsed >= maxMs then
        self.selectedEffectId = self.rolledEffectId or self:pickRandomEffectId()
        ChaosEffectsManager.DisableSpecificEffects({ SELF_EFFECT_ID })
    end
end

---@param deltaMs integer
function EffectPlayerRollsEffects:OnTick(deltaMs)
end

function EffectPlayerRollsEffects:closeWindow()
    if self.window and not self.window.resolved then
        self.window.resolved = true
        self.window:setVisible(false)
        self.window:removeFromUIManager()
    end
    self.window = nil
end

function EffectPlayerRollsEffects:OnEnd()
    ChaosEffectBase:OnEnd()
    self:closeWindow()
    setGameSpeed(1)

    local activateId = self.selectedEffectId or self.rolledEffectId
    if not activateId then
        activateId = self:pickRandomEffectId()
    end

    if activateId then
        ChaosEffectsManager.StartEffect(activateId, self.effectNickname, self.activationType)
    end
end
