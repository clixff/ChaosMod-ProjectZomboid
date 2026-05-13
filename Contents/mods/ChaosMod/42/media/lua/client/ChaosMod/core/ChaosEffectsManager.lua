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

---@class ChaosEffectsManager
---@field activeEffects table<integer, ChaosEffectBase>
---@field globalTimerMs number -- current elapsed ms, counts 0 → globalTimerMaxMs
---@field globalTimerMaxMs number -- effects_interval in ms
---@field iterationIndex integer -- increments each time globalTimer fires
---@field voteStartedThisInterval boolean -- true after vote_start has been emitted in the current interval
ChaosEffectsManager = ChaosEffectsManager or {
    activeEffects = {},
    globalTimerMs = 0,
    globalTimerMaxMs = 0,
    iterationIndex = 0,
    voteStartedThisInterval = false,
}

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

function ChaosEffectsManager.OnGlobalEffectsTimerEnd()
    if not ChaosConfig.IsEffectsEnabled() then return end
    local sm = ChaosConfig.streamer_mode
    if not sm or sm.streamer_mode_enabled == false or sm.voting_enabled == false then
        local effectIds = ChaosEffectsRegistry.GetRandomEffects(1, "default")
        if effectIds and effectIds[1] then
            ChaosEffectsManager.StartEffect(effectIds[1], nil, ChaosEffectActivationType.INTERVAL)
        end
    end
    if sm and sm.streamer_mode_enabled == true then
        ChaosEffectsManager.iterationIndex = ChaosEffectsManager.iterationIndex + 1
        ChaosEffectsManager.voteStartedThisInterval = false
        ChaosBridge.Emit("interval_start", { iteration = ChaosEffectsManager.iterationIndex })
    end
end

---@param effectId string
---@param effectNickname string | nil
---@param activationType ChaosEffectActivationType | nil
---@return ChaosEffectBase | nil
function ChaosEffectsManager.StartEffect(effectId, effectNickname, activationType)
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
    ChaosUtils.PlayUISound("UIPauseMenuEnter")

    local msNow = getTimestampMs()

    newEffect.activationTimeMs = msNow
    newEffect.ticksActiveTime = 0
    newEffect.maxTicks = math.floor(newEffect.duration * 1000)

    if newEffect.withDuration == false then
        newEffect.maxTicks = 15 * 1000
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
                ChaosBridge.Emit("vote_start", nil)
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
            if effect.ticksActiveTime >= effect.maxTicks then
                effect:OnEnd()
                shouldRemove = true
            end
        end

        if shouldRemove then
            table.remove(ChaosEffectsManager.activeEffects, i)
        end
    end
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

function ChaosEffectsManager.StopAllEffects()
    for i = #ChaosEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosEffectsManager.activeEffects[i]
        if effect then
            effect:OnEnd()
            table.remove(ChaosEffectsManager.activeEffects, i)
        end
    end
end
