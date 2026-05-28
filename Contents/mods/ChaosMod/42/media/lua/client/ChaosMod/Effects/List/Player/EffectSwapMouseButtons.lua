---@class EffectSwapMouseButtons : ChaosEffectBase
---@field savedBindings table<string, {key: integer, alt: integer}>
---@field savedUIMethods table<table, table<string, function>>
---@field savedWorldContextCreateMenu function
EffectSwapMouseButtons = ChaosEffectBase:derive("EffectSwapMouseButtons", "swap_mouse_buttons")

local SWAP_PAIRS = {
    { "Aim", "Attack/Click" },
}

local MOUSE_LEFT = 0
local MOUSE_RIGHT = 1
local KEY_MOUSE_RIGHT = 10001

local UI_CLASSES_TO_SWAP = {
    "ISInventoryPane",
}

local UI_MOUSE_METHOD_PAIRS = {
    { "onMouseDown", "onRightMouseDown" },
    { "onMouseUp", "onRightMouseUp" },
    { "onMouseDownOutside", "onRightMouseDownOutside" },
    { "onMouseUpOutside", "onRightMouseUpOutside" },
}

local RAW_NIL = {}

function EffectSwapMouseButtons:OnStart()
    ChaosEffectBase:OnStart()
    local core = getCore()

    self.savedBindings = {}
    for _, pair in ipairs(SWAP_PAIRS) do
        for _, name in ipairs(pair) do
            self.savedBindings[name] = {
                key = core:getKey(name),
                alt = core:getAltKey(name),
            }
        end
    end

    for _, pair in ipairs(SWAP_PAIRS) do
        local a, b = pair[1], pair[2]
        core:addKeyBinding(a, self.savedBindings[b].key, self.savedBindings[b].alt, false, false, false)
        core:addKeyBinding(b, self.savedBindings[a].key, self.savedBindings[a].alt, false, false, false)
    end

    -- RMB is special in the engine: it opens the world context menu immediately, but
    -- key bindings using RMB are delayed by Mouse.isRightDelay() (~0.15s).  This made
    -- quick swapped attacks open the context menu instead of attacking.  Handle the
    -- first RMB frame ourselves, then mark RMB as UI-captured so the delayed keybind
    -- path won't fire a duplicate attack while the button is held.
    self.onRightMouseDown = function(x, y) self:OnRightMouseDown(x, y) end
    Events.OnRightMouseDown.Add(self.onRightMouseDown)

    self:SwapUIMouseHandlers()
    self:DisableWorldContextMenuWhileAiming()
end

function EffectSwapMouseButtons:SwapUIMouseHandlers()
    self.savedUIMethods = {}

    for _, className in ipairs(UI_CLASSES_TO_SWAP) do
        local classTable = _G[className]
        if classTable then
            self.savedUIMethods[classTable] = {}
            for _, pair in ipairs(UI_MOUSE_METHOD_PAIRS) do
                local leftName, rightName = pair[1], pair[2]
                self.savedUIMethods[classTable][leftName] = rawget(classTable, leftName) or RAW_NIL
                self.savedUIMethods[classTable][rightName] = rawget(classTable, rightName) or RAW_NIL
                classTable[leftName], classTable[rightName] = classTable[rightName], classTable[leftName]
            end
        end
    end
end

function EffectSwapMouseButtons:RestoreUIMouseHandlers()
    if not self.savedUIMethods then return end

    for classTable, methods in pairs(self.savedUIMethods) do
        for methodName, method in pairs(methods) do
            classTable[methodName] = method ~= RAW_NIL and method or nil
        end
    end

    self.savedUIMethods = nil
end

function EffectSwapMouseButtons:DisableWorldContextMenuWhileAiming()
    if not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.createMenu then return end

    self.savedWorldContextCreateMenu = ISWorldObjectContextMenu.createMenu
    local originalCreateMenu = self.savedWorldContextCreateMenu

    ISWorldObjectContextMenu.createMenu = function(playerNum, worldobjects, x, y, test)
        local player = getSpecificPlayer(playerNum)
        if player and player:isAiming() then
            return nil
        end

        return originalCreateMenu(playerNum, worldobjects, x, y, test)
    end
end

function EffectSwapMouseButtons:RestoreWorldContextMenuWhileAiming()
    if self.savedWorldContextCreateMenu and ISWorldObjectContextMenu then
        ISWorldObjectContextMenu.createMenu = self.savedWorldContextCreateMenu
        self.savedWorldContextCreateMenu = nil
    end
end

function EffectSwapMouseButtons:OnRightMouseDown(_x, _y)
    if not self.savedBindings then return end

    local core = getCore()
    if core:getKey("Attack/Click") ~= KEY_MOUSE_RIGHT and core:getAltKey("Attack/Click") ~= KEY_MOUSE_RIGHT then
        return
    end

    local player = getPlayer()
    if not player then return end

    local shouldAttack = player:isAiming() or isMouseButtonDown(MOUSE_LEFT)

    -- UIManager checks player:isAiming() after firing OnRightMouseDown.  Setting it
    -- here prevents the world context menu from opening for this RMB press.
    player:setIsAiming(true)
    Mouse.UIBlockButtonDown(MOUSE_RIGHT)

    if shouldAttack then
        player:AttemptAttack()
    end
end

function EffectSwapMouseButtons:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.onRightMouseDown then
        Events.OnRightMouseDown.Remove(self.onRightMouseDown)
        self.onRightMouseDown = nil
    end

    self:RestoreUIMouseHandlers()
    self:RestoreWorldContextMenuWhileAiming()

    if not self.savedBindings then return end

    local core = getCore()
    for name, bind in pairs(self.savedBindings) do
        core:addKeyBinding(name, bind.key, bind.alt, false, false, false)
    end
    self.savedBindings = nil
end
