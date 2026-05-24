require "ISUI/ISPanel"

---@class ChaosHeadsackHUD : ISPanel
ChaosHeadsackHUD = ISPanel:derive("ChaosHeadsackHUD")

---@return ChaosHeadsackHUD
function ChaosHeadsackHUD:new()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local o = ISPanel:new(0, 0, 0, 0)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosHeadsackHUD

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false

    o:backMost()

    return o
end

function ChaosHeadsackHUD:initialise()
    ISPanel.initialise(self)

    if self.javaObject and self.javaObject.setConsumeMouseEvents then
        self.javaObject:setConsumeMouseEvents(false)
    end
end

function ChaosHeadsackHUD:prerender()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local texture = getTexture("media/ui/chaos_headsack.png")
    if not texture then return end

    local tw = texture:getWidth()
    local th = texture:getHeight()
    if tw <= 0 or th <= 0 then return end

    local scale = math.max(screenW / tw, screenH / th)
    local w = math.floor(tw * scale)
    local h = math.floor(th * scale)
    local x = math.floor((screenW - w) / 2)
    local y = math.floor((screenH - h) / 2)
    self:drawTextureScaled(texture, x, y, w, h, 0.98, 1, 1, 1)
end

function ChaosHeadsackHUD:render()
end
