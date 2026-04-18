require "ISUI/ISPanel"
require "ISUI/ISButton"
---@class ChaosHUD : ISPanel
---@field toasts table<string, string>
---@field text string
---@field btn ISButton
ChaosHUD = ISPanel:derive("ChaosHUD")

function ChaosHUD:initialise()
    ISPanel.initialise(self)
    self.text = "Test String"
end

function ChaosHUD:new()
    local panelWidth = ChaosUIManager.GetScaledWidth(500)
    local panelHeight = ChaosUIManager.GetScaledWidth(300)
    local panelX = ChaosUIManager.GetScaledWidth(1300)
    local panelY = ChaosUIManager.GetScaledHeight(50)
    local o = ISPanel:new(panelX, panelY, panelWidth, panelHeight)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.anchorLeft = true
    o.anchorTop = true

    return o
end

function ChaosHUD:createChildren()
    -- Button belongs to THIS instance (self)
    local buttonWidth = ChaosUIManager.GetScaledWidth(120)
    local buttonHeight = ChaosUIManager.GetScaledWidth(25)
    local buttonX = ChaosUIManager.GetScaledWidth(10)
    local buttonY = ChaosUIManager.GetScaledHeight(50)
    self.btn = ISButton:new(buttonX, buttonY, buttonWidth, buttonHeight, "Button", self, ChaosHUD.OnMainButtonClick)
    self.btn:initialise()
    self.btn:instantiate()
    self:addChild(self.btn)
    self:OnModStatusChanged(ChaosMod.enabled)

    local secondButtonWidth = ChaosUIManager.GetScaledWidth(100)
    local secondButtonHeight = ChaosUIManager.GetScaledWidth(25)
    local secondButtonX = buttonWidth + ChaosUIManager.GetScaledWidth(10)
    local secondButtonY = ChaosUIManager.GetScaledHeight(50)

    self.secondBtn = ISButton:new(secondButtonX, secondButtonY, secondButtonWidth, secondButtonHeight, ChaosLocalization.GetString("core", "select_effect"),
        self,
        ChaosHUD.OnSecondButtonClick)
    self.secondBtn:initialise()
    self.secondBtn:instantiate()
    self:addChild(self.secondBtn)
end

---@param text string
function ChaosHUD:addText(text)
    self.text = text
end

function ChaosHUD:prerender()
    ISPanel.prerender(self)

    -- Draw text
    self:drawText(self.text, 0, 0, 1, 1, 1, 1, UIFont.Large)

    -- Draw active effects name
    local effectHeight = ChaosUIManager.GetScaledWidth(20)
    local baseEffectY = ChaosUIManager.GetScaledHeight(200);
    for i, effect in ipairs(ChaosEffectsManager.activeEffects) do
        local effectString = tostring(effect.effectName)
        if effect.withDuration then
            local msToEnd = effect.maxTicks - effect.ticksActiveTime
            local secondsToEnd = msToEnd / 1000
            effectString = string.format("%s (%.1fs)", effectString, secondsToEnd)
        end
        self:drawText(effectString, 0, baseEffectY + (i * effectHeight), 1, 1, 1, 1, UIFont.NewLarge)
    end

    -- local fontsTest = {
    --     "Small",
    --     "Medium",
    --     "Large",
    --     "Massive",
    --     "MainMenu1",
    --     "MainMenu2",
    --     "Cred1",
    --     "Cred2",
    --     "NewSmall",
    --     "NewMedium",
    --     "NewLarge",
    --     "Code",
    --     "CodeSmall",
    --     "CodeMedium",
    --     "CodeLarge",
    --     "MediumNew",
    --     "AutoNormSmall",
    --     "AutoNormMedium",
    --     "AutoNormLarge",
    --     "Dialogue",
    --     "Intro",
    --     "Handwritten",
    --     "DebugConsole",
    --     "Title",
    --     "SdfRegular",
    --     "SdfBold",
    --     "SdfItalic",
    --     "SdfBoldItalic",
    --     "SdfOldRegular",
    --     "SdfOldBold",
    --     "SdfOldItalic",
    --     "SdfOldBoldItalic",
    --     "SdfRobertoSans",
    --     "SdfCaveat",
    -- }

    -- local i = 0
    -- for i, fontName in pairs(fontsTest) do
    --     self:drawText(fontName, -200, 0 + (i * 40), 1, 1, 1, 1, UIFont[fontName])
    -- end
end

function ChaosHUD:OnMainButtonClick()
    print("Main button clicked")
    if ChaosMod.enabled then
        ChaosMod.StopMod()
    else
        ChaosMod.StartMod()
    end
end

---@param enabled boolean
function ChaosHUD:OnModStatusChanged(enabled)
    if enabled then
        self.btn:setTitle(ChaosLocalization.GetString("core", "stop_mod"))
        self.btn:enableCancelColor()
    else
        self.btn:setTitle(ChaosLocalization.GetString("core", "start_mod"))
        self.btn:enableAcceptColor()
    end

    local buttonWidth = ChaosUIManager.GetScaledWidth(120)
    self.btn:setWidthToTitle(buttonWidth)
end

function ChaosHUD:OnLanguageLoaded()
    self.secondBtn:setTitle(ChaosLocalization.GetString("core", "select_effect"))
    self:OnModStatusChanged(ChaosMod.enabled)
end

function ChaosHUD:OnSecondButtonClick()
    print("Second button clicked")
    ChaosUIManager:ToggleEffectsWindow()
end
