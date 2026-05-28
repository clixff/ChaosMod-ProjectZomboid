---@class LootboxRollEntry
---@field text string?
---@field scriptItem Item | nil

---@class EffectLootboxRoll : ChaosEffectBase
---@field rollIndex integer
---@field totalRolls integer
---@field entries LootboxRollEntry[]
---@field window ChaosLootboxRollWindow | nil
---@field finished boolean
---@field lastRollTimeMs integer
---@field startTimeMs integer
EffectLootboxRoll = ChaosEffectBase:derive("EffectLootboxRoll", "lootbox_roll")

local TOTAL_ROLLS = 4
local CLOSE_DELAY_MS = 3000

---@param index integer
---@return string
local function pickItemIdForRoll(index)
    if index == 2 or index == 4 then
        return GetRandomLootboxItem(3)
    end
    return ChaosItems.GetRandomItemId()
end

function EffectLootboxRoll:OnStart()
    ChaosEffectBase:OnStart()

    setGameSpeed(0)

    self.rollIndex = 0
    self.totalRolls = TOTAL_ROLLS
    self.entries = {}
    for i = 1, TOTAL_ROLLS do
        self.entries[i] = { text = "????", scriptItem = nil }
    end
    self.finished = false
    self.startTimeMs = getTimestampMs()
    self.lastRollTimeMs = 0

    self.window = ChaosLootboxRollWindow:new(self)
    self.window:initialise()
    self.window:addToUIManager()
    self.window:setVisible(true)
end

function EffectLootboxRoll:onRollPressed()
    if self.finished then return end
    if self.rollIndex >= self.totalRolls then return end

    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local nextIndex = self.rollIndex + 1

    local itemId
    local item
    for _ = 1, 5 do
        itemId = pickItemIdForRoll(nextIndex)
        if itemId and itemId ~= "" then
            item = inventory:AddItem(itemId)
            ChaosItems.SetFullAmmoIfWeapon(item)
            if item then break end
        end
    end

    if not item then return end

    self.rollIndex = nextIndex
    self.lastRollTimeMs = getTimestampMs()

    local displayName = item:getDisplayName() --[[@as string?]]
    local text = displayName or itemId
    local scriptItem = itemId and getItem(itemId) or nil

    ---@type LootboxRollEntry
    local entry = { text = text, scriptItem = scriptItem }
    self.entries[nextIndex] = entry

    ChaosPlayer.SayLineNewItem(player, item)

    if self.rollIndex >= self.totalRolls then
        self.lastRollTimeMs = getTimestampMs()
    end
end

--- Drives expiry from the window's prerender so timers fire while the game is
--- paused via setGameSpeed(0) — Events.OnTick does not advance reliably then.
function EffectLootboxRoll:tickExpiry()
    if self.finished then return end

    local now = getTimestampMs()

    if self.rollIndex >= self.totalRolls and self.lastRollTimeMs > 0 then
        if now - self.lastRollTimeMs >= CLOSE_DELAY_MS then
            self.finished = true
            ChaosEffectsManager.DisableSpecificEffects({ "lootbox_roll" })
            return
        end
    end

    local maxMs = math.floor((self.duration or 0) * 1000)
    if maxMs > 0 and (now - (self.startTimeMs or 0)) >= maxMs then
        self.finished = true
        ChaosEffectsManager.DisableSpecificEffects({ "lootbox_roll" })
    end
end

---@param deltaMs integer
function EffectLootboxRoll:OnTick(deltaMs)
end

function EffectLootboxRoll:closeWindow()
    if self.window and not self.window.resolved then
        self.window.resolved = true
        self.window:setVisible(false)
        self.window:removeFromUIManager()
    end
    self.window = nil
end

function EffectLootboxRoll:OnEnd()
    ChaosEffectBase:OnEnd()
    self:closeWindow()
    setGameSpeed(1)
end
