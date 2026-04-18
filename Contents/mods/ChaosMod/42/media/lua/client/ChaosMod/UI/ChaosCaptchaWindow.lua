require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"

---@class ChaosCaptchaWindow : ISPanel
---@field effect EffectMathCaptcha
---@field question string
---@field startTimeMs integer
---@field durationMs integer
---@field resolved boolean
---@field answerEntry ISTextEntryBox
---@field submitBtn ISButton
ChaosCaptchaWindow = ISPanel:derive("ChaosCaptchaWindow")

local WINDOW_W = 420
local WINDOW_H = 220
local PAD = 24

---@param effect EffectMathCaptcha
---@param question string
---@return ChaosCaptchaWindow
function ChaosCaptchaWindow:new(effect, question)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - WINDOW_W) / 2)
    local y = math.floor((screenH - WINDOW_H) / 2)

    local o = ISPanel:new(x, y, WINDOW_W, WINDOW_H)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosCaptchaWindow

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.92 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.effect = effect
    o.question = question
    o.startTimeMs = getTimestampMs()
    o.durationMs = math.floor(effect.duration * 1000)
    o.resolved = false

    return o
end

function ChaosCaptchaWindow:createChildren()
    local entryY = 118
    local entryH = 32
    self.answerEntry = ISTextEntryBox:new("", PAD, entryY, WINDOW_W - PAD * 2, entryH)
    self.answerEntry.font = UIFont.NewLarge
    self.answerEntry:initialise()
    self.answerEntry:instantiate()
    self:addChild(self.answerEntry)

    local btnY = entryY + entryH + 12
    local btnH = 36
    self.submitBtn = ISButton:new(PAD, btnY, WINDOW_W - PAD * 2, btnH, "Submit", self,
        ChaosCaptchaWindow.onSubmit)
    self.submitBtn:initialise()
    self.submitBtn:instantiate()
    self:addChild(self.submitBtn)
end

function ChaosCaptchaWindow:prerender()
    ISPanel.prerender(self)

    local elapsed = getTimestampMs() - self.startTimeMs

    if not self.resolved and elapsed >= self.durationMs then
        self:onTimeUp()
        return
    end

    local remaining = math.max(0.0, (self.durationMs - elapsed) / 1000.0)

    -- Question
    local qX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.Large, self.question)) / 2)
    self:drawText(self.question, qX, 18, 1, 1, 1, 1, UIFont.Large)

    -- Timer
    local timerText = string.format("%.1fs remaining", remaining)
    local timerR, timerG = 1.0, 1.0
    if remaining < 5 then
        timerR, timerG = 1.0, 0.2
    elseif remaining < 10 then
        timerR, timerG = 1.0, 0.6
    end
    local timerX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.NewSmall, timerText)) / 2)
    self:drawText(timerText, timerX, 76, timerR, timerG, 0.2, 1, UIFont.NewSmall)
end

function ChaosCaptchaWindow.onSubmit(self)
    if self.resolved then return end

    local text = self.answerEntry:getInternalText()
    local userAnswer = tonumber(text)

    if userAnswer ~= nil and userAnswer == self.effect.answer then
        self.effect:applyCorrectAnswer()
    else
        self.effect:applyWrongAnswer()
    end

    self:resolve()
end

function ChaosCaptchaWindow:onTimeUp()
    if self.resolved then return end
    self.effect:applyWrongAnswer()
    self:resolve()
end

function ChaosCaptchaWindow:resolve()
    if self.resolved then return end
    self.resolved = true

    setGameSpeed(1)

    self:setVisible(false)
    self:removeFromUIManager()

    ChaosEffectsManager.DisableSpecificEffects({ "math_captcha" })
end
