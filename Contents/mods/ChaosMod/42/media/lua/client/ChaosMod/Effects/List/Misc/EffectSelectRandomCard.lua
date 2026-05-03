---@class EffectSelectRandomCard : ChaosCardSelectEffect
---@field cardEffectIds string[]
---@field listedEffectIds string[]
---@field revealEndTimeMs integer | nil
---@field selectedCardIndex integer | nil
---@field selectedEffectId string | nil
---@field selectRandomCardWindow ChaosSelectRandomCardWindow | nil
EffectSelectRandomCard = ChaosEffectBase:derive("EffectSelectRandomCard", "select_random_card")

---@param values string[]
---@return string[]
local function shuffleCopy(values)
    local result = {}
    for i = 1, #values do
        result[i] = values[i]
    end

    for i = #result, 2, -1 do
        local j = ZombRand(i) + 1
        result[i], result[j] = result[j], result[i]
    end

    return result
end

function EffectSelectRandomCard:activateRandomCardEffect()
    if self.selectedEffectId then return end
    if not self.cardEffectIds or #self.cardEffectIds == 0 then return end

    local randomIndex = ChaosUtils.RandArrayIndex(self.cardEffectIds)
    local effectId = self.cardEffectIds[randomIndex]
    if not effectId then return end

    self.selectedCardIndex = randomIndex
    self.selectedEffectId = effectId
    ChaosEffectsManager.StartEffect(effectId)
end

function EffectSelectRandomCard:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSelectRandomCard] OnStart")

    setGameSpeed(0)

    self.listedEffectIds = ChaosEffectsRegistry.GetRandomEffects(3, "default")
    self.cardEffectIds = shuffleCopy(self.listedEffectIds)
    self.revealEndTimeMs = nil
    self.selectedCardIndex = nil
    self.selectedEffectId = nil

    self.selectRandomCardWindow = ChaosSelectRandomCardWindow:new(self, self.listedEffectIds, self.cardEffectIds)
    self.selectRandomCardWindow:initialise()
    self.selectRandomCardWindow:addToUIManager()
    self.selectRandomCardWindow:setVisible(true)
end

---@param cardIndex integer
function EffectSelectRandomCard:onCardSelected(cardIndex)
    if self.selectedCardIndex then return end
    if not self.cardEffectIds or not self.cardEffectIds[cardIndex] then return end

    self.selectedCardIndex = cardIndex
    self.selectedEffectId = self.cardEffectIds[cardIndex]
    self.revealEndTimeMs = getTimestampMs() + 3000

    setGameSpeed(1)

    ChaosEffectsManager.StartEffect(self.selectedEffectId)
end

---@param deltaMs integer
function EffectSelectRandomCard:OnTick(deltaMs)
    if not self.selectedEffectId and (self.ticksActiveTime + deltaMs) >= self.maxTicks then
        self:activateRandomCardEffect()
        return
    end

    if not self.revealEndTimeMs then
        return
    end

    if getTimestampMs() >= self.revealEndTimeMs then
        ChaosEffectsManager.DisableSpecificEffects({ "select_random_card" })
    end
end

function EffectSelectRandomCard:OnEnd()
    setGameSpeed(1)

    if self.selectRandomCardWindow and not self.selectRandomCardWindow.resolved then
        self.selectRandomCardWindow.resolved = true
        self.selectRandomCardWindow:setVisible(false)
        self.selectRandomCardWindow:removeFromUIManager()
    end
    self.selectRandomCardWindow = nil
end
