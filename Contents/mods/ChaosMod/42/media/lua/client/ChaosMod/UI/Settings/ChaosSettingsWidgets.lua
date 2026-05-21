require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISTickBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISComboBox"

---@class ChaosSettingsWidgets
ChaosSettingsWidgets = ChaosSettingsWidgets or {}

local W              = ChaosSettingsWidgets

W.LABEL_WIDTH        = 280
W.CONTROL_WIDTH      = 240
W.ROW_HEIGHT         = 22
W.ROW_GAP            = 8
W.SECTION_GAP        = 14
W.SECTION_HEADER_H   = 24
W.HINT_LINE_HEIGHT   = 16

---@param value any
---@return number | nil
local function toFloatOrNil(value)
    if type(value) == "number" then return value end
    if type(value) ~= "string" then return nil end
    local trimmed = value:match("^%s*(.-)%s*$")
    if trimmed == "" then return nil end
    return tonumber(trimmed)
end

W.toFloatOrNil = toFloatOrNil

---@param parent ISPanel
---@param x number
---@param y number
---@param w number
---@param text string
---@return ISLabel
function W.MakeLabel(parent, x, y, w, text)
    local label = ISLabel:new(x, y, ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT), text or "", 1, 1, 1, 1, UIFont.Small,
        true)
    label:initialise()
    label:instantiate()
    parent:addChild(label)
    return label
end

---Creates a muted multi-line hint placed below a setting row. The input
---string is split on `\n` and rendered as one ISLabel per line so it stacks
---vertically without word-wrap.
---@param parent ISPanel
---@param x number
---@param y number
---@param text string
---@return table<integer, ISLabel> labels, number totalHeight
function W.MakeHint(parent, x, y, text)
    local labels = {}
    local lineH = ChaosUIManager.GetScaledWidth(W.HINT_LINE_HEIGHT)
    local i = 0
    for line in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        local label = ISLabel:new(x, y + i * lineH, lineH, line, 0.7, 0.7, 0.7, 1, UIFont.Small, true)
        label:initialise()
        label:instantiate()
        parent:addChild(label)
        table.insert(labels, label)
        i = i + 1
    end
    return labels, i * lineH
end

---@param parent ISPanel
---@param x number
---@param y number
---@param w number
---@param text string
---@return ISLabel
function W.MakeSectionHeader(parent, x, y, w, text)
    local label = ISLabel:new(x, y, ChaosUIManager.GetScaledWidth(W.SECTION_HEADER_H), text or "", 1, 0.85, 0.55, 1,
        UIFont.Medium, true)
    label:initialise()
    label:instantiate()
    parent:addChild(label)
    return label
end

---Creates a single-option ISTickBox.
---@param parent ISPanel
---@param x number
---@param y number
---@param label string
---@param initial boolean
---@param onChange fun(checked: boolean) | nil
---@return ISTickBox
function W.MakeCheckbox(parent, x, y, label, initial, onChange)
    local h = ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT)
    ---@type ISTickBox
    local box
    box = ISTickBox:new(x, y, h, h, "", parent, function(_target, _idx, _selected)
        if onChange then onChange(box:isSelected(1)) end
    end)
    box:initialise()
    box:instantiate()
    -- addChild *before* addOption: addOption calls setHeight, which clamps y to
    -- screenHeight when the widget has no parent (getKeepOnScreen() defaults to
    -- true while self.parent is nil). With many donate groups pushing y past
    -- screen height, the checkbox would otherwise jump up to the screen bottom.
    parent:addChild(box)
    box:addOption(label or "")
    box:setSelected(1, initial == true)
    return box
end

---@param parent ISPanel
---@param x number
---@param y number
---@param w number
---@param initial number | string
---@param opts {float: boolean | nil, maxLen: number | nil} | nil
---@return ISTextEntryBox
function W.MakeNumberInput(parent, x, y, w, initial, opts)
    opts = opts or {}
    local h = ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT)
    local box = ISTextEntryBox:new(tostring(initial or ""), x, y, w, h)
    box.font = UIFont.NewSmall
    box:initialise()
    box:instantiate()
    if not opts then
        return box
    end
    if not opts.float then
        box:setOnlyNumbers(true)
    end
    if opts.maxLen then
        box:setMaxTextLength(opts.maxLen)
    end
    parent:addChild(box)
    return box
end

---@param parent ISPanel
---@param x number
---@param y number
---@param w number
---@param initial string
---@param opts {maxLen: number | nil} | nil
---@return ISTextEntryBox
function W.MakeTextInput(parent, x, y, w, initial, opts)
    opts = opts or {}
    local h = ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT)
    local box = ISTextEntryBox:new(tostring(initial or ""), x, y, w, h)
    box.font = UIFont.NewSmall
    box:initialise()
    box:instantiate()

    if not opts then
        return box
    end

    if opts.maxLen then
        box:setMaxTextLength(opts.maxLen)
    end
    parent:addChild(box)
    return box
end

---Creates an ISComboBox. `options` is `{ {key=any, label=string}, ... }`.
---Selects the entry whose `key` equals `initialKey` (defaults to first if not found).
---`onChange(key)` is invoked with the new key when selection changes.
---@param parent ISPanel
---@param x number
---@param y number
---@param w number
---@param options table<integer, {key: any, label: string}>
---@param initialKey any
---@param onChange fun(key: any) | nil
---@return ISComboBox
function W.MakeDropdown(parent, x, y, w, options, initialKey, onChange)
    local h = ChaosUIManager.GetScaledWidth(W.ROW_HEIGHT)
    local combo = ISComboBox:new(x, y, w, h, parent, function() end)
    combo:initialise()
    combo:instantiate()
    local selectedIndex = 1
    for i, opt in ipairs(options) do
        combo:addOptionWithData(opt.label, opt.key)
        if opt.key == initialKey then selectedIndex = i end
    end
    combo.selected = selectedIndex
    -- ISComboBox invokes onChange as: onChange(target, comboBox, arg1, arg2)
    combo.onChange = function(_target, comboBox)
        if not comboBox then return end
        local data = comboBox:getOptionData(comboBox.selected)
        if onChange then onChange(data) end
    end
    parent:addChild(combo)
    return combo
end

---Returns the integer value typed into a number input, or `fallback` if invalid.
---@param box ISTextEntryBox
---@param fallback number
---@return number
function W.GetIntFromBox(box, fallback)
    local n = toFloatOrNil(box:getInternalText())
    if not n then return fallback end
    return math.floor(n)
end

---Returns the float value typed into a number input, or `fallback` if invalid.
---@param box ISTextEntryBox
---@param fallback number
---@return number
function W.GetFloatFromBox(box, fallback)
    local n = toFloatOrNil(box:getInternalText())
    if not n then return fallback end
    return n
end

---Clamps a number into [min, max].
---@param value number
---@param minVal number
---@param maxVal number
---@return number
function W.Clamp(value, minVal, maxVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

---Returns a deep clone of any table. Detects cycles via a memo so referencing
---tables (e.g. classes whose metatable points back at themselves) never recurse
---forever.
---@param value any
---@param memo table | nil
---@return any
function W.DeepCopy(value, memo)
    if type(value) ~= "table" then return value end
    memo = memo or {}
    local existing = memo[value]
    if existing ~= nil then return existing end
    local out = {}
    memo[value] = out
    for k, v in pairs(value) do
        out[k] = W.DeepCopy(v, memo)
    end
    return out
end

return W
