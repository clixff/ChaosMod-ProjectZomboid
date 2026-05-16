require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class ChaosModalWindowButton
---@field label string
---@field onClick fun(window: ChaosModalWindow)
---@field accent string? -- "accept" → green styling like the in-game Start button. Default: neutral.

---@class ChaosModalWindow : ISPanel
---@field category string -- Category key used for replacement and shown-tracking
---@field priority integer -- Higher priority replaces lower, never the reverse
---@field title string
---@field bodyLines string[]
---@field buttons ChaosModalWindowButton[]
---@field buttonIndexByName table<string, integer>
---@field onCloseCallback fun(window: ChaosModalWindow)?
---@field paused boolean
ChaosModalWindow = ISPanel:derive("ChaosModalWindow")

ChaosModalWindow.current = nil ---@type ChaosModalWindow | nil

local MIN_WINDOW_W = 360
local MAX_WINDOW_W = 1000
local PAD_X = 28
local TITLE_TOP = 22
local TITLE_BODY_GAP = 28
local BODY_LINE_H = 24
local BODY_BUTTONS_GAP = 28
local BTN_H = 40
local BTN_GAP = 16
local BTN_PAD_X = 24
local BTN_MIN_W = 140
local BTN_BOTTOM_PAD = 24

---@param text string
---@return string[]
local function splitLines(text)
    local lines = {}
    if type(text) ~= "string" then return lines end
    local start = 1
    while true do
        local nlPos = string.find(text, "\n", start, true)
        if not nlPos then
            table.insert(lines, string.sub(text, start))
            break
        end
        table.insert(lines, string.sub(text, start, nlPos - 1))
        start = nlPos + 1
    end
    return lines
end

---@param title string
---@param bodyLines string[]
---@param buttonCount integer
---@return integer
local function computeHeight(title, bodyLines, buttonCount)
    local height = TITLE_TOP + getTextManager():getFontHeight(UIFont.Large) + TITLE_BODY_GAP
    height = height + math.max(1, #bodyLines) * BODY_LINE_H
    height = height + BODY_BUTTONS_GAP
    if buttonCount > 0 then
        height = height + BTN_H
    end
    height = height + BTN_BOTTOM_PAD
    return height
end

---@param label string
---@return integer
local function buttonWidthFor(label)
    local textW = getTextManager():MeasureStringX(UIFont.Medium, label or "")
    return math.max(BTN_MIN_W, textW + BTN_PAD_X * 2)
end

---@param title string
---@param bodyLines string[]
---@param buttons ChaosModalWindowButton[]
---@return integer
local function computeWidth(title, bodyLines, buttons)
    local maxContent = getTextManager():MeasureStringX(UIFont.Large, title or "")
    for i = 1, #bodyLines do
        local w = getTextManager():MeasureStringX(UIFont.Medium, bodyLines[i] or "")
        if w > maxContent then maxContent = w end
    end

    local btnRowW = 0
    for i = 1, #buttons do
        local def = buttons[i]
        if def then
            btnRowW = btnRowW + buttonWidthFor(def.label or "")
            if i > 1 then btnRowW = btnRowW + BTN_GAP end
        end
    end

    local needed = math.max(maxContent, btnRowW) + PAD_X * 2
    if needed < MIN_WINDOW_W then needed = MIN_WINDOW_W end
    if needed > MAX_WINDOW_W then needed = MAX_WINDOW_W end
    return needed
end

---@class ChaosModalWindowOpts
---@field category string
---@field priority integer
---@field title string
---@field body string
---@field buttons ChaosModalWindowButton[]
---@field onClose fun(window: ChaosModalWindow)? -- Called when window closes by any path

---@param opts ChaosModalWindowOpts
---@return ChaosModalWindow
function ChaosModalWindow:new(opts)
    local bodyLines = splitLines(opts.body or "")
    local buttons = opts.buttons or {}
    local width = computeWidth(opts.title or "", bodyLines, buttons)
    local height = computeHeight(opts.title or "", bodyLines, #buttons)

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosModalWindow

    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.category = opts.category or "default"
    o.priority = opts.priority or 0
    o.title = opts.title or ""
    o.bodyLines = bodyLines
    o.buttons = buttons
    o.buttonIndexByName = {}
    o.onCloseCallback = opts.onClose
    o.paused = false

    return o
end

function ChaosModalWindow:createChildren()
    local count = #self.buttons
    if count == 0 then return end

    local titleH = getTextManager():getFontHeight(UIFont.Large)
    local bodyH = math.max(1, #self.bodyLines) * BODY_LINE_H
    local btnY = TITLE_TOP + titleH + TITLE_BODY_GAP + bodyH + BODY_BUTTONS_GAP

    local btnWidths = {}
    local totalBtnW = 0
    for i = 1, count do
        local def = self.buttons[i]
        local w = def and buttonWidthFor(def.label or "") or BTN_MIN_W
        btnWidths[i] = w
        totalBtnW = totalBtnW + w
        if i > 1 then totalBtnW = totalBtnW + BTN_GAP end
    end

    local cursorX = math.floor((self.width - totalBtnW) / 2)

    for i = 1, count do
        local def = self.buttons[i]
        local w = btnWidths[i] or BTN_MIN_W
        if def then
            local internalName = "CHAOS_MODAL_BTN_" .. tostring(i)
            local btn = ISButton:new(cursorX, btnY, w, BTN_H, def.label or "", self,
                ChaosModalWindow.onButtonClicked)
            btn:initialise()
            btn:instantiate()
            btn.internal = internalName
            if def.accent == "accept" then
                btn:enableAcceptColor()
            end
            self.buttonIndexByName[internalName] = i
            self:addChild(btn)
            cursorX = cursorX + w + BTN_GAP
        end
    end
end

function ChaosModalWindow:prerender()
    ISPanel.prerender(self)

    if self.title and self.title ~= "" then
        local titleX = math.floor((self.width - getTextManager():MeasureStringX(UIFont.Large, self.title)) / 2)
        self:drawText(self.title, titleX, TITLE_TOP, 1, 1, 1, 1, UIFont.Large)
    end

    local titleH = getTextManager():getFontHeight(UIFont.Large)
    local bodyY = TITLE_TOP + titleH + TITLE_BODY_GAP

    for i = 1, #self.bodyLines do
        local line = self.bodyLines[i] or ""
        local lineX = math.floor((self.width - getTextManager():MeasureStringX(UIFont.Medium, line)) / 2)
        self:drawText(line, lineX, bodyY + (i - 1) * BODY_LINE_H, 0.9, 0.9, 0.9, 1, UIFont.Medium)
    end
end

---@param button ISButton
function ChaosModalWindow.onButtonClicked(self, button)
    local idx = self.buttonIndexByName[button.internal]
    if not idx then return end
    local def = self.buttons[idx]
    if def and def.onClick then
        def.onClick(self)
    end
end

--- Closes this window and restores game speed if it was paused on open.
function ChaosModalWindow:closeWindow()
    if ChaosModalWindow.current == self then
        ChaosModalWindow.current = nil
    end
    if self.paused then
        self.paused = false
        setGameSpeed(1)
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if self.onCloseCallback then
        local cb = self.onCloseCallback
        self.onCloseCallback = nil
        cb(self)
    end
end

--- Opens a modal. Replaces the current modal only when newOpts.priority >= current.priority.
--- When replacement happens, the replaced modal's onClose callback fires as usual.
---@param opts ChaosModalWindowOpts
---@return ChaosModalWindow? -- Returns the opened modal, or nil if dropped due to lower priority
function ChaosModalWindow.Open(opts)
    local current = ChaosModalWindow.current
    if current then
        if (opts.priority or 0) < current.priority then
            return nil
        end
        current:closeWindow()
    end

    local window = ChaosModalWindow:new(opts)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:setVisible(true)

    if not window.paused then
        window.paused = true
        setGameSpeed(0)
    end

    ChaosModalWindow.current = window
    return window
end

--- Returns the category key of the currently-open modal, or nil if none.
---@return string?
function ChaosModalWindow.CurrentCategory()
    return ChaosModalWindow.current and ChaosModalWindow.current.category or nil
end

--- Closes the open modal if its category matches `category`. No-op otherwise.
---@param category string
function ChaosModalWindow.CloseIfCategory(category)
    local current = ChaosModalWindow.current
    if current and current.category == category then
        current:closeWindow()
    end
end
