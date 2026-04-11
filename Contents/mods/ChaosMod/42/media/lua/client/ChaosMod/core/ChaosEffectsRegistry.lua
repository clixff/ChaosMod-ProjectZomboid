---@class ChaosEffectDataEntry
---@field id string
---@field name string
---@field enabled boolean
---@field chance number
---@field withDuration boolean
---@field duration number
---@field disableEffects table<integer, string>
---@field class ChaosEffectBase

---@class ChaosEffectJsonData
---@field id string?
---@field name string?
---@field enabled boolean?
---@field chance number?
---@field withDuration boolean?
---@field duration number?
---@field disable_effects table<integer, string>?

---@class ChaosEffectsRegistry
---@field effects table<string, ChaosEffectDataEntry>
---@field effectsEnabledCount number
ChaosEffectsRegistry = ChaosEffectsRegistry or {}

---@type table<string, ChaosEffectBase>
ChaosEffectsClassMap = ChaosEffectsClassMap or {}

function ChaosEffectsRegistry.Initialize()
    --- Remove old effects
    ChaosEffectsRegistry.effects = {}

    local enabledEffects = 0;
    local totalEffects = 0;
    local effectsData = ChaosFileReader.ReadJsonFile("effects.json")
    if not effectsData then
        print("[ChaosEffectsRegistry] Failed to load effects data")
        return
    end
    if not effectsData.effects then
        print("[ChaosEffectsRegistry] No effects in json array")
        return
    end
    for _, _effectJsonData in ipairs(effectsData.effects) do
        ---@type ChaosEffectJsonData
        local effectJsonData = _effectJsonData
        print("[ChaosEffectsRegistry] Effect JSON Data: " .. tostring(effectJsonData))

        local newEffectData = ChaosEffectsRegistry.CreateNewEffectData(effectJsonData)
        if newEffectData then
            print("[ChaosEffectsRegistry] Adding effect data for ID: " .. tostring(newEffectData.id))
            ChaosEffectsRegistry.effects[newEffectData.id] = newEffectData
            if newEffectData.enabled then
                enabledEffects = enabledEffects + 1
            end
            totalEffects = totalEffects + 1
        end
    end
    local resultString = string.format("[ChaosMod] Loaded %d effects, %d enabled", totalEffects,
        enabledEffects)
    print(resultString)
    ChaosEffectsRegistry.effectsEnabledCount = enabledEffects
end

---@param effectJsonData ChaosEffectJsonData
---@return ChaosEffectDataEntry | nil
function ChaosEffectsRegistry.CreateNewEffectData(effectJsonData)
    if not effectJsonData then
        return nil
    end

    local effectId = effectJsonData.id or ""
    if effectId == "" then
        print("[ChaosEffectsRegistry] Effect ID is required")
        return nil
    end
    local effectClass = ChaosEffectsClassMap[effectId]
    print("[ChaosEffectsRegistry] Effect class: " .. tostring(effectClass))
    if not effectClass then
        print("[ChaosEffectsRegistry] Effect class not found for ID: " .. tostring(effectId))
        return nil
    end

    ---@type ChaosEffectDataEntry
    local newEffectData = {
        id = effectId,
        name = effectJsonData.name or "",
        enabled = effectJsonData.enabled or false,
        chance = effectJsonData.chance or 0,
        withDuration = effectJsonData.withDuration or false,
        duration = effectJsonData.duration or 0,
        class = effectClass,
        disableEffects = {}
    }

    -- Push disable_effects from json to new effect data
    if effectJsonData.disable_effects then
        for _, disableEffectId in ipairs(effectJsonData.disable_effects) do
            table.insert(newEffectData.disableEffects, disableEffectId)
        end
    end

    return newEffectData
end
