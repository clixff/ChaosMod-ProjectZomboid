require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"

---@class ChaosRememberCodeWindow : ISPanel
---@field effect EffectRememberCode
---@field code string
---@field startTimeMs integer
---@field durationMs integer
---@field revealDurationMs integer
---@field resolved boolean
---@field isCodeHidden boolean
---@field answerEntry ISTextEntryBox
---@field submitBtn ISButton
ChaosRememberCodeWindow = ISPanel:derive("ChaosRememberCodeWindow")

local WINDOW_W = 420
local WINDOW_H = 220
local PAD = 24

---@param effect EffectRememberCode
---@param code string
---@return ChaosRememberCodeWindow
function ChaosRememberCodeWindow:new(effect, code)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - WINDOW_W) / 2)
    local y = math.floor((screenH - WINDOW_H) / 2)

    local o = ISPanel:new(x, y, WINDOW_W, WINDOW_H)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosRememberCodeWindow

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.92 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.effect = effect
    o.code = code
    o.startTimeMs = getTimestampMs()
    o.durationMs = math.floor(effect.duration * 1000)
    o.revealDurationMs = 2900
    o.resolved = false
    o.isCodeHidden = false

    return o
end

function ChaosRememberCodeWindow:createChildren()
    local entryY = 118
    local entryH = 32
    self.answerEntry = ISTextEntryBox:new("", PAD, entryY, WINDOW_W - PAD * 2, entryH)
    self.answerEntry.font = UIFont.NewLarge
    self.answerEntry:initialise()
    self.answerEntry:instantiate()
    self.answerEntry:setVisible(false)
    self:addChild(self.answerEntry)

    local btnY = entryY + entryH + 12
    local btnH = 36
    self.submitBtn = ISButton:new(PAD, btnY, WINDOW_W - PAD * 2, btnH, "Submit", self,
        ChaosRememberCodeWindow.onSubmit)
    self.submitBtn:initialise()
    self.submitBtn:instantiate()
    self.submitBtn:setVisible(false)
    self:addChild(self.submitBtn)
end

function ChaosRememberCodeWindow:prerender()
    ISPanel.prerender(self)

    local elapsed = getTimestampMs() - self.startTimeMs

    if not self.resolved and elapsed >= self.durationMs then
        self:onTimeUp()
        return
    end

    if not self.isCodeHidden and elapsed >= self.revealDurationMs then
        self.isCodeHidden = true
        self.answerEntry:setVisible(true)
        self.submitBtn:setVisible(true)
    end

    local remaining = math.max(0.0, (self.durationMs - elapsed) / 1000.0)

    local title = self.isCodeHidden and "Repeat the code" or "Remember this code"
    local titleX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.Large, title)) / 2)
    self:drawText(title, titleX, 18, 1, 1, 1, 1, UIFont.Large)

    local displayCode = self.isCodeHidden and "? ? ? ? ? ?" or table.concat({
        string.sub(self.code, 1, 1),
        string.sub(self.code, 2, 2),
        string.sub(self.code, 3, 3),
        string.sub(self.code, 4, 4),
        string.sub(self.code, 5, 5),
        string.sub(self.code, 6, 6),
    }, " ")
    local codeX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.NewLarge, displayCode)) / 2)
    self:drawText(displayCode, codeX, 62, 1, 1, 1, 1, UIFont.NewLarge)

    local timerText = string.format("%.1fs remaining", remaining)
    local timerR, timerG = 1.0, 1.0
    if remaining < 5 then
        timerR, timerG = 1.0, 0.2
    elseif remaining < 10 then
        timerR, timerG = 1.0, 0.6
    end
    local timerX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.NewSmall, timerText)) / 2)
    self:drawText(timerText, timerX, 92, timerR, timerG, 0.2, 1, UIFont.NewSmall)
end

function ChaosRememberCodeWindow.onSubmit(self)
    if self.resolved then return end

    local text = self.answerEntry:getInternalText() or ""
    local userAnswer = string.gsub(text, "%s+", "")

    if userAnswer == self.effect.code then
        self.effect:applyCorrectAnswer()
    else
        self.effect:applyWrongAnswer()
    end

    self:resolve()
end

function ChaosRememberCodeWindow:onTimeUp()
    if self.resolved then return end
    self.effect:applyWrongAnswer()
    self:resolve()
end

function ChaosRememberCodeWindow:resolve()
    if self.resolved then return end
    self.resolved = true

    setGameSpeed(1)

    self:setVisible(false)
    self:removeFromUIManager()

    ChaosEffectsManager.DisableSpecificEffects({ "remember_code" })
end
