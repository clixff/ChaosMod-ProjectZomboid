--- Tracks StreamerApp handshake state and shows the version-mismatch / update /
--- failed-connect modals based on the unified `streamer_handshake` event.
---@class ChaosBridgeHandshake
ChaosBridgeHandshake = ChaosBridgeHandshake or {}

local CATEGORY_MISMATCH = "version_mismatch"
local CATEGORY_UPDATE = "new_update"
local CATEGORY_FAILED = "failed_connect"

local PRIORITY_MISMATCH = 3
local PRIORITY_UPDATE = 3
local PRIORITY_FAILED = 2

local WATCHDOG_TIMEOUT_MS = 15000

-- Per-StartMod state, reset on Bridge.Init
ChaosBridgeHandshake.shown = {} ---@type table<string, boolean>
ChaosBridgeHandshake.watchdogActive = false
ChaosBridgeHandshake.watchdogAccumMs = 0
ChaosBridgeHandshake.lastHandshake = nil ---@type table | nil

-- Persists across StartMod cycles within the same game session
ChaosBridgeHandshake.handshakeReceivedThisSession = false

---@return string
local function getModVersion()
    if ChaosMod and ChaosMod.modData then
        return ChaosMod.modData:getModVersion() or "0"
    end
    return "0"
end

---@param a string
---@param b string
---@return string -- The greater of a and b by CompareVersions; ties return a
local function maxVersion(a, b)
    if ChaosUtils.CompareVersions(a, b) < 0 then
        return b
    end
    return a
end

---@param payload table
---@return string streamerVersion
---@return boolean hasNewUpdate
---@return string newUpdateVersion
local function parseHandshakePayload(payload)
    local streamerVersion = type(payload.streamer_mode_version) == "string"
        and payload.streamer_mode_version or ""
    local hasNewUpdate = payload.has_new_update == true
    local newUpdateVersion = type(payload.new_update_version) == "string"
        and payload.new_update_version or ""
    return streamerVersion, hasNewUpdate, newUpdateVersion
end

---@param category string
local function markDismissed(category)
    ChaosBridgeHandshake.shown[category] = true
end

---@param category string
---@return ChaosModalWindowButton
local function makeOpenGitHubButton(category)
    return {
        label = "Open GitHub",
        accent = "accept",
        onClick = function(window)
            ChaosBridge.Emit("open_github", nil)
            markDismissed(category)
            window:closeWindow()
        end,
    }
end

---@param category string
---@return ChaosModalWindowButton
local function makeCloseButton(category)
    return {
        label = "Close",
        onClick = function(window)
            markDismissed(category)
            window:closeWindow()
        end,
    }
end

---@param category string
---@param priority integer
---@param title string
---@param body string
---@param withGitHubButton boolean
local function openOrUpdateModal(category, priority, title, body, withGitHubButton)
    local current = ChaosModalWindow.current

    -- If a modal of the SAME category is open, update its content in place (no shown flip).
    if current and current.category == category then
        if current.title ~= title or table.concat(current.bodyLines, "\n") ~= body then
            current:closeWindow()
        else
            return -- identical, nothing to do
        end
    end

    -- Skip if a higher-priority modal is currently open.
    local nowOpen = ChaosModalWindow.current
    if nowOpen and nowOpen.priority > priority then
        return
    end

    -- Don't re-open a category the user already dismissed this StartMod.
    if ChaosBridgeHandshake.shown[category] then
        return
    end

    local buttons = {}
    if withGitHubButton then
        table.insert(buttons, makeOpenGitHubButton(category))
    end
    table.insert(buttons, makeCloseButton(category))

    ChaosModalWindow.Open({
        category = category,
        priority = priority,
        title = title,
        body = body,
        buttons = buttons,
    })
end

---@param modVersion string
---@param streamerVersion string
---@param hasNewUpdate boolean
---@param newUpdateVersion string
---@return string body
local function composeMismatchBody(modVersion, streamerVersion, hasNewUpdate, newUpdateVersion)
    local cmp = ChaosUtils.CompareVersions(modVersion, streamerVersion)
    if cmp > 0 then
        -- Mod is ahead of app — telling user to download a new update doesn't apply.
        return string.format(
            "Your mod version is %s, but your Streamer App version is %s.\nUpdate the Streamer App to match",
            modVersion, streamerVersion)
    end
    -- mod < app
    local target = streamerVersion
    if hasNewUpdate and newUpdateVersion ~= "" then
        target = maxVersion(target, newUpdateVersion)
    end
    target = maxVersion(target, modVersion)
    return string.format(
        "Your mod version is %s, but your Streamer App version is %s.\nDownload new update %s\nResubscribe in Steam Workshop to download new update",
        modVersion, streamerVersion, target)
end

--- Evaluates the latest handshake payload and opens/updates/closes a modal accordingly.
local function evaluate()
    local handshake = ChaosBridgeHandshake.lastHandshake
    if not handshake then return end

    local modVersion = getModVersion()
    local streamerVersion, hasNewUpdate, newUpdateVersion = parseHandshakePayload(handshake)

    -- Decide category from current state.
    local category = nil ---@type string?
    if streamerVersion ~= "" and ChaosUtils.CompareVersions(modVersion, streamerVersion) ~= 0 then
        category = CATEGORY_MISMATCH
    elseif hasNewUpdate and newUpdateVersion ~= ""
        and ChaosUtils.CompareVersions(modVersion, newUpdateVersion) < 0 then
        category = CATEGORY_UPDATE
    end

    if category == nil then
        -- No issue — close any version-related modal that may be open.
        ChaosModalWindow.CloseIfCategory(CATEGORY_MISMATCH)
        ChaosModalWindow.CloseIfCategory(CATEGORY_UPDATE)
        return
    end

    if category == CATEGORY_MISMATCH then
        local body = composeMismatchBody(modVersion, streamerVersion, hasNewUpdate, newUpdateVersion)
        openOrUpdateModal(CATEGORY_MISMATCH, PRIORITY_MISMATCH, "Version Mismatch", body, true)
    else
        local body = string.format(
            "Mod update %s available with StreamerApp update\nAlso resubscribe in Steam Workshop to download new update",
            newUpdateVersion)
        openOrUpdateModal(CATEGORY_UPDATE, PRIORITY_UPDATE, "New Update Available", body, true)
    end
end

---@param payload table
function ChaosBridgeHandshake.OnHandshake(payload)
    if type(payload) ~= "table" then return end

    ChaosBridgeHandshake.handshakeReceivedThisSession = true
    ChaosBridgeHandshake.watchdogActive = false
    ChaosBridgeHandshake.watchdogAccumMs = 0
    ChaosBridgeHandshake.lastHandshake = payload

    -- A real handshake supersedes the failed-connect modal (if any).
    ChaosModalWindow.CloseIfCategory(CATEGORY_FAILED)

    evaluate()
end

---@param deltaMs integer
function ChaosBridgeHandshake.Tick(deltaMs)
    if not ChaosBridgeHandshake.watchdogActive then return end
    ChaosBridgeHandshake.watchdogAccumMs = ChaosBridgeHandshake.watchdogAccumMs + (deltaMs or 0)
    if ChaosBridgeHandshake.watchdogAccumMs < WATCHDOG_TIMEOUT_MS then return end

    ChaosBridgeHandshake.watchdogActive = false
    ChaosBridgeHandshake.watchdogAccumMs = 0

    if ChaosBridgeHandshake.shown[CATEGORY_FAILED] then return end
    if ChaosBridgeHandshake.handshakeReceivedThisSession then return end

    local body = "The Streamer App is not running or has an outdated version\n"
        .. "(This is shown to you because you have voting_enabled or enable_donate in settings)"
    openOrUpdateModal(CATEGORY_FAILED, PRIORITY_FAILED, "StreamerApp: Failed to connect", body, false)
end

--- Called from ChaosBridge.Init when streamer mode starts. Resets per-StartMod
--- shown flags and arms the watchdog if voting/donate is enabled and we have
--- not yet seen a handshake during this game session.
function ChaosBridgeHandshake.OnBridgeInit()
    ChaosBridgeHandshake.shown = {}
    ChaosBridgeHandshake.watchdogActive = false
    ChaosBridgeHandshake.watchdogAccumMs = 0
    ChaosBridgeHandshake.lastHandshake = nil

    local sm = ChaosConfig and ChaosConfig.streamer_mode
    if not sm then return end

    local arm = (sm.voting_enabled == true) or (sm.enable_donate == true)
    if arm and not ChaosBridgeHandshake.handshakeReceivedThisSession then
        ChaosBridgeHandshake.watchdogActive = true
    end
end

--- Called from ChaosBridge.Shutdown when streamer mode stops. Closes any open
--- modal that this handshake module owns and stops the watchdog.
function ChaosBridgeHandshake.OnBridgeShutdown()
    ChaosBridgeHandshake.watchdogActive = false
    ChaosBridgeHandshake.watchdogAccumMs = 0
    ChaosModalWindow.CloseIfCategory(CATEGORY_MISMATCH)
    ChaosModalWindow.CloseIfCategory(CATEGORY_UPDATE)
    ChaosModalWindow.CloseIfCategory(CATEGORY_FAILED)
end

return ChaosBridgeHandshake
