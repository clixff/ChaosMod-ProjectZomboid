require "ISUI/ISCollapsableWindow"
require "ISUI/ISTabPanel"
require "ISUI/ISButton"
require "ISUI/ISModalDialog"

---@class ChaosSettingsWindow : ISCollapsableWindow
---@field workingConfig table
---@field workingEffects table<string, ChaosEffectDataEntry>
---@field workingEffectOrder string[]
---@field tabPanel ISTabPanel
---@field configPanel ChaosSettingsConfigPanel
---@field effectsPanel ChaosSettingsEffectsPanel
---@field resetButton ISButton
---@field saveButton ISButton
---@field closeButton ISButton
---@field activeTab "settings" | "effects"
ChaosSettingsWindow = ISCollapsableWindow:derive("ChaosSettingsWindow")

---@type ChaosSettingsWidgets
local W = setmetatable({}, { __index = function(_, k) return ChaosSettingsWidgets[k] end })

---@param x number
---@param y number
---@param w number
---@param h number
---@return ChaosSettingsWindow
function ChaosSettingsWindow:new(x, y, w, h)
    ---@type ChaosSettingsWindow
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.title = ChaosLocalization.GetString("settings", "title")
    o.resizable = false
    o.activeTab = "settings"
    o.workingConfig = W.DeepCopy(ChaosConfig.BuildJsonSnapshot())
    o.workingEffects = {}
    o.workingEffectOrder = {}
    local order = ChaosEffectsRegistry.effectOrder or {}
    for _, id in ipairs(order) do
        local effect = ChaosEffectsRegistry.effects[id]
        if effect then
            o.workingEffects[id] = W.DeepCopy(effect)
            table.insert(o.workingEffectOrder, id)
        end
    end
    -- Pick up effects not in order list
    for id, effect in pairs(ChaosEffectsRegistry.effects) do
        if not o.workingEffects[id] then
            o.workingEffects[id] = W.DeepCopy(effect)
            table.insert(o.workingEffectOrder, id)
        end
    end
    return o
end

function ChaosSettingsWindow:initialise()
    ISCollapsableWindow.initialise(self)
    -- Without this, key events fall through to the world (movement keys move the player
    -- while typing in the search/text inputs).
    self:setWantKeyEvents(true)
end

function ChaosSettingsWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local pad = ChaosUIManager.GetScaledWidth(8)
    local titleH = ISCollapsableWindow.titleBarHeight(self)
    local btnH = ChaosUIManager.GetScaledWidth(28)
    local bottomBarH = btnH + pad * 2

    local tabsX = pad
    local tabsY = titleH + pad
    local tabsW = self.width - pad * 2
    local tabsH = self.height - tabsY - bottomBarH

    self.tabPanel = ISTabPanel:new(tabsX, tabsY, tabsW, tabsH)
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.target = self
    self.tabPanel.equalTabWidth = true
    self:addChild(self.tabPanel)

    local viewX = 0
    local viewY = self.tabPanel.tabHeight or ChaosUIManager.GetScaledWidth(24)
    local viewW = tabsW
    local viewH = tabsH - viewY

    self.configPanel = ChaosSettingsConfigPanel:new(viewX, viewY, viewW, viewH, self)
    self.configPanel:initialise()
    self.configPanel:instantiate()
    self.tabPanel:addView(ChaosLocalization.GetString("settings", "tab_settings"), self.configPanel)

    self.effectsPanel = ChaosSettingsEffectsPanel:new(viewX, viewY, viewW, viewH, self)
    self.effectsPanel:initialise()
    self.effectsPanel:instantiate()
    self.tabPanel:addView(ChaosLocalization.GetString("settings", "tab_effects"), self.effectsPanel)

    -- Bottom button row (Reset / Save / Close), right-aligned. Created before
    -- activateView so that the OnTabChanged callback can safely reference them.
    local btnY = self.height - btnH - pad
    local btnGap = ChaosUIManager.GetScaledWidth(6)
    local closeBtnW = ChaosUIManager.GetScaledWidth(120)
    local saveBtnW = ChaosUIManager.GetScaledWidth(120)
    local resetBtnW = ChaosUIManager.GetScaledWidth(220)

    local closeX = self.width - pad - closeBtnW
    local saveX = closeX - btnGap - saveBtnW
    local resetX = saveX - btnGap - resetBtnW

    self.resetButton = ISButton:new(resetX, btnY, resetBtnW, btnH,
        ChaosLocalization.GetString("settings", "reset_default_config"),
        self, ChaosSettingsWindow.OnResetClicked)
    self.resetButton:initialise()
    self.resetButton:instantiate()
    self:addChild(self.resetButton)

    self.saveButton = ISButton:new(saveX, btnY, saveBtnW, btnH,
        ChaosLocalization.GetString("settings", "save"),
        self, ChaosSettingsWindow.OnSaveClicked)
    self.saveButton:initialise()
    self.saveButton:instantiate()
    self.saveButton:enableAcceptColor()
    self:addChild(self.saveButton)

    self.closeButton = ISButton:new(closeX, btnY, closeBtnW, btnH,
        ChaosLocalization.GetString("settings", "close"),
        self, ChaosSettingsWindow.OnCloseClicked)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    -- Wire the tab callback last, then activate the default tab so the callback fires once.
    self.tabPanel.onActivateView = ChaosSettingsWindow.OnTabChanged
    self.tabPanel:activateView(ChaosLocalization.GetString("settings", "tab_settings"))
end

---@param tabPanel ISTabPanel
function ChaosSettingsWindow:OnTabChanged(tabPanel)
    local active = tabPanel:getActiveView()
    if active == self.effectsPanel then
        self.activeTab = "effects"
        self.resetButton:setTitle(ChaosLocalization.GetString("settings", "reset_default_effects"))
    else
        self.activeTab = "settings"
        self.resetButton:setTitle(ChaosLocalization.GetString("settings", "reset_default_config"))
    end
end

function ChaosSettingsWindow:OnSaveClicked()
    -- Have child panels flush any in-flight text inputs into workingConfig/workingEffects
    if self.configPanel and self.configPanel.CommitWorkingState then
        self.configPanel:CommitWorkingState()
    end
    if self.effectsPanel and self.effectsPanel.CommitWorkingState then
        self.effectsPanel:CommitWorkingState()
    end

    -- Capture timing values before reload so we can detect changes that require
    -- restarting the global effects iteration.
    local prevEffectsInterval = ChaosConfig.effects_interval
    local prevVoteStartTime = ChaosConfig.vote_start_time

    -- Persist working config snapshot to disk, then reload to repopulate ChaosConfig.
    if not ChaosFileReader.WriteJsonToCache("ChaosMod/config.json", self.workingConfig) then
        print("[ChaosSettingsWindow] Failed to write config.json")
    else
        ChaosConfig.LoadConfigFromDisk()
    end

    -- If the mod is currently running and the interval or vote-start timing changed,
    -- restart the global iteration so the progress bar reflects the new timing.
    if ChaosMod.enabled
        and (ChaosConfig.effects_interval ~= prevEffectsInterval
            or ChaosConfig.vote_start_time ~= prevVoteStartTime) then
        ChaosEffectsManager.StartGlobalTimer()
    end

    -- Reload language files first so the registry rebuild below picks up the new translations.
    ChaosLocalization.ReloadLanguages()

    -- Persist working effects snapshot
    local effectsSnapshot = self:BuildEffectsSnapshot()
    if not ChaosFileReader.WriteJsonToCache("ChaosMod/effects.json", effectsSnapshot) then
        print("[ChaosSettingsWindow] Failed to write effects.json")
    else
        ChaosEffectsRegistry.Initialize()
    end

    -- Refresh dependent UI (HUD labels, effects window, settings panels)
    if ChaosUIManager and ChaosUIManager.OnLanguageLoaded then
        ChaosUIManager:OnLanguageLoaded()
    end

    -- Refresh window title and child panels' visible labels
    self.title = ChaosLocalization.GetString("settings", "title")
    self:OnTabChanged(self.tabPanel)

    -- Notify Node side
    if ChaosBridge and ChaosBridge.NotifyConfigReloaded then
        ChaosBridge.NotifyConfigReloaded()
    end

    -- Refresh working state from current truth so subsequent edits start fresh
    self.workingConfig = W.DeepCopy(ChaosConfig.BuildJsonSnapshot())
    self.workingEffects = {}
    self.workingEffectOrder = {}
    for _, id in ipairs(ChaosEffectsRegistry.effectOrder or {}) do
        local effect = ChaosEffectsRegistry.effects[id]
        if effect then
            self.workingEffects[id] = W.DeepCopy(effect)
            table.insert(self.workingEffectOrder, id)
        end
    end

    if self.configPanel and self.configPanel.RefreshFromWorkingState then
        self.configPanel:RefreshFromWorkingState()
    end
    if self.effectsPanel and self.effectsPanel.RefreshFromWorkingState then
        self.effectsPanel:RefreshFromWorkingState()
    end

    print("[ChaosSettingsWindow] Saved")
end

---@return table
function ChaosSettingsWindow:BuildEffectsSnapshot()
    local arr = {}
    for _, id in ipairs(self.workingEffectOrder) do
        local e = self.workingEffects[id]
        if e then
            local disable = {}
            if type(e.disableEffects) == "table" then
                for _, did in ipairs(e.disableEffects) do
                    table.insert(disable, did)
                end
            end
            table.insert(arr, {
                id = e.id,
                enabled = e.enabled,
                chance = e.chance,
                withDuration = e.withDuration,
                duration = e.duration,
                disable_effects = disable,
                enabled_donate = e.enabled_donate,
                price_group = e.price_group,
            })
        end
    end
    return { effects = arr }
end

function ChaosSettingsWindow:OnCloseClicked()
    self:setVisible(false)
    self:removeFromUIManager()
    if ChaosUIManager then
        ChaosUIManager.settingsWindow = nil
    end
end

function ChaosSettingsWindow:OnResetClicked()
    local modal = ISModalDialog:new(0, 0,
        ChaosUIManager.GetScaledWidth(420),
        ChaosUIManager.GetScaledHeight(180),
        ChaosLocalization.GetString("settings", "confirm_reset_text"),
        true, self, ChaosSettingsWindow.OnResetConfirm)
    modal:initialise()
    modal:addToUIManager()
end

---@param button ISButton
function ChaosSettingsWindow:OnResetConfirm(button)
    if not button or button.internal ~= "YES" then return end
    if self.activeTab == "settings" then
        if ChaosConfig.ResetToDefaults() then
            self.workingConfig = W.DeepCopy(ChaosConfig.BuildJsonSnapshot())
            if self.configPanel and self.configPanel.RefreshFromWorkingState then
                self.configPanel:RefreshFromWorkingState()
            end
        end
    else
        if ChaosEffectsRegistry.ResetToDefaults() then
            self.workingEffects = {}
            self.workingEffectOrder = {}
            for _, id in ipairs(ChaosEffectsRegistry.effectOrder or {}) do
                local effect = ChaosEffectsRegistry.effects[id]
                if effect then
                    self.workingEffects[id] = W.DeepCopy(effect)
                    table.insert(self.workingEffectOrder, id)
                end
            end
            if self.effectsPanel and self.effectsPanel.RefreshFromWorkingState then
                self.effectsPanel:RefreshFromWorkingState()
            end
        end
    end
    if ChaosBridge and ChaosBridge.NotifyConfigReloaded then
        ChaosBridge.NotifyConfigReloaded()
    end
end

return ChaosSettingsWindow
