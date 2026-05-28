---@class ChaosMetaEffectDataEntry
---@field id string
---@field name string
---@field enabled boolean
---@field voting_only boolean
---@field chance number
---@field duration number
---@field variables table
---@field class ChaosMetaEffectBase

---@class ChaosMetaEffectsRegistry
---@field effects table<string, ChaosMetaEffectDataEntry>
---@field order string[]
ChaosMetaEffectsRegistry = ChaosMetaEffectsRegistry or {
    effects = {},
    order = {},
}

function ChaosMetaEffectsRegistry.Initialize()
    ChaosMetaEffectsRegistry.effects = {}
    ChaosMetaEffectsRegistry.order = {}

    local meta = ChaosConfig.meta_effects
    if type(meta) ~= "table" or type(meta.list) ~= "table" then
        return
    end

    local total, enabledCount = 0, 0
    for _, item in ipairs(meta.list) do
        if type(item) == "table" and type(item.id) == "string" and item.id ~= "" then
            local class = ChaosMetaEffectsClassMap[item.id]
            if not class then
                print("[ChaosMetaEffectsRegistry] No class registered for meta id: " .. item.id)
            else
                ---@type ChaosMetaEffectDataEntry
                local entry = {
                    id = item.id,
                    name = ChaosLocalization.GetString("effects", item.id),
                    enabled = item.enabled == true,
                    voting_only = item.voting_only == true,
                    chance = tonumber(item.chance) or 0,
                    duration = tonumber(item.duration) or 0,
                    variables = type(item.variables) == "table" and item.variables or {},
                    class = class,
                }
                ChaosMetaEffectsRegistry.effects[item.id] = entry
                table.insert(ChaosMetaEffectsRegistry.order, item.id)
                total = total + 1
                if entry.enabled then enabledCount = enabledCount + 1 end
            end
        end
    end
    print(string.format("[ChaosMetaEffectsRegistry] Loaded %d meta effects, %d enabled", total, enabledCount))
end

--- Picks a random enabled meta effect id via weighted random selection. Returns
--- nil if no enabled meta effect with a positive chance is registered.
---@return string | nil
function ChaosMetaEffectsRegistry.GetRandomMetaEffectId()
    local pool = {}
    local totalWeight = 0.0
    for _, entry in pairs(ChaosMetaEffectsRegistry.effects) do
        if entry.enabled and entry.chance > 0 then
            table.insert(pool, entry)
            totalWeight = totalWeight + entry.chance
        end
    end
    if #pool == 0 or totalWeight <= 0 then return nil end

    local roll = ChaosUtils.RandFloat(0, totalWeight)
    local cumulative = 0
    for _, entry in ipairs(pool) do
        cumulative = cumulative + entry.chance
        if roll <= cumulative then
            return entry.id
        end
    end
    return pool[#pool].id
end

---@param id string
---@return ChaosMetaEffectDataEntry | nil
function ChaosMetaEffectsRegistry.Get(id)
    return ChaosMetaEffectsRegistry.effects[id]
end

function ChaosMetaEffectsRegistry.RefreshNames()
    for id, entry in pairs(ChaosMetaEffectsRegistry.effects) do
        entry.name = ChaosLocalization.GetString("effects", id)
    end
end
