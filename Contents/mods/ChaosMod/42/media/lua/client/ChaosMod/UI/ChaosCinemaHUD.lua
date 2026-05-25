require "ISUI/ISPanel"

---@class ChaosCinemaHUD : ISPanel
ChaosCinemaHUD = ISPanel:derive("ChaosCinemaHUD")

---@return ChaosCinemaHUD
function ChaosCinemaHUD:new()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local o = ISPanel:new(0, 0, screenW, screenH)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosCinemaHUD

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false

    o:backMost()

    return o
end

function ChaosCinemaHUD:initialise()
    ISPanel.initialise(self)

    if self.javaObject and self.javaObject.setConsumeMouseEvents then
        self.javaObject:setConsumeMouseEvents(false)
    end
end

function ChaosCinemaHUD:prerender()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    self:setWidth(screenW)
    self:setHeight(screenH)

    local barHeight = math.floor(((screenH - (screenW / 2.4)) / 2.0) * 1.5)
    if barHeight <= 0 then return end

    self:drawRect(0, 0, screenW, barHeight, 1, 0, 0, 0)
    self:drawRect(0, screenH - barHeight, screenW, barHeight, 1, 0, 0, 0)
end

function ChaosCinemaHUD:render()
end

---@return boolean
function ChaosCinemaHUD:onMouseDown(x, y)
    return false
end

---@return boolean
function ChaosCinemaHUD:onMouseUp(x, y)
    return false
end

---@return boolean
function ChaosCinemaHUD:onRightMouseDown(x, y)
    return false
end

---@return boolean
function ChaosCinemaHUD:onRightMouseUp(x, y)
    return false
end

---@return boolean
function ChaosCinemaHUD:onMouseWheel(del)
    return false
end
