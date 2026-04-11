require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"

---@class ChaosEffectsWindow : ISCollapsableWindow
---@field effects table<string, ChaosEffectDataEntry>
---@field selectedEffect ChaosEffectDataEntry | nil
ChaosEffectsWindow = ISCollapsableWindow:derive("ChaosEffectsWindow")

---@param x number
---@param y number
---@param w number
---@param h number
---@return ChaosEffectsWindow
function ChaosEffectsWindow:new(x, y, w, h)
    ---@type ChaosEffectsWindow
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.title = "Chaos Effects"
    o.resizable = false

    o.effects = {}
    o.selectedEffect = nil

    return o
end

function ChaosEffectsWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function ChaosEffectsWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = ChaosUIManager.GetScaledWidth(10)
    local btnH = ChaosUIManager.GetScaledWidth(28)
    local listY = ChaosUIManager.GetScaledWidth(30)
    local listW = self.width - pad * 2
    local listH = self.height - listY - pad - btnH - ChaosUIManager.GetScaledWidth(8)

    -- Scroll list
    self.list = ISScrollingListBox:new(pad, listY, listW, listH)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = ChaosUIManager.GetScaledWidth(22)
    self.list.drawBorder = true
    self.list.font = UIFont.NewSmall
    self.list.target = self
    self.list.onmousedown = ChaosEffectsWindow.onListMouseDown
    self.list.onmousedblclick = ChaosEffectsWindow.onEffectListDoubleClick

    self:addChild(self.list)

    -- Activate button (bottom)
    local btnY = listY + listH + 8
    self.btnActivate = ISButton:new(pad, btnY, listW, btnH, "Activate", self, ChaosEffectsWindow.onActivateClicked)
    self.btnActivate:initialise()
    self:addChild(self.btnActivate)

    self:fillWithEffects()
end

-- Called by ISScrollingListBox when you click an item.
-- In vanilla usage, listbox calls: onmousedown(target, clickedItemData, listbox)
--- @param target ChaosEffectDataEntry
--- @param item unknown
function ChaosEffectsWindow:onListMouseDown(target, item)
    self.selectedEffect = target
    print("[ChaosMod] Selected effect: " .. tostring(self.selectedEffect))
    print("[ChaosMod] Target: " .. tostring(target))
    print("[ChaosMod] Item: " .. tostring(item))
end

function ChaosEffectsWindow:fillWithEffects()
    self.list:clear()
    local firstEffectId = ""
    local i = 0
    for _, effectData in pairs(ChaosEffectsRegistry.effects) do
        i = i + 1
        local effectLineString = string.format("%d. %s", i, effectData.name)
        self.list:addItem(effectLineString, effectData)
        if firstEffectId == "" then
            firstEffectId = effectData.id
        end
    end

    if firstEffectId == "" then
        self.selectedEffect = nil
    else
        self.selectedEffect = ChaosEffectsRegistry.effects[firstEffectId]
    end
end

function ChaosEffectsWindow:onActivateClicked()
    print("[ChaosMod] Selected effect activated: " .. tostring(self.selectedEffect))
    if self.selectedEffect then
        print("[ChaosMod] Activate selected effect: " .. self.selectedEffect.id)

        ChaosEffectsManager.StartEffect(self.selectedEffect.id)
    end
end

--- @param target ChaosEffectDataEntry
--- @param item unknown
function ChaosEffectsWindow:onEffectListDoubleClick(target, item)
    self.selectedEffect = target
    print("[ChaosMod] Double clicked effect: " .. tostring(self.selectedEffect))
    print("[ChaosMod] Double clicked Target: " .. tostring(target))
    print("[ChaosMod] Double clicked Item: " .. tostring(item))
    self:onActivateClicked()
end
