---@alias RollDicePhase "idle" | "rolling" | "revealing" | "completed"

---@class EffectRollDice : ChaosEffectBase
---@field listedEffectIds string[]
---@field rollDicePhase RollDicePhase
---@field rollEndMs integer
---@field revealEndMs integer
---@field nextDiceUpdateMs integer
---@field currentDiceFace integer
---@field winnerIndex integer | nil
---@field rollDiceWindow ChaosRollDiceWindow | nil
EffectRollDice = ChaosEffectBase:derive("EffectRollDice", "roll_dice")

local SELF_EFFECT_ID = "roll_dice"
local ROLL_DURATION_MS = 4000
local REVEAL_DURATION_MS = 3000
local DICE_FACE_INTERVAL_MS = 250

local SLOT_PRICE_GROUPS = {
    { "neutral_1", "neutral_2", "neutral_3", "neutral_4", "neutral_5", "neutral_6" },
    { "neutral_1", "neutral_2", "neutral_3", "neutral_4", "neutral_5", "neutral_6" },
    { "positive_1", "positive_2", "positive_3" },
    { "positive_4", "positive_5", "positive_6" },
    { "negative_1", "negative_2", "negative_3" },
    { "negative_4", "negative_5", "negative_6" },
}

---@param priceGroups string[]
---@param excludeIds table<string, boolean>
---@return string | nil
local function pickEffectByPriceGroups(priceGroups, excludeIds)
    local groupSet = {}
    for _, g in ipairs(priceGroups) do groupSet[g] = true end

    local pool = {}
    for id, effect in pairs(ChaosEffectsRegistry.effects) do
        if id ~= SELF_EFFECT_ID and effect.enabled and groupSet[effect.price_group] and not excludeIds[id] then
            table.insert(pool, id)
        end
    end

    if #pool == 0 then return nil end
    return pool[ChaosUtils.RandArrayIndex(pool)]
end

---@return string[]
local function generateSlotEffects()
    local result = {}
    local used = {}
    for i = 1, #SLOT_PRICE_GROUPS do
        local picked = pickEffectByPriceGroups(SLOT_PRICE_GROUPS[i], used)
        if picked then used[picked] = true end
        result[i] = picked
    end
    return result
end

function EffectRollDice:OnStart()
    ChaosEffectBase:OnStart()
    setGameSpeed(0)

    self.listedEffectIds = generateSlotEffects()
    self.rollDicePhase = "idle"
    self.rollEndMs = 0
    self.revealEndMs = 0
    self.nextDiceUpdateMs = 0
    self.currentDiceFace = 0
    self.winnerIndex = nil

    self.rollDiceWindow = ChaosRollDiceWindow:new(self, self.listedEffectIds)
    self.rollDiceWindow:initialise()
    self.rollDiceWindow:addToUIManager()
    self.rollDiceWindow:setVisible(true)
end

function EffectRollDice:onRollPressed()
    if self.rollDicePhase ~= "idle" then return end
    local now = getTimestampMs()
    self.rollDicePhase = "rolling"
    self.rollEndMs = now + ROLL_DURATION_MS
    self.nextDiceUpdateMs = now
    self.currentDiceFace = ChaosUtils.RandIntegerRange(1, 7)
end

---@return string | nil
function EffectRollDice:pickRandomFromList()
    local pool = {}
    if self.listedEffectIds then
        for _, id in ipairs(self.listedEffectIds) do
            if id then table.insert(pool, id) end
        end
    end
    if #pool == 0 then return nil end
    return pool[ChaosUtils.RandArrayIndex(pool)]
end

function EffectRollDice:closeWindow()
    if self.rollDiceWindow and not self.rollDiceWindow.resolved then
        self.rollDiceWindow.resolved = true
        self.rollDiceWindow:setVisible(false)
        self.rollDiceWindow:removeFromUIManager()
    end
    self.rollDiceWindow = nil
end

--- Drives the rolling/revealing state machine. Called from the UI window's
--- prerender so timing keeps advancing even while the game is paused via
--- setGameSpeed(0) — Events.OnTick does not fire reliably while paused.
function EffectRollDice:updateRollPhase()
    local now = getTimestampMs()

    if self.rollDicePhase == "rolling" then
        if now >= self.nextDiceUpdateMs then
            self.currentDiceFace = ChaosUtils.RandIntegerRange(1, 7)
            self.nextDiceUpdateMs = now + DICE_FACE_INTERVAL_MS
        end

        if now >= self.rollEndMs then
            local winner = ChaosUtils.RandIntegerRange(1, 7)
            self.winnerIndex = winner
            self.currentDiceFace = winner
            self.rollDicePhase = "revealing"
            self.revealEndMs = now + REVEAL_DURATION_MS
        end
        return
    end

    if self.rollDicePhase == "revealing" then
        if now >= self.revealEndMs then
            local winnerId = self.winnerIndex and self.listedEffectIds[self.winnerIndex] or nil
            if not winnerId then
                winnerId = self:pickRandomFromList()
            end

            self.rollDicePhase = "completed"
            self:closeWindow()
            setGameSpeed(1)

            if winnerId then
                ChaosEffectsManager.StartEffect(winnerId, self.effectNickname, self.activationType)
            end
            ChaosEffectsManager.DisableSpecificEffects({ SELF_EFFECT_ID })
        end
        return
    end
end

function EffectRollDice:OnEnd()
    ChaosEffectBase:OnEnd()
    setGameSpeed(1)

    if self.rollDicePhase ~= "completed" then
        local fallback = self:pickRandomFromList()
        self.rollDicePhase = "completed"
        if fallback then
            ChaosEffectsManager.StartEffect(fallback, self.effectNickname, self.activationType)
        end
    end

    self:closeWindow()
end
