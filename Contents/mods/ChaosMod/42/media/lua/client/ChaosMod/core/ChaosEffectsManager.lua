---@class ChaosEffectsManager
---@field activeEffects table<integer, ChaosEffectBase>
---@field globalTimerMs number -- current elapsed ms, counts 0 → globalTimerMaxMs
---@field globalTimerMaxMs number -- effects_interval in ms
ChaosEffectsManager = ChaosEffectsManager or {
    activeEffects = {},
    globalTimerMs = 0,
    globalTimerMaxMs = 0,
}

function ChaosEffectsManager.StartGlobalTimer()
    ChaosEffectsManager.globalTimerMaxMs = math.floor(ChaosConfig.effects_interval * 1000)
    ChaosEffectsManager.globalTimerMs = 0
end

function ChaosEffectsManager.ClearGlobalTimer()
    ChaosEffectsManager.globalTimerMs = 0
    ChaosEffectsManager.globalTimerMaxMs = 0
end

function ChaosEffectsManager.OnGlobalEffectsTimerEnd()
end

---@param effectId string
---@return ChaosEffectBase | nil
function ChaosEffectsManager.StartEffect(effectId)
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
    local newEffect = effectClass:new(effectId, effectData.name, effectData.duration, effectData.withDuration)
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
