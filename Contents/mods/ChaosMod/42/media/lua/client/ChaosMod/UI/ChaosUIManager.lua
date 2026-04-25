---@class ChaosUIManager
---@field hud ChaosHUD
---@field effectsWindow ChaosEffectsWindow
---@field chaosEffectsUI ChaosEffectsUI
---@field cachedWidth number
---@field cachedHeight number
ChaosUIManager = ChaosUIManager or {
    hud = nil,
    effectsWindow = nil,
    chaosEffectsUI = nil,
    cachedWidth = 0,
    cachedHeight = 0,
}

function ChaosUIManager:Init()
    if self.hud then return end

    self.cachedWidth = getCore():getScreenWidth()
    self.cachedHeight = getCore():getScreenHeight()

    self.hud = ChaosHUD:new()
    self.hud:initialise()
    self.hud:addToUIManager()
    self.hud:setVisible(true)

    self.chaosEffectsUI = ChaosEffectsUI:new()
    self.chaosEffectsUI:initialise()
    self.chaosEffectsUI:addToUIManager()
    self.chaosEffectsUI:setVisible(false)

    print("[ChaosUIManager] Initialized")
    print("[ChaosUIManager] Screen width: " .. tostring(self.cachedWidth))
    print("[ChaosUIManager] Screen height: " .. tostring(self.cachedHeight))
end

---@param text string
function ChaosUIManager:SetMainText(text)
    if not self.hud then return end
    self.hud:addText(text)
end

---@param value number
---@return number
function ChaosUIManager.GetScaledWidth(value)
    local basicWidth = 1920
    return math.floor(value * (ChaosUIManager.cachedWidth / basicWidth))
end

---@param value number
---@return number
function ChaosUIManager.GetScaledHeight(value)
    local basicHeight = 1080
    return math.floor(value * (ChaosUIManager.cachedHeight / basicHeight))
end

function ChaosUIManager:ShowEffectsUI()
    if self.chaosEffectsUI then self.chaosEffectsUI:setVisible(true) end
end

function ChaosUIManager:HideEffectsUI()
    if self.chaosEffectsUI then self.chaosEffectsUI:setVisible(false) end
end

function ChaosUIManager:ToggleEffectsWindow()
    if self.effectsWindow and self.effectsWindow:getIsVisible() then
        self.effectsWindow:setVisible(false)
        self.effectsWindow:removeFromUIManager()
        return
    end

    local windowWidth = ChaosUIManager.GetScaledWidth(420)
    local windowHeight = ChaosUIManager.GetScaledHeight(420)
    local windowX = ChaosUIManager.GetScaledWidth(200)
    local windowY = ChaosUIManager.GetScaledHeight(120)

    self.effectsWindow = ChaosEffectsWindow:new(windowX, windowY, windowWidth, windowHeight)
    self.effectsWindow:initialise()
    self.effectsWindow:addToUIManager()
    self.effectsWindow:setVisible(true)
end
