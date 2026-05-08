require "ISUI/ISPanel"

---@class ChaosSettingsEffectDetail : ISPanel
---@field parentWindow ChaosSettingsWindow
---@field currentId string | nil
---@field controls table
ChaosSettingsEffectDetail = ISPanel:derive("ChaosSettingsEffectDetail")

---@type ChaosSettingsWidgets
local W = setmetatable({}, { __index = function(_, k) return ChaosSettingsWidgets[k] end })

---@param x number
---@param y number
---@param w number
---@param h number
---@param parentWindow ChaosSettingsWindow
---@return ChaosSettingsEffectDetail
function ChaosSettingsEffectDetail:new(x, y, w, h, parentWindow)
    ---@type ChaosSettingsEffectDetail
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.parentWindow = parentWindow
    o.currentId = nil
    o.controls = {}
    o.background = true
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.3 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.15 }
    return o
end

function ChaosSettingsEffectDetail:initialise()
    ISPanel.initialise(self)
end

function ChaosSettingsEffectDetail:createChildren()
    ISPanel.createChildren(self)
end

---Reads typed values into workingEffects[currentId].
function ChaosSettingsEffectDetail:CommitWorkingState()
    if not self.currentId then return end
    local effect = self.parentWindow.workingEffects[self.currentId]
    if not effect then return end
    if self.controls.chance then
        effect.chance = math.floor(W.Clamp(W.GetIntFromBox(self.controls.chance, effect.chance or 0), 0, 100))
    end
    if self.controls.duration and effect.withDuration then
        effect.duration = math.floor(math.max(0, W.GetIntFromBox(self.controls.duration, effect.duration or 0)))
    end
end

function ChaosSettingsEffectDetail:RefreshFromWorkingState()
    if self.currentId then
        self:LoadEffect(self.currentId)
    end
end

local function clearChildren(panel)
    if not panel.children then return end
    -- Iterate keys in a snapshot since removeChild mutates the table
    local toRemove = {}
    for _, child in pairs(panel.children) do
        table.insert(toRemove, child)
    end
    for _, child in ipairs(toRemove) do
        panel:removeChild(child)
    end
end

---@param id string | nil
function ChaosSettingsEffectDetail:LoadEffect(id)
    -- Persist any in-flight changes for the previously displayed effect first
    self:CommitWorkingState()

    clearChildren(self)
    self.controls = {}
    self.currentId = id
    if not id then return end

    local effect = self.parentWindow.workingEffects[id]
    if not effect then return end

    local pad = ChaosUIManager.GetScaledWidth(10)
    local rowH = ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT)
    local rowGap = ChaosUIManager.GetScaledWidth(W.ROW_GAP)
    local labelW = ChaosUIManager.GetScaledWidth(180)
    local controlW = math.min(self.width - pad * 3 - labelW, ChaosUIManager.GetScaledWidth(220))
    if controlW < ChaosUIManager.GetScaledWidth(60) then
        controlW = ChaosUIManager.GetScaledWidth(60)
    end
    local labelX = pad
    local controlX = pad + labelW + pad

    -- Header line: localized name + id + index
    local localizedName = ChaosLocalization.GetString("effects", id) or id
    local indexInOrder = 0
    for i, oid in ipairs(self.parentWindow.workingEffectOrder) do
        if oid == id then
            indexInOrder = i
            break
        end
    end
    local headerText = string.format("%s   |   %s: %s   |   %s: %d",
        localizedName,
        ChaosLocalization.GetString("settings", "effect_id"), id,
        ChaosLocalization.GetString("settings", "effect_index"), indexInOrder)
    local header = W.MakeSectionHeader(self, labelX, pad, self.width - pad * 2, headerText)

    local y = header:getY() + ChaosUIManager.GetScaledWidth(W.SECTION_HEADER_H) + rowGap

    local function addLabelled(textKey)
        W.MakeLabel(self, labelX, y, labelW, ChaosLocalization.GetString("settings", textKey))
    end

    addLabelled("effect_enabled")
    self.controls.enabled = W.MakeCheckbox(self, controlX, y, "", effect.enabled == true, function(c)
        effect.enabled = c
    end)
    y = y + rowH + rowGap

    addLabelled("effect_chance")
    self.controls.chance = W.MakeNumberInput(self, controlX, y, controlW, effect.chance or 0, { float = false, maxLen = 4 })
    y = y + rowH + rowGap

    -- Has Duration label (read-only)
    addLabelled("effect_with_duration")
    local hasDurStr = effect.withDuration and "yes" or "no"
    W.MakeLabel(self, controlX, y, controlW, hasDurStr)
    y = y + rowH + rowGap

    if effect.withDuration then
        addLabelled("effect_duration")
        self.controls.duration = W.MakeNumberInput(self, controlX, y, controlW, effect.duration or 0, { float = false, maxLen = 8 })
        y = y + rowH + rowGap
    end

    addLabelled("effect_enabled_donate")
    self.controls.enabled_donate = W.MakeCheckbox(self, controlX, y, "", effect.enabled_donate == true, function(c)
        effect.enabled_donate = c
    end)
    y = y + rowH + rowGap

    addLabelled("effect_price_group")
    local groupOptions = {}
    table.insert(groupOptions, { key = "", label = "—" })
    local sm = self.parentWindow.workingConfig and self.parentWindow.workingConfig.streamer_mode or {}
    if type(sm.donate_price_groups) == "table" then
        for _, g in ipairs(sm.donate_price_groups) do
            if type(g.group) == "string" or type(g.group) == "number" then
                table.insert(groupOptions, { key = tostring(g.group), label = tostring(g.group) })
            end
        end
    end
    self.controls.priceGroupCombo = W.MakeDropdown(self, controlX, y, controlW, groupOptions, effect.price_group or "", function(key)
        effect.price_group = key or ""
        self:RefreshPriceLabel()
    end)
    y = y + rowH + rowGap

    -- Price line
    addLabelled("effect_price")
    self.controls.priceLabel = W.MakeLabel(self, controlX, y, controlW, self:ResolvePriceLabel(effect.price_group))
end

---@param groupKey string
---@return string
function ChaosSettingsEffectDetail:ResolvePriceLabel(groupKey)
    if not groupKey or groupKey == "" then return "—" end
    local sm = self.parentWindow.workingConfig and self.parentWindow.workingConfig.streamer_mode or {}
    if type(sm.donate_price_groups) ~= "table" then return "—" end
    for _, g in ipairs(sm.donate_price_groups) do
        if tostring(g.group) == tostring(groupKey) then
            return tostring(g.price or 0)
        end
    end
    return "—"
end

function ChaosSettingsEffectDetail:RefreshPriceLabel()
    if not self.currentId then return end
    local effect = self.parentWindow.workingEffects[self.currentId]
    if not effect then return end
    if self.controls.priceLabel and self.controls.priceLabel.setName then
        self.controls.priceLabel:setName(self:ResolvePriceLabel(effect.price_group))
    end
end

return ChaosSettingsEffectDetail
