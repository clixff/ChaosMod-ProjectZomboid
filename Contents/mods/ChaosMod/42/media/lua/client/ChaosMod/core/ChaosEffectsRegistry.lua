---@class ChaosEffectDataEntry
---@field id string
---@field name string
---@field enabled boolean
---@field chance integer
---@field withDuration boolean
---@field duration number
---@field disableEffects table<integer, string>
---@field class ChaosEffectBase
---@field enabled_donate boolean
---@field price_group string

---@class ChaosEffectJsonData
---@field id string?
---@field name string?
---@field enabled boolean?
---@field chance integer?
---@field withDuration boolean?
---@field duration number?
---@field disable_effects table<integer, string>?
---@field enabled_donate boolean?
---@field price_group string?

---@class ChaosEffectsRegistry
---@field effects table<string, ChaosEffectDataEntry>
---@field effectsEnabledCount number
ChaosEffectsRegistry = ChaosEffectsRegistry or {}

---@type table<string, ChaosEffectBase>
ChaosEffectsClassMap = ChaosEffectsClassMap or {}

--- Stable order of effect ids as loaded from effects.json (used to preserve file order on save).
---@type string[]
ChaosEffectsRegistry.effectOrder = ChaosEffectsRegistry.effectOrder or {}

function ChaosEffectsRegistry.Initialize()
    --- Remove old effects
    ChaosEffectsRegistry.effects = {}
    ChaosEffectsRegistry.effectOrder = {}

    local enabledEffects = 0;
    local totalEffects = 0;

    ---@type table | nil
    local defaultEffectsData = ChaosFileReader.ReadJsonFile("default_effects.json")

    ---@type table | nil
    local effectsData = ChaosFileReader.ReadJsonFromCache("ChaosMod/effects.json")
    if not effectsData then
        if defaultEffectsData then
            print("[ChaosEffectsRegistry] effects.json not found in user folder; copying default_effects.json")
            ChaosFileReader.WriteJsonToCache("ChaosMod/effects.json", defaultEffectsData)
            effectsData = defaultEffectsData
        end
    elseif defaultEffectsData and type(defaultEffectsData.effects) == "table" then
        if type(effectsData.effects) ~= "table" then
            effectsData.effects = {}
        end
        local existingIds = {}
        for _, effect in ipairs(effectsData.effects) do
            if type(effect) == "table" and type(effect.id) == "string" then
                existingIds[effect.id] = true
            end
        end
        local addedCount = 0
        for _, defEffect in ipairs(defaultEffectsData.effects) do
            if type(defEffect) == "table" and type(defEffect.id) == "string" and not existingIds[defEffect.id] then
                table.insert(effectsData.effects, defEffect)
                existingIds[defEffect.id] = true
                addedCount = addedCount + 1
            end
        end
        if addedCount > 0 then
            print("[ChaosEffectsRegistry] Added " .. tostring(addedCount) .. " missing effect(s) from default_effects.json; saving effects.json")
            ChaosFileReader.WriteJsonToCache("ChaosMod/effects.json", effectsData)
        end
    end

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

        local newEffectData = ChaosEffectsRegistry.CreateNewEffectData(effectJsonData)
        if newEffectData then
            if not ChaosEffectsRegistry.effects[newEffectData.id] then
                table.insert(ChaosEffectsRegistry.effectOrder, newEffectData.id)
            end
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

---@alias ChaosEffectPickType "default" | "donate"

local RECENT_EFFECTS_MAX = 30
---@type table<string, boolean>
local recentEffectsSet = {}
---@type string[]
local recentEffectsQueue = {}

---@param id string
local function addToBlocklist(id)
    if #recentEffectsQueue >= RECENT_EFFECTS_MAX then
        local evicted = table.remove(recentEffectsQueue, 1)
        recentEffectsSet[evicted] = nil
    end
    table.insert(recentEffectsQueue, id)
    recentEffectsSet[id] = true
end

--- Returns an array of randomly selected effect IDs using weighted random selection.
--- Picked effects are added to a rolling blocklist of 12 and cannot be re-selected until evicted.
---@param amount integer
---@param pickType ChaosEffectPickType
---@return string[]
function ChaosEffectsRegistry.GetRandomEffects(amount, pickType)
    local pool = {}
    local totalWeight = 0

    local ignoreChances = ChaosConfig.ignore_effect_chances == true
    for id, effect in pairs(ChaosEffectsRegistry.effects) do
        local eligible = (pickType == "donate") and effect.enabled_donate or effect.enabled
        if eligible and effect.chance > 0 and not recentEffectsSet[id] then
            local weight = ignoreChances and 1 or effect.chance
            table.insert(pool, { id = id, chance = weight })
            totalWeight = totalWeight + weight
        end
    end

    local result = {}

    for _ = 1, amount do
        if totalWeight <= 0 then break end

        local roll = ChaosUtils.RandInteger(totalWeight) + 1
        local cumulative = 0
        local picked = nil
        local pickedIndex = nil

        for i, entry in ipairs(pool) do
            cumulative = cumulative + entry.chance
            if roll <= cumulative then
                picked = entry.id
                pickedIndex = i
                break
            end
        end

        if picked then
            table.insert(result, picked)
            addToBlocklist(picked)
            totalWeight = totalWeight - pool[pickedIndex].chance
            table.remove(pool, pickedIndex)
        end
    end

    return result
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
    if not effectClass then
        print("[ChaosEffectsRegistry] Effect class not found for ID: " .. tostring(effectId))
        return nil
    end

    ---@type ChaosEffectDataEntry
    local newEffectData = {
        id = effectId,
        name = ChaosLocalization.GetString("effects", effectId),
        enabled = effectJsonData.enabled or false,
        chance = math.floor(effectJsonData.chance or 0),
        withDuration = effectJsonData.withDuration or false,
        duration = effectJsonData.duration or 0,
        class = effectClass,
        disableEffects = {},
        enabled_donate = effectJsonData.enabled_donate or false,
        price_group = effectJsonData.price_group or "",
    }

    -- Push disable_effects from json to new effect data
    if effectJsonData.disable_effects then
        for _, disableEffectId in ipairs(effectJsonData.disable_effects) do
            table.insert(newEffectData.disableEffects, disableEffectId)
        end
    end

    return newEffectData
end

---@return table
function ChaosEffectsRegistry.BuildJsonSnapshot()
    local order = ChaosEffectsRegistry.effectOrder or {}
    local seen = {}
    local effectsArr = {}

    local function appendEntry(effect)
        local disable = {}
        if type(effect.disableEffects) == "table" then
            for _, id in ipairs(effect.disableEffects) do
                table.insert(disable, id)
            end
        end
        local entry = {
            id = effect.id,
            enabled = effect.enabled,
            chance = effect.chance,
            withDuration = effect.withDuration,
            duration = effect.duration,
            disable_effects = disable,
            enabled_donate = effect.enabled_donate,
            price_group = effect.price_group,
        }
        table.insert(effectsArr, entry)
    end

    for _, id in ipairs(order) do
        local effect = ChaosEffectsRegistry.effects[id]
        if effect and not seen[id] then
            seen[id] = true
            appendEntry(effect)
        end
    end
    -- Append any effects not in the recorded order (e.g. newly added)
    for id, effect in pairs(ChaosEffectsRegistry.effects) do
        if not seen[id] then
            seen[id] = true
            appendEntry(effect)
            table.insert(order, id)
        end
    end

    return { effects = effectsArr }
end

---@return boolean
function ChaosEffectsRegistry.SaveEffectsToDisk()
    local snapshot = ChaosEffectsRegistry.BuildJsonSnapshot()
    local ok = ChaosFileReader.WriteJsonToCache("ChaosMod/effects.json", snapshot)
    if ok then
        print("[ChaosEffectsRegistry] Saved effects.json")
    else
        print("[ChaosEffectsRegistry] Failed to save effects.json")
    end
    return ok
end

---@return boolean
function ChaosEffectsRegistry.ResetToDefaults()
    local defaults = ChaosFileReader.ReadJsonFile("default_effects.json")
    if not defaults then
        print("[ChaosEffectsRegistry] Cannot reset: default_effects.json not found")
        return false
    end
    if not ChaosFileReader.WriteJsonToCache("ChaosMod/effects.json", defaults) then
        print("[ChaosEffectsRegistry] Failed to write defaults to user effects.json")
        return false
    end
    ChaosEffectsRegistry.Initialize()
    print("[ChaosEffectsRegistry] Reset to defaults complete")
    return true
end
