require "ISUI/ISPanel"

---@class ChaosUFOAbductionHUD : ISPanel
---@field startTimeMs integer
---@field fadeDurationMs integer
ChaosUFOAbductionHUD = ISPanel:derive("ChaosUFOAbductionHUD")

local FADE_DURATION_MS = 3000
local POST_FADE_DELAY_MS = 4000
local TEXTURE_1_DURATION_MS = 1500
local TEXTURE_2_DURATION_MS = 1500

---@return ChaosUFOAbductionHUD
function ChaosUFOAbductionHUD:new()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local o = ISPanel:new(0, 0, screenW, screenH)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosUFOAbductionHUD

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false
    o.startTimeMs = getTimestampMs()
    o.fadeDurationMs = FADE_DURATION_MS

    o:backMost()

    return o
end

---@param texture Texture
---@param screenW integer
---@param screenH integer
function ChaosUFOAbductionHUD:drawCenteredTexture(texture, screenW, screenH)
    local tw = texture:getWidth()
    local th = texture:getHeight()
    if tw <= 0 or th <= 0 then return end

    local maxW = screenW * 0.4
    local maxH = screenH * 0.5
    local scale = math.min(maxW / tw, maxH / th, 1)
    local w = math.floor(tw * scale)
    local h = math.floor(th * scale)
    local x = math.floor((screenW - w) / 2)
    local y = math.floor((screenH - h) / 2)
    self:drawTextureScaledAspect(texture, x, y, w, h, 1, 1, 1, 1)
end

function ChaosUFOAbductionHUD:prerender()
    local elapsed = getTimestampMs() - self.startTimeMs
    local t = elapsed / self.fadeDurationMs
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    self:setWidth(screenW)
    self:setHeight(screenH)

    self:drawRect(0, 0, screenW, screenH, t, 0, 0, 0)
end

function ChaosUFOAbductionHUD:onMouseDown() end

function ChaosUFOAbductionHUD:onMouseUp() end
