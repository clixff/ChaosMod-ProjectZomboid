require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class ChaosSettingsConfigPanel : ISPanel
---@field parentWindow ChaosSettingsWindow
---@field controls table  -- per-section control handles for re-reads/refresh
ChaosSettingsConfigPanel = ISPanel:derive("ChaosSettingsConfigPanel")

-- Lazy resolution: ChaosSettingsWidgets loads after this file alphabetically,
-- so capture by reference each time a field is read.
---@type ChaosSettingsWidgets
local W = setmetatable({}, { __index = function(_, k) return ChaosSettingsWidgets[k] end })

local LANG_OPTIONS = {
    { key = "en", label = "en" },
    { key = "ru", label = "ru" },
    { key = "tr", label = "tr" },
    { key = "pl", label = "pl" },
    { key = "pt", label = "pt" },
    { key = "es", label = "es" },
    { key = "fr", label = "fr" },
    { key = "zh", label = "zh" },
    { key = "de", label = "de" },
}

---@param x number
---@param y number
---@param w number
---@param h number
---@param parentWindow ChaosSettingsWindow
---@return ChaosSettingsConfigPanel
function ChaosSettingsConfigPanel:new(x, y, w, h, parentWindow)
    ---@type ChaosSettingsConfigPanel
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.parentWindow = parentWindow
    o.background = false
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.controls = {}
    return o
end

function ChaosSettingsConfigPanel:initialise()
    ISPanel.initialise(self)
end

function ChaosSettingsConfigPanel:createChildren()
    ISPanel.createChildren(self)
    self:setScrollChildren(true)
    self:addScrollBars()
    if self.vscroll then
        ---@diagnostic disable-next-line: inject-field
        self.vscroll.doSetStencil = true
    end
    self:rebuild()
end

---ISPanel does not consume mouse-wheel events by default; without this, the
---wheel falls through and zooms the world camera.
---@param del number
---@return boolean
function ChaosSettingsConfigPanel:onMouseWheel(del)
    if self:getScrollHeight() > 0 then
        self:setYScroll(self:getYScroll() - (del * 40))
    end
    return true
end

-- Clip child rendering to the panel bounds. Without this, scrolled-out rows
-- are still drawn over the tab header and the bottom button bar.
function ChaosSettingsConfigPanel:prerender()
    self:setStencilRect(0, 0, self.width, self.height)
    ISPanel.prerender(self)
end

function ChaosSettingsConfigPanel:render()
    ISPanel.render(self)
    self:clearStencilRect()
end

function ChaosSettingsConfigPanel:RefreshFromWorkingState()
    -- Remove all child UI and rebuild against the latest workingConfig
    for _, c in ipairs(self.controls.allChildren or {}) do
        self:removeChild(c)
    end
    self.controls = {}
    self:rebuild()
end

---@param section string
---@return table
local function getSection(cfg, section)
    if not cfg[section] or type(cfg[section]) ~= "table" then
        cfg[section] = {}
    end
    return cfg[section]
end

function ChaosSettingsConfigPanel:rebuild()
    local cfg = self.parentWindow.workingConfig
    local pad = ChaosUIManager.GetScaledWidth(8)
    local labelW = ChaosUIManager.GetScaledWidth(W.LABEL_WIDTH)
    local controlW = ChaosUIManager.GetScaledWidth(W.CONTROL_WIDTH)
    local rowH = ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT)
    local rowGap = ChaosUIManager.GetScaledWidth(W.ROW_GAP)
    local sectionGap = ChaosUIManager.GetScaledWidth(W.SECTION_GAP)
    local sectionH = ChaosUIManager.GetScaledWidth(W.SECTION_HEADER_H)

    self.controls = { allChildren = {} }
    local children = self.controls.allChildren

    local labelX = pad
    local controlX = labelX + labelW + pad

    local y = pad

    local function addHeader(textKey)
        y = y + sectionGap
        local lbl = W.MakeSectionHeader(self, labelX, y, self.width - pad * 2, ChaosLocalization.GetString("settings", textKey))
        table.insert(children, lbl)
        y = y + sectionH + rowGap
    end

    local function addLabelled(textKey)
        local lbl = W.MakeLabel(self, labelX, y, labelW, ChaosLocalization.GetString("settings", textKey))
        table.insert(children, lbl)
    end

    -- ---------- Common ----------
    addHeader("section_common")

    addLabelled("lang")
    self.controls.lang = W.MakeDropdown(self, controlX, y, controlW, LANG_OPTIONS, cfg.lang or "en", function(key)
        cfg.lang = key
    end)
    table.insert(children, self.controls.lang)
    y = y + rowH + rowGap

    addLabelled("effects_interval_enabled")
    self.controls.effects_interval_enabled = W.MakeCheckbox(self, controlX, y, "", cfg.effects_interval_enabled == true, function(checked)
        cfg.effects_interval_enabled = checked
    end)
    table.insert(children, self.controls.effects_interval_enabled)
    y = y + rowH + rowGap

    addLabelled("effects_interval")
    self.controls.effects_interval = W.MakeNumberInput(self, controlX, y, controlW, cfg.effects_interval or 45, { float = false, maxLen = 6 })
    table.insert(children, self.controls.effects_interval)
    y = y + rowH + rowGap

    addLabelled("effects_duration_multiplier")
    self.controls.effects_duration_multiplier = W.MakeNumberInput(self, controlX, y, controlW, cfg.effects_duration_multiplier or 1.0, { float = true, maxLen = 8 })
    table.insert(children, self.controls.effects_duration_multiplier)
    y = y + rowH + rowGap

    addLabelled("recent_effects_block_buffer")
    self.controls.recent_effects_block_buffer = W.MakeNumberInput(self, controlX, y, controlW, cfg.recent_effects_block_buffer or 90, { float = false, maxLen = 6 })
    table.insert(children, self.controls.recent_effects_block_buffer)
    y = y + rowH + rowGap

    addLabelled("hide_progress_bar")
    self.controls.hide_progress_bar = W.MakeCheckbox(self, controlX, y, "", cfg.hide_progress_bar == true, function(checked)
        cfg.hide_progress_bar = checked
    end)
    table.insert(children, self.controls.hide_progress_bar)
    y = y + rowH + rowGap

    addLabelled("ui_sounds_enabled")
    self.controls.ui_sounds_enabled = W.MakeCheckbox(self, controlX, y, "", cfg.ui_sounds_enabled == true, function(checked)
        cfg.ui_sounds_enabled = checked
    end)
    table.insert(children, self.controls.ui_sounds_enabled)
    y = y + rowH + rowGap

    addLabelled("ignore_effect_chances")
    self.controls.ignore_effect_chances = W.MakeCheckbox(self, controlX, y, "", cfg.ignore_effect_chances == true, function(checked)
        cfg.ignore_effect_chances = checked
    end)
    table.insert(children, self.controls.ignore_effect_chances)
    y = y + rowH + rowGap

    -- ---------- Streamer Mode ----------
    local sm = getSection(cfg, "streamer_mode")
    addHeader("section_streamer_mode")

    addLabelled("streamer_mode_enabled")
    self.controls.streamer_mode_enabled = W.MakeCheckbox(self, controlX, y, "", sm.streamer_mode_enabled == true, function(c)
        sm.streamer_mode_enabled = c
    end)
    table.insert(children, self.controls.streamer_mode_enabled)
    y = y + rowH + rowGap

    addLabelled("voting_enabled")
    self.controls.voting_enabled = W.MakeCheckbox(self, controlX, y, "", sm.voting_enabled == true, function(c)
        sm.voting_enabled = c
    end)
    table.insert(children, self.controls.voting_enabled)
    y = y + rowH + rowGap

    addLabelled("vote_start_time")
    self.controls.vote_start_time = W.MakeNumberInput(self, controlX, y, controlW, cfg.vote_start_time or 10, { float = false, maxLen = 6 })
    table.insert(children, self.controls.vote_start_time)
    y = y + rowH + rowGap

    addLabelled("voting_mode")
    self.controls.voting_mode = W.MakeDropdown(self, controlX, y, controlW, {
        { key = 0, label = ChaosLocalization.GetString("settings", "voting_mode_most_votes") },
        { key = 1, label = ChaosLocalization.GetString("settings", "voting_mode_weighted_random") },
    }, sm.voting_mode or 0, function(key)
        sm.voting_mode = key
    end)
    table.insert(children, self.controls.voting_mode)
    y = y + rowH + rowGap

    addLabelled("voting_options_number")
    self.controls.voting_options_number = W.MakeDropdown(self, controlX, y, controlW, {
        { key = 4, label = "4" },
        { key = 5, label = "5" },
        { key = 6, label = "6" },
        { key = 7, label = "7" },
        { key = 8, label = "8" },
    }, sm.voting_options_number or 4, function(key)
        sm.voting_options_number = key
    end)
    table.insert(children, self.controls.voting_options_number)
    y = y + rowH + rowGap

    addLabelled("voting_type")
    self.controls.voting_type = W.MakeDropdown(self, controlX, y, controlW, {
        { key = "twitch", label = "Twitch" },
    }, sm.type or "twitch", function(key)
        sm.type = key
    end)
    table.insert(children, self.controls.voting_type)
    y = y + rowH + rowGap

    addLabelled("use_localhost_ip")
    self.controls.use_localhost_ip = W.MakeCheckbox(self, controlX, y, "", sm.use_localhost_ip == true, function(c)
        sm.use_localhost_ip = c
    end)
    table.insert(children, self.controls.use_localhost_ip)
    y = y + rowH + rowGap

    addLabelled("use_zombie_nicknames")
    self.controls.use_zombie_nicknames = W.MakeCheckbox(self, controlX, y, "", sm.use_zombie_nicknames == true, function(c)
        sm.use_zombie_nicknames = c
    end)
    table.insert(children, self.controls.use_zombie_nicknames)
    y = y + rowH + rowGap

    addLabelled("use_animals_nicknames")
    self.controls.use_animals_nicknames = W.MakeCheckbox(self, controlX, y, "", sm.use_animals_nicknames == true, function(c)
        sm.use_animals_nicknames = c
    end)
    table.insert(children, self.controls.use_animals_nicknames)
    y = y + rowH + rowGap

    addLabelled("render_chat_messages")
    self.controls.render_chat_messages = W.MakeCheckbox(self, controlX, y, "", sm.render_chat_messages == true, function(c)
        sm.render_chat_messages = c
    end)
    table.insert(children, self.controls.render_chat_messages)
    y = y + rowH + rowGap

    addLabelled("say_killed_zombie_name")
    self.controls.say_killed_zombie_name = W.MakeCheckbox(self, controlX, y, "", sm.say_killed_zombie_name == true, function(c)
        sm.say_killed_zombie_name = c
    end)
    table.insert(children, self.controls.say_killed_zombie_name)
    y = y + rowH + rowGap

    addLabelled("zombie_nicknames_buffer")
    self.controls.zombie_nicknames_buffer = W.MakeNumberInput(self, controlX, y, controlW, sm.zombie_nicknames_buffer or 150, { float = false, maxLen = 6 })
    table.insert(children, self.controls.zombie_nicknames_buffer)
    y = y + rowH + rowGap

    addLabelled("enable_donate")
    self.controls.enable_donate = W.MakeCheckbox(self, controlX, y, "", sm.enable_donate == true, function(c)
        sm.enable_donate = c
    end)
    table.insert(children, self.controls.enable_donate)
    y = y + rowH + rowGap

    addLabelled("allow_vote_command")
    self.controls.allow_vote_command = W.MakeCheckbox(self, controlX, y, "", sm.allow_vote_command == true, function(c)
        sm.allow_vote_command = c
    end)
    table.insert(children, self.controls.allow_vote_command)
    y = y + rowH + rowGap

    addLabelled("hide_votes")
    self.controls.hide_votes = W.MakeCheckbox(self, controlX, y, "", sm.hide_votes == true, function(c)
        sm.hide_votes = c
    end)
    table.insert(children, self.controls.hide_votes)
    y = y + rowH + rowGap

    -- ---------- Donate Groups ----------
    addHeader("section_donate_groups")
    if type(sm.donate_price_groups) ~= "table" then
        sm.donate_price_groups = {}
    end
    self.controls.donateGroups = {}
    local groupColW = (controlW + labelW + pad) - ChaosUIManager.GetScaledWidth(110) - pad
    local nameW = math.floor(groupColW * 0.55)
    local priceW = groupColW - nameW - pad
    local removeBtnW = ChaosUIManager.GetScaledWidth(110)
    for i, group in ipairs(sm.donate_price_groups) do
        local nameBox = W.MakeTextInput(self, labelX, y, nameW, group.group or "", { maxLen = 64 })
        table.insert(children, nameBox)
        local priceBox = W.MakeNumberInput(self, labelX + nameW + pad, y, priceW, group.price or 0, { float = true, maxLen = 12 })
        table.insert(children, priceBox)
        local removeX = labelX + nameW + pad + priceW + pad
        local btn = ISButton:new(removeX, y, removeBtnW, ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT),
            ChaosLocalization.GetString("settings", "remove_group"), self, ChaosSettingsConfigPanel.OnRemoveGroup)
        ---@diagnostic disable-next-line: inject-field
        btn.removeIndex = i
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        table.insert(children, btn)
        table.insert(self.controls.donateGroups, { name = nameBox, price = priceBox, oldName = group.group })
        y = y + rowH + rowGap
    end
    -- + Add Group button
    local addBtn = ISButton:new(labelX, y, ChaosUIManager.GetScaledWidth(160), ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT),
        ChaosLocalization.GetString("settings", "add_group"), self, ChaosSettingsConfigPanel.OnAddGroup)
    addBtn:initialise()
    addBtn:instantiate()
    self:addChild(addBtn)
    table.insert(children, addBtn)
    y = y + rowH + rowGap

    -- ---------- UI ----------
    local ui = getSection(cfg, "ui")
    addHeader("section_ui")

    addLabelled("use_voting_progress_bar_color")
    self.controls.use_voting_progress_bar_color = W.MakeCheckbox(self, controlX, y, "", cfg.use_voting_progress_bar_color == true, function(c)
        cfg.use_voting_progress_bar_color = c
    end)
    table.insert(children, self.controls.use_voting_progress_bar_color)
    y = y + rowH + rowGap

    addLabelled("progress_bar_color")
    self.controls.progress_bar_color = W.MakeTextInput(self, controlX, y, controlW, ui.progress_bar_color or "9f211f", { maxLen = 6 })
    table.insert(children, self.controls.progress_bar_color)
    y = y + rowH + rowGap

    addLabelled("progress_bar_opacity")
    self.controls.progress_bar_opacity = W.MakeNumberInput(self, controlX, y, controlW, ui.progress_bar_opacity or 0.9, { float = true, maxLen = 8 })
    table.insert(children, self.controls.progress_bar_opacity)
    y = y + rowH + rowGap

    addLabelled("progress_bar_text_color")
    self.controls.progress_bar_text_color = W.MakeTextInput(self, controlX, y, controlW, ui.progress_bar_text_color or "ffffff", { maxLen = 6 })
    table.insert(children, self.controls.progress_bar_text_color)
    y = y + rowH + rowGap

    addLabelled("progress_bar_height")
    self.controls.progress_bar_height = W.MakeNumberInput(self, controlX, y, controlW, ui.progress_bar_height or 22, { float = false, maxLen = 6 })
    table.insert(children, self.controls.progress_bar_height)
    y = y + rowH + rowGap

    addLabelled("effect_progress_color")
    self.controls.effect_progress_color = W.MakeTextInput(self, controlX, y, controlW, ui.effect_progress_color or "9f211f", { maxLen = 6 })
    table.insert(children, self.controls.effect_progress_color)
    y = y + rowH + rowGap

    addLabelled("effect_progress_text_color")
    self.controls.effect_progress_text_color = W.MakeTextInput(self, controlX, y, controlW, ui.effect_progress_text_color or "ffffff", { maxLen = 6 })
    table.insert(children, self.controls.effect_progress_text_color)
    y = y + rowH + rowGap

    addLabelled("effects_default_x")
    self.controls.effects_default_x = W.MakeNumberInput(self, controlX, y, controlW, ui.effects_default_x or 1620, { float = false, maxLen = 6 })
    table.insert(children, self.controls.effects_default_x)
    y = y + rowH + rowGap

    addLabelled("effects_default_y")
    self.controls.effects_default_y = W.MakeNumberInput(self, controlX, y, controlW, ui.effects_default_y or 720, { float = false, maxLen = 6 })
    table.insert(children, self.controls.effects_default_y)
    y = y + rowH + rowGap

    addLabelled("effects_from_bottom_to_top")
    self.controls.effects_from_bottom_to_top = W.MakeCheckbox(self, controlX, y, "", ui.effects_from_bottom_to_top == true, function(c)
        ui.effects_from_bottom_to_top = c
    end)
    table.insert(children, self.controls.effects_from_bottom_to_top)
    y = y + rowH + rowGap

    addLabelled("progress_bar_voting_color")
    self.controls.progress_bar_voting_color = W.MakeTextInput(self, controlX, y, controlW, ui.progress_bar_voting_color or "3b8eea", { maxLen = 6 })
    table.insert(children, self.controls.progress_bar_voting_color)
    y = y + rowH + rowGap

    addLabelled("vote_background_color")
    self.controls.vote_background_color = W.MakeTextInput(self, controlX, y, controlW, ui.vote_background_color or "9f211f", { maxLen = 6 })
    table.insert(children, self.controls.vote_background_color)
    y = y + rowH + rowGap

    self:setScrollHeight(y + pad)
end

---Reads typed values from text inputs (those don't fire onChange) into workingConfig.
function ChaosSettingsConfigPanel:CommitWorkingState()
    local cfg = self.parentWindow.workingConfig
    local sm = getSection(cfg, "streamer_mode")
    local ui = getSection(cfg, "ui")

    if self.controls.effects_interval then
        cfg.effects_interval = W.GetIntFromBox(self.controls.effects_interval, cfg.effects_interval or 45)
    end
    if self.controls.effects_duration_multiplier then
        local v = W.GetFloatFromBox(self.controls.effects_duration_multiplier, cfg.effects_duration_multiplier or 1.0)
        if v <= 0 then v = 1.0 end
        cfg.effects_duration_multiplier = v
    end
    if self.controls.recent_effects_block_buffer then
        local v = W.GetIntFromBox(self.controls.recent_effects_block_buffer, cfg.recent_effects_block_buffer or 90)
        if v < 0 then v = 0 end
        cfg.recent_effects_block_buffer = v
    end
    if self.controls.vote_start_time then
        cfg.vote_start_time = W.GetIntFromBox(self.controls.vote_start_time, cfg.vote_start_time or 10)
    end
    if self.controls.zombie_nicknames_buffer then
        sm.zombie_nicknames_buffer = W.GetIntFromBox(self.controls.zombie_nicknames_buffer, sm.zombie_nicknames_buffer or 150)
    end
    if self.controls.progress_bar_color then
        ui.progress_bar_color = self.controls.progress_bar_color:getInternalText() or ui.progress_bar_color
    end
    if self.controls.progress_bar_opacity then
        ui.progress_bar_opacity = W.Clamp(W.GetFloatFromBox(self.controls.progress_bar_opacity, ui.progress_bar_opacity or 0.9), 0, 1)
    end
    if self.controls.progress_bar_text_color then
        ui.progress_bar_text_color = self.controls.progress_bar_text_color:getInternalText() or ui.progress_bar_text_color
    end
    if self.controls.progress_bar_height then
        ui.progress_bar_height = W.GetIntFromBox(self.controls.progress_bar_height, ui.progress_bar_height or 22)
    end
    if self.controls.effect_progress_color then
        ui.effect_progress_color = self.controls.effect_progress_color:getInternalText() or ui.effect_progress_color
    end
    if self.controls.effect_progress_text_color then
        ui.effect_progress_text_color = self.controls.effect_progress_text_color:getInternalText() or ui.effect_progress_text_color
    end
    if self.controls.effects_default_x then
        ui.effects_default_x = W.GetIntFromBox(self.controls.effects_default_x, ui.effects_default_x or 1620)
    end
    if self.controls.effects_default_y then
        ui.effects_default_y = W.GetIntFromBox(self.controls.effects_default_y, ui.effects_default_y or 720)
    end
    if self.controls.progress_bar_voting_color then
        ui.progress_bar_voting_color = self.controls.progress_bar_voting_color:getInternalText() or ui.progress_bar_voting_color
    end
    if self.controls.vote_background_color then
        ui.vote_background_color = self.controls.vote_background_color:getInternalText() or ui.vote_background_color
    end

    -- Donate groups: read name + price text inputs and rename references on effects.
    if self.controls.donateGroups and sm.donate_price_groups then
        local effects = self.parentWindow.workingEffects or {}
        for i, ctl in ipairs(self.controls.donateGroups) do
            ---@type DonatePriceGroup | nil
            local g = sm.donate_price_groups[i]
            if g then
                local newName = tostring(ctl.name:getInternalText() or g.group or "")
                local oldName = ctl.oldName
                if oldName ~= nil and newName ~= oldName then
                    for _, effect in pairs(effects) do
                        if effect.price_group == oldName then
                            effect.price_group = newName
                        end
                    end
                end
                g.group = newName
                ctl.oldName = newName
                g.price = W.GetFloatFromBox(ctl.price, g.price or 0)
            end
        end
    end
end

---@param button ISButton
function ChaosSettingsConfigPanel:OnRemoveGroup(button)
    self:CommitWorkingState()
    local cfg = self.parentWindow.workingConfig
    local sm = getSection(cfg, "streamer_mode")
    if not sm.donate_price_groups then return end
    ---@diagnostic disable-next-line: undefined-field
    local idx = button.removeIndex
    if not idx or not sm.donate_price_groups[idx] then return end
    ---@type DonatePriceGroup | nil
    local removed = sm.donate_price_groups[idx]
    table.remove(sm.donate_price_groups, idx)
    -- Clear references on effects to a removed group
    if removed and removed.group then
        local removedName = removed.group
        for _, effect in pairs(self.parentWindow.workingEffects or {}) do
            if effect.price_group == removedName then
                effect.price_group = ""
            end
        end
    end
    self:RefreshFromWorkingState()
end

function ChaosSettingsConfigPanel:OnAddGroup()
    self:CommitWorkingState()
    local cfg = self.parentWindow.workingConfig
    local sm = getSection(cfg, "streamer_mode")
    if type(sm.donate_price_groups) ~= "table" then
        sm.donate_price_groups = {}
    end
    table.insert(sm.donate_price_groups, { group = "", price = 1 })
    self:RefreshFromWorkingState()
end

return ChaosSettingsConfigPanel
