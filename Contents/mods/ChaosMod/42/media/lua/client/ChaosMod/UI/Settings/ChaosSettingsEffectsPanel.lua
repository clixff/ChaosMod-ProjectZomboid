require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"

---@class ChaosSettingsEffectsPanel : ISPanel
---@field parentWindow ChaosSettingsWindow
---@field searchText string
---@field selectedId string | nil
---@field list ISScrollingListBox
---@field searchBox ISTextEntryBox
---@field detail ChaosSettingsEffectDetail
ChaosSettingsEffectsPanel = ISPanel:derive("ChaosSettingsEffectsPanel")

---@param x number
---@param y number
---@param w number
---@param h number
---@param parentWindow ChaosSettingsWindow
---@return ChaosSettingsEffectsPanel
function ChaosSettingsEffectsPanel:new(x, y, w, h, parentWindow)
    ---@type ChaosSettingsEffectsPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.parentWindow = parentWindow
    o.searchText = ""
    o.selectedId = nil
    o.background = false
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ChaosSettingsEffectsPanel:initialise()
    ISPanel.initialise(self)
end

---Consume the mouse wheel so it doesn't fall through to the world camera.
---@param del number
---@return boolean
function ChaosSettingsEffectsPanel:onMouseWheel(del)
    -- Forward the wheel to the list so it scrolls.
    if self.list and self.list.onMouseWheel then
        self.list:onMouseWheel(del)
    end
    return true
end

function ChaosSettingsEffectsPanel:createChildren()
    ISPanel.createChildren(self)

    local pad = ChaosUIManager.GetScaledWidth(8)
    local rowH = ChaosUIManager.GetScaledWidth(22)
    local leftW = ChaosUIManager.GetScaledWidth(320)

    self.searchBox = ISTextEntryBox:new("", pad, pad, leftW, rowH)
    self.searchBox.font = UIFont.NewSmall
    self.searchBox.target = self
    self.searchBox.onTextChange = ChaosSettingsEffectsPanel.OnSearchChanged
    self.searchBox:setPlaceholderText(ChaosLocalization.GetString("core", "search_placeholder"))
    self.searchBox:initialise()
    self.searchBox:instantiate()
    self.searchBox:setClearButton(true)
    self:addChild(self.searchBox)
    -- Defensive: this panel is created as a non-active tab view, so the parent
    -- tabPanel calls view:setVisible(false) on it before the user ever shows it.
    -- Force the search box's java state so it routes input correctly when the
    -- effects tab is later activated.
    self.searchBox:setEditable(true)
    self.searchBox:setVisible(true)

    local listY = pad + rowH + pad
    local listH = self.height - listY - pad
    self.list = ISScrollingListBox:new(pad, listY, leftW, listH)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = ChaosUIManager.GetScaledWidth(22)
    self.list.drawBorder = true
    self.list.font = UIFont.NewSmall
    self.list.target = self
    self.list.onmousedown = ChaosSettingsEffectsPanel.OnListClicked
    self:addChild(self.list)

    local detailX = pad + leftW + pad
    local detailW = self.width - detailX - pad
    local detailY = pad
    local detailH = self.height - pad * 2

    self.detail = ChaosSettingsEffectDetail:new(detailX, detailY, detailW, detailH, self.parentWindow)
    self.detail:initialise()
    self.detail:instantiate()
    self:addChild(self.detail)

    self:RefillList()
end

-- Note: dot syntax (not colon) — ISTextEntryBox calls onTextChange(box) with a single
-- argument. The panel is reachable via box.target.
---@param box ISTextEntryBox
function ChaosSettingsEffectsPanel.OnSearchChanged(box)
    if not box or not box.target then return end
    local panel = box.target
    local newText = box:getInternalText() or ""
    if newText ~= panel.searchText then
        panel.searchText = newText
        panel:RefillList()
    end
end

function ChaosSettingsEffectsPanel:RefillList()
    self.list:clear()
    local needle = nil
    if self.searchText and self.searchText ~= "" then
        needle = string.lower(self.searchText)
    end

    -- Iterate in the original effects.json order; items are labelled "<index>. <name> (<id>)".
    local firstId = nil
    for index, id in ipairs(self.parentWindow.workingEffectOrder) do
        local effect = self.parentWindow.workingEffects[id]
        if effect then
            local name = ChaosLocalization.GetString("effects", id) or id
            local matches = true
            if needle then
                matches = (string.find(string.lower(name), needle, 1, true) ~= nil)
                    or (string.find(string.lower(id), needle, 1, true) ~= nil)
            end
            if matches then
                local label = string.format("%d. %s  (%s)", index, name, id)
                self.list:addItem(label, { id = id, name = name, index = index })
                if not firstId then firstId = id end
            end
        end
    end

    if self.selectedId and self.parentWindow.workingEffects[self.selectedId] then
        self.detail:LoadEffect(self.selectedId)
    elseif firstId then
        self.selectedId = firstId
        self.detail:LoadEffect(firstId)
    else
        self.detail:LoadEffect(nil)
    end
end

---Called by ISScrollingListBox on item click. Item data is the table we passed in addItem.
---@param item {id: string, name: string}
function ChaosSettingsEffectsPanel:OnListClicked(item)
    if not item or not item.id then return end
    self.selectedId = item.id
    self.detail:LoadEffect(item.id)
end

function ChaosSettingsEffectsPanel:CommitWorkingState()
    if self.detail and self.detail.CommitWorkingState then
        self.detail:CommitWorkingState()
    end
end

function ChaosSettingsEffectsPanel:RefreshFromWorkingState()
    self:RefillList()
    if self.detail and self.detail.RefreshFromWorkingState then
        self.detail:RefreshFromWorkingState()
    end
end

return ChaosSettingsEffectsPanel
