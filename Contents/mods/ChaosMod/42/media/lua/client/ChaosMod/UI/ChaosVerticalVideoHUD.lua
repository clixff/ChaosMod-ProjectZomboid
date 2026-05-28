require "ISUI/ISPanel"

---@class ChaosVerticalVideoHUD : ISPanel
ChaosVerticalVideoHUD = ISPanel:derive("ChaosVerticalVideoHUD")

---@return ChaosVerticalVideoHUD
function ChaosVerticalVideoHUD:new()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local o = ISPanel:new(0, 0, screenW, screenH)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosVerticalVideoHUD

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false

    o:backMost()

    return o
end

function ChaosVerticalVideoHUD:initialise()
    ISPanel.initialise(self)

    if self.javaObject and self.javaObject.setConsumeMouseEvents then
        self.javaObject:setConsumeMouseEvents(false)
    end
end

function ChaosVerticalVideoHUD:prerender()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    self:setWidth(screenW)
    self:setHeight(screenH)

    local freeWidth = screenH * 0.5625
    local barWidth = math.floor((screenW - freeWidth) / 2)
    if barWidth <= 0 then return end

    self:drawRect(0, 0, barWidth, screenH, 1, 0, 0, 0)
    self:drawRect(screenW - barWidth, 0, barWidth, screenH, 1, 0, 0, 0)
end

function ChaosVerticalVideoHUD:render()
end

---@return boolean
function ChaosVerticalVideoHUD:onMouseDown(x, y)
    return false
end

---@return boolean
function ChaosVerticalVideoHUD:onMouseUp(x, y)
    return false
end

---@return boolean
function ChaosVerticalVideoHUD:onRightMouseDown(x, y)
    return false
end

---@return boolean
function ChaosVerticalVideoHUD:onRightMouseUp(x, y)
    return false
end

---@return boolean
function ChaosVerticalVideoHUD:onMouseWheel(del)
    return false
end
