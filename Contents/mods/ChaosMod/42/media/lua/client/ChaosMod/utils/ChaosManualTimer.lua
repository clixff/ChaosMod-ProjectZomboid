---@class ChaosManualTimer
---@field currentMs integer
---@field maxMs integer
ChaosManualTimer = {}
ChaosManualTimer.__index = ChaosManualTimer

---@param maxMs integer
---@return ChaosManualTimer
function ChaosManualTimer.new(maxMs)
    local o = setmetatable({}, ChaosManualTimer)
    o.currentMs = 0
    o.maxMs = maxMs or 0
    return o
end

---@param deltaMs integer
function ChaosManualTimer:add(deltaMs)
    self.currentMs = self.currentMs + deltaMs
end

---@return boolean
function ChaosManualTimer:isEnded()
    return self.currentMs >= self.maxMs
end

function ChaosManualTimer:reset()
    self.currentMs = 0
end

---@param maxMs integer
function ChaosManualTimer:setMax(maxMs)
    self.maxMs = maxMs
end
