---@class ChaosMetaEffectsManager
---@field activeEffects ChaosMetaEffectBase[]
---@field intervalMs number
---@field intervalMaxMs number
ChaosMetaEffectsManager = ChaosMetaEffectsManager or {
    activeEffects = {},
    intervalMs = 0,
    intervalMaxMs = 0,
}

local function getIntervalSec()
    local meta = ChaosConfig.meta_effects
    if type(meta) ~= "table" then return 0 end
    local s = tonumber(meta.interval_sec)
    if not s or s <= 0 then return 0 end
    return s
end

local function isMetaSystemEnabled()
    local meta = ChaosConfig.meta_effects
    return type(meta) == "table" and meta.enabled == true
end

function ChaosMetaEffectsManager.Start()
    ChaosMetaEffectsManager.activeEffects = {}
    ChaosMetaEffectsManager.intervalMs = 0
    ChaosMetaEffectsManager.intervalMaxMs = math.floor(getIntervalSec() * 1000)
end

--- Removes a meta effect from the active list (calls OnEnd and emits bridge end).
---@param id string
---@return boolean removed
function ChaosMetaEffectsManager.StopMetaEffectById(id)
    for i = #ChaosMetaEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosMetaEffectsManager.activeEffects[i]
        if effect and effect.effectId == id then
            effect:OnEnd()
            table.remove(ChaosMetaEffectsManager.activeEffects, i)
            if ChaosBridge and ChaosBridge.Emit then
                ChaosBridge.Emit("meta_effect_end", { id = id })
            end
            return true
        end
    end
    return false
end

--- Activates a meta effect by id. If an instance with the same id is already
--- active, ends and removes it first, then starts a fresh one.
---@param id string
---@return ChaosMetaEffectBase | nil
function ChaosMetaEffectsManager.ActivateById(id)
    local entry = ChaosMetaEffectsRegistry.Get(id)
    if not entry or not entry.class then
        print("[ChaosMetaEffectsManager] Unknown meta effect id: " .. tostring(id))
        return nil
    end

    -- Same-id replace: end the old instance cleanly first.
    ChaosMetaEffectsManager.StopMetaEffectById(id)

    local durationMultiplier = ChaosConfig.effects_duration_multiplier
    if type(durationMultiplier) ~= "number" or durationMultiplier <= 0 then
        durationMultiplier = 1
    end
    local scaledDuration = (entry.duration or 0) * durationMultiplier

    local newEffect = entry.class:new(entry.id, entry.name, scaledDuration, entry.variables)
    if not newEffect then return nil end

    newEffect:OnStart()
    table.insert(ChaosMetaEffectsManager.activeEffects, newEffect)

    if ChaosBridge and ChaosBridge.Emit then
        ChaosBridge.Emit("meta_effect_start", { id = id, duration = scaledDuration })
    end

    return newEffect
end

---@param id string
---@return boolean
function ChaosMetaEffectsManager.IsMetaActive(id)
    for _, effect in ipairs(ChaosMetaEffectsManager.activeEffects) do
        if effect and effect.effectId == id then
            return true
        end
    end
    return false
end

---@return boolean
function ChaosMetaEffectsManager.HasActiveMeta()
    return #ChaosMetaEffectsManager.activeEffects > 0
end

--- Returns an array of effect ids for every currently active meta effect.
--- Used to attach a meta-state snapshot onto bridge events like interval_start
--- and vote_start so the StreamerApp can self-correct its activeMetas set.
---@return string[]
function ChaosMetaEffectsManager.GetActiveIds()
    local ids = {}
    for _, effect in ipairs(ChaosMetaEffectsManager.activeEffects) do
        if effect and effect.effectId then
            table.insert(ids, effect.effectId)
        end
    end
    return ids
end

---@param id string
---@return ChaosMetaEffectBase | nil
function ChaosMetaEffectsManager.GetActive(id)
    for _, effect in ipairs(ChaosMetaEffectsManager.activeEffects) do
        if effect and effect.effectId == id then
            return effect
        end
    end
    return nil
end

---@param deltaMs integer
function ChaosMetaEffectsManager.OnTick(deltaMs)
    if not ChaosMod.enabled then return end

    -- Tick active meta effects first so duration-based end happens even when
    -- effects_interval_enabled is false (so they don't get stuck active).
    for i = #ChaosMetaEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosMetaEffectsManager.activeEffects[i]
        if not effect then
            table.remove(ChaosMetaEffectsManager.activeEffects, i)
        else
            effect:OnTick(deltaMs)
            effect.ticksActiveTime = effect.ticksActiveTime + deltaMs
            if effect.ticksActiveTime >= effect.maxTicks then
                effect:OnEnd()
                table.remove(ChaosMetaEffectsManager.activeEffects, i)
                if ChaosBridge and ChaosBridge.Emit then
                    ChaosBridge.Emit("meta_effect_end", { id = effect.effectId })
                end
            end
        end
    end

    -- Meta interval timer is paused when effects are disabled or meta system is off.
    if not isMetaSystemEnabled() then return end
    if not ChaosConfig.IsEffectsEnabled() then return end

    ChaosMetaEffectsManager.intervalMaxMs = math.floor(getIntervalSec() * 1000)
    if ChaosMetaEffectsManager.intervalMaxMs <= 0 then return end

    ChaosMetaEffectsManager.intervalMs = ChaosMetaEffectsManager.intervalMs + deltaMs
    if ChaosMetaEffectsManager.intervalMs >= ChaosMetaEffectsManager.intervalMaxMs then
        ChaosMetaEffectsManager.intervalMs = 0
        local id = ChaosMetaEffectsRegistry.GetRandomMetaEffectId()
        if id then
            ChaosMetaEffectsManager.ActivateById(id)
        end
    end
end

--- Stops every active meta effect (called on mod stop).
function ChaosMetaEffectsManager.StopAllMetaEffects()
    for i = #ChaosMetaEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosMetaEffectsManager.activeEffects[i]
        if effect then
            effect:OnEnd()
            if ChaosBridge and ChaosBridge.Emit then
                ChaosBridge.Emit("meta_effect_end", { id = effect.effectId })
            end
        end
        table.remove(ChaosMetaEffectsManager.activeEffects, i)
    end
    ChaosMetaEffectsManager.intervalMs = 0
end
