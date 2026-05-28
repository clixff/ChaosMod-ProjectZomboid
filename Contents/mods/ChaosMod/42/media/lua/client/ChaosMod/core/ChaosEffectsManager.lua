---@alias ChaosEffectActivationType "vote" | "interval" | "donate" | "cheat"

---@type { VOTE: ChaosEffectActivationType, INTERVAL: ChaosEffectActivationType, DONATE: ChaosEffectActivationType, CHEAT: ChaosEffectActivationType }
ChaosEffectActivationType = {
    VOTE = "vote",         -- Streamer-mode vote winner
    INTERVAL = "interval", -- Triggered automatically by the global effects timer
    DONATE = "donate",     -- Activated by a donation through StreamerMode
    CHEAT = "cheat",       -- Activated manually from the in-game effects window UI
}

---@param activationType any
---@return ChaosEffectActivationType
local function NormalizeActivationType(activationType)
    if activationType == ChaosEffectActivationType.VOTE
        or activationType == ChaosEffectActivationType.INTERVAL
        or activationType == ChaosEffectActivationType.DONATE
        or activationType == ChaosEffectActivationType.CHEAT then
        return activationType
    end
    return ChaosEffectActivationType.INTERVAL
end

---@class ChaosFakeVisualEffect
---@field displayName string
---@field timeMs number -- remaining display time in ms

---@class ChaosEffectsManager
---@field activeEffects table<integer, ChaosEffectBase>
---@field fakeVisualEffects ChaosFakeVisualEffect[] -- UI-only decoy rows shown for fake vote effects
---@field globalTimerMs number -- current elapsed ms, counts 0 → globalTimerMaxMs
---@field globalTimerMaxMs number -- effects_interval in ms
---@field iterationIndex integer -- increments each time globalTimer fires
---@field voteStartedThisInterval boolean -- true after vote_start has been emitted in the current interval
ChaosEffectsManager = ChaosEffectsManager or {
    activeEffects = {},
    fakeVisualEffects = {},
    globalTimerMs = 0,
    globalTimerMaxMs = 0,
    iterationIndex = 0,
    voteStartedThisInterval = false,
}

-- Fake (1) / Hidden (2) vote effects are concealed in the effects UI for a while
-- before being revealed with a "[Fake] " / "[Hidden] " prefix.
--
-- Hidden: concealed 20s, then revealed. No-duration shows for 10s after reveal (30s total).
ChaosEffectsManager.HIDDEN_REVEAL_DELAY_MS = 20 * 1000       -- how long a hidden effect stays concealed
ChaosEffectsManager.HIDDEN_NO_DURATION_MAX_TICKS = 30 * 1000 -- 20s concealed + 10s revealed
--
-- Fake: decoy shown 15s, then 10s of nothing, then the real effect revealed at 25s.
-- No-duration shows for 10s after reveal (35s total).
ChaosEffectsManager.FAKE_DECOY_MS = 15 * 1000              -- how long the decoy row is shown
ChaosEffectsManager.FAKE_REVEAL_DELAY_MS = 25 * 1000       -- 15s decoy + 10s gap before the real effect is revealed
ChaosEffectsManager.FAKE_NO_DURATION_MAX_TICKS = 35 * 1000 -- 25s concealed + 10s revealed

function ChaosEffectsManager.StartGlobalTimer()
    ChaosEffectsManager.globalTimerMaxMs = math.floor(ChaosConfig.effects_interval * 1000)
    ChaosEffectsManager.globalTimerMs = 0
    ChaosEffectsManager.voteStartedThisInterval = false
end

function ChaosEffectsManager.ClearGlobalTimer()
    ChaosEffectsManager.globalTimerMs = 0
    ChaosEffectsManager.globalTimerMaxMs = 0
    ChaosEffectsManager.voteStartedThisInterval = false
end

--- Returns how many effects this cycle should activate (1 by default; >1 when
--- combo_time meta effect is active). Streamer-side voting branch handles its
--- own multi-winner selection via meta state tracking.
---@return integer
local function getEffectsCountForThisCycle()
    if not ChaosMetaEffectsManager or not ChaosMetaEffectsManager.GetActive then
        return 1
    end
    ---@type MetaEffectComboTime | nil
    local combo = ChaosMetaEffectsManager.GetActive("combo_time")
    if not combo or not combo.GetEffectsCount then return 1 end
    local n = combo:GetEffectsCount()
    if type(n) ~= "number" or n < 1 then return 1 end
    return math.floor(n)
end

--- Picks N effects via weighted random, dropping picks that conflict with
--- already-chosen picks via `disable_effects` and re-rolling from the remaining
--- pool. May return fewer than N if the pool runs dry.
---@param amount integer
---@return string[]
local function pickComboEffects(amount)
    if amount <= 1 then
        return ChaosEffectsRegistry.GetRandomEffects(1, "default")
    end

    local chosen = {} ---@type string[]
    local chosenSet = {} ---@type table<string, boolean>
    local pickedTries = 0
    local maxTries = amount * 4
    while #chosen < amount and pickedTries < maxTries do
        pickedTries = pickedTries + 1
        local rolled = ChaosEffectsRegistry.GetRandomEffects(1, "default")
        local candidate = rolled and rolled[1] or nil
        if not candidate then break end
        if chosenSet[candidate] then
            -- Already picked this exact id; try again.
        else
            local conflict = false
            local candidateData = ChaosEffectsRegistry.effects[candidate]
            local candidateDisables = candidateData and candidateData.disableEffects or {}
            for _, otherId in ipairs(chosen) do
                if otherId == candidate then conflict = true; break end
                for _, d in ipairs(candidateDisables) do
                    if d == otherId then conflict = true; break end
                end
                if conflict then break end
                local otherData = ChaosEffectsRegistry.effects[otherId]
                local otherDisables = otherData and otherData.disableEffects or {}
                for _, d in ipairs(otherDisables) do
                    if d == candidate then conflict = true; break end
                end
                if conflict then break end
            end
            if not conflict then
                table.insert(chosen, candidate)
                chosenSet[candidate] = true
            end
        end
    end
    return chosen
end

function ChaosEffectsManager.OnGlobalEffectsTimerEnd()
    if not ChaosConfig.IsEffectsEnabled() then return end
    local sm = ChaosConfig.streamer_mode
    if not sm or sm.streamer_mode_enabled == false or sm.voting_enabled == false then
        local count = getEffectsCountForThisCycle()
        local effectIds = pickComboEffects(count)
        for _, id in ipairs(effectIds) do
            ChaosEffectsManager.StartEffect(id, nil, ChaosEffectActivationType.INTERVAL)
        end
    end
    if sm and sm.streamer_mode_enabled == true then
        ChaosEffectsManager.iterationIndex = ChaosEffectsManager.iterationIndex + 1
        ChaosEffectsManager.voteStartedThisInterval = false
        ChaosBridge.Emit("interval_start", {
            iteration = ChaosEffectsManager.iterationIndex,
            meta_effects = ChaosMetaEffectsManager.GetActiveIds(),
        })
    end
end

---@param effectId string
---@param effectNickname string | nil
---@param activationType ChaosEffectActivationType | nil
---@param voteFakeType integer | nil -- 1 = fake vote effect, 2 = hidden vote effect (concealed in UI)
---@return ChaosEffectBase | nil
function ChaosEffectsManager.StartEffect(effectId, effectNickname, activationType, voteFakeType)
    if not effectId or effectId == "" then
        print("[ChaosEffectsManager] Effect ID is required")
        return
    end

    local effectData = ChaosEffectsRegistry.effects[effectId]
    if not effectData then
        print("[ChaosEffectsManager] Effect not found")
        return
    end

    if not effectData.class then
        print("[ChaosEffectsManager] Effect class not found")
        return
    end

    if effectData.disableEffects and #effectData.disableEffects > 0 then
        ChaosEffectsManager.DisableSpecificEffects(effectData.disableEffects)
    end

    local effectClass = effectData.class
    local durationMultiplier = ChaosConfig.effects_duration_multiplier
    if type(durationMultiplier) ~= "number" or durationMultiplier <= 0 then
        durationMultiplier = 1
    end
    local scaledDuration = (effectData.duration or 0) * durationMultiplier
    local resolvedActivationType = NormalizeActivationType(activationType)
    local newEffect = effectClass:new(effectId, effectData.name, scaledDuration, effectData.withDuration,
        effectNickname, resolvedActivationType)
    if not newEffect then return end

    newEffect:OnStart()

    -- Fake (1) / Hidden (2) vote effects are concealed in the UI. Hidden effects
    -- also suppress the activation sound so nothing tips off the streamer; fake
    -- effects keep the sound, since a decoy row appears in their place.
    local fakeType = (voteFakeType == 1 or voteFakeType == 2) and voteFakeType or nil
    if fakeType ~= 2 then
        ChaosUtils.PlayUISound("UIPauseMenuEnter")
    end

    local msNow = getTimestampMs()

    newEffect.activationTimeMs = msNow
    newEffect.ticksActiveTime = 0
    newEffect.maxTicks = math.floor(newEffect.duration * 1000)

    if newEffect.withDuration == false then
        newEffect.maxTicks = 15 * 1000
    end

    if fakeType then
        newEffect.uiHidden = true
        local sm = ChaosConfig.streamer_mode
        -- When reveal-after-delay is off, leave uiRevealDelayMs unset so the effect
        -- stays concealed for its whole life (and skip the no-duration display bump).
        if fakeType == 1 then
            newEffect.uiRevealPrefix = "[Fake] "
            if not sm or sm.reveal_fake_effect_after_delay ~= false then
                newEffect.uiRevealDelayMs = ChaosEffectsManager.FAKE_REVEAL_DELAY_MS
                if newEffect.withDuration == false then
                    newEffect.maxTicks = ChaosEffectsManager.FAKE_NO_DURATION_MAX_TICKS
                end
            end
        else
            newEffect.uiRevealPrefix = "[Hidden] "
            if not sm or sm.reveal_hidden_effect_after_delay ~= false then
                newEffect.uiRevealDelayMs = ChaosEffectsManager.HIDDEN_REVEAL_DELAY_MS
                if newEffect.withDuration == false then
                    newEffect.maxTicks = ChaosEffectsManager.HIDDEN_NO_DURATION_MAX_TICKS
                end
            end
        end
    end

    table.insert(ChaosEffectsManager.activeEffects, newEffect)
    return newEffect
end

---@param deltaMs integer
function ChaosEffectsManager.OnTick(deltaMs)
    if ChaosMod.enabled and ChaosConfig.IsEffectsEnabled() then
        ChaosEffectsManager.globalTimerMs = ChaosEffectsManager.globalTimerMs + deltaMs
        if ChaosEffectsManager.globalTimerMs >= ChaosEffectsManager.globalTimerMaxMs then
            ChaosEffectsManager.OnGlobalEffectsTimerEnd()
            ChaosEffectsManager.globalTimerMs = 0
        end

        local sm = ChaosConfig.streamer_mode
        if sm and sm.streamer_mode_enabled == true and sm.voting_enabled == true
            and not ChaosEffectsManager.voteStartedThisInterval then
            local voteStartMs = (ChaosConfig.vote_start_time or 0) * 1000
            if ChaosEffectsManager.globalTimerMs >= voteStartMs then
                ChaosEffectsManager.voteStartedThisInterval = true
                local optionsCount = math.floor(sm.voting_options_number or 4)
                local includeRandom = sm.random_effect_in_vote ~= false
                local visibleCount = includeRandom
                    and math.max(0, optionsCount - 1)
                    or math.max(0, optionsCount)
                local visibleEffects = ChaosEffectsRegistry.GetRandomEffects(visibleCount, "default", true)
                local payload = {
                    effects = visibleEffects,
                    meta_effects = ChaosMetaEffectsManager.GetActiveIds(),
                }
                if includeRandom then
                    local secretEffects = ChaosEffectsRegistry.GetRandomEffects(1, "default", false)
                    if secretEffects[1] then
                        payload.secret_effect = secretEffects[1]
                    end
                end
                ChaosBridge.Emit("vote_start", payload)
            end
        end
    end

    -- Backward loop to avoid issues with removing items from the table while iterating
    for i = #ChaosEffectsManager.activeEffects, 1, -1 do
        local shouldRemove = false
        local effect = ChaosEffectsManager.activeEffects[i]
        if not effect then
            shouldRemove = true
        else
            if effect.withDuration then
                effect:OnTick(deltaMs)
            end

            effect.ticksActiveTime = effect.ticksActiveTime + deltaMs

            -- Reveal a concealed fake/hidden effect once its conceal window passes.
            if effect.uiHidden and effect.uiRevealDelayMs
                and effect.ticksActiveTime >= effect.uiRevealDelayMs then
                effect.uiHidden = false
            end

            if effect.ticksActiveTime >= effect.maxTicks then
                effect:OnEnd()
                shouldRemove = true
            end
        end

        if shouldRemove then
            table.remove(ChaosEffectsManager.activeEffects, i)
        end
    end

    -- Tick down fake (decoy) visual-only rows; they carry no effect logic.
    for i = #ChaosEffectsManager.fakeVisualEffects, 1, -1 do
        local fv = ChaosEffectsManager.fakeVisualEffects[i]
        if not fv then
            table.remove(ChaosEffectsManager.fakeVisualEffects, i)
        else
            fv.timeMs = fv.timeMs - deltaMs
            if fv.timeMs <= 0 then
                table.remove(ChaosEffectsManager.fakeVisualEffects, i)
            end
        end
    end
end

--- Adds a UI-only decoy row that shows `displayName` for `timeMs` milliseconds.
--- Used by fake vote effects to display a plausible (no-duration) effect name
--- while the real effect runs concealed.
---@param displayName string
---@param timeMs number
function ChaosEffectsManager.AddFakeVisualEffect(displayName, timeMs)
    if not displayName or displayName == "" then return end
    table.insert(ChaosEffectsManager.fakeVisualEffects, {
        displayName = displayName,
        timeMs = timeMs,
    })
end

---@param effectIds table<integer, string>
function ChaosEffectsManager.DisableSpecificEffects(effectIds)
    if not effectIds or #effectIds == 0 then
        return
    end

    ---@type table<string, boolean>
    local effectIdsToDisableMap = {}

    for _, effectId in ipairs(effectIds) do
        effectIdsToDisableMap[effectId] = true
    end

    -- Backward loop in activeEffects table to avoid issues
    for i = #ChaosEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosEffectsManager.activeEffects[i]
        if effect then
            local activeEffectId = effect.effectId
            -- If effectID is found in map of effects to disable
            if effectIdsToDisableMap[activeEffectId] then
                -- Call method that will clean up the effect
                effect:OnEnd()
                -- Remove effect from activeEffects table
                table.remove(ChaosEffectsManager.activeEffects, i)
            end
        end
    end
end

--- Refreshes the localized `effectName` field on every currently active effect, so the
--- active effects UI shows the new translation immediately after a language change.
function ChaosEffectsManager.RefreshActiveEffectNames()
    if not ChaosEffectsManager.activeEffects then return end
    for _, effect in ipairs(ChaosEffectsManager.activeEffects) do
        if effect and effect.effectId then
            effect.effectName = ChaosLocalization.GetString("effects", effect.effectId)
        end
    end
end

function ChaosEffectsManager.StopAllEffects()
    for i = #ChaosEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosEffectsManager.activeEffects[i]
        if effect then
            effect:OnEnd()
            table.remove(ChaosEffectsManager.activeEffects, i)
        end
    end
    ChaosEffectsManager.fakeVisualEffects = {}
end
