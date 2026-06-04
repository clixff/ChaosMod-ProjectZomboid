---@class ChaosEffectDataEntry
---@field id string
---@field name string
---@field enabled boolean
---@field chance number
---@field withDuration boolean
---@field duration number
---@field disableEffects table<integer, string>
---@field class ChaosEffectBase
---@field enabled_donate boolean
---@field price_group string
---@field tags string[] -- normalized lowercase tags (mod-owned, from default_effects.json)
---@field tagsSet table<string, true> -- set view of `tags` for O(1) lookup

---@class ChaosEffectJsonData
---@field id string?
---@field name string?
---@field enabled boolean?
---@field chance number?
---@field withDuration boolean?
---@field duration number?
---@field disable_effects table<integer, string>?
---@field enabled_donate boolean?
---@field price_group string?
---@field tags table<integer, string>? -- optional, only read from default_effects.json

---@class ChaosEffectsRegistry
---@field effects table<string, ChaosEffectDataEntry>
---@field effectsEnabledCount number
ChaosEffectsRegistry = ChaosEffectsRegistry or {}

---@type table<string, ChaosEffectBase>
ChaosEffectsClassMap = ChaosEffectsClassMap or {}

--- Stable order of effect ids as loaded from effects.json (used to preserve file order on save).
---@type string[]
ChaosEffectsRegistry.effectOrder = ChaosEffectsRegistry.effectOrder or {}


local DEBUG_LOGS_CONTEXT_AWARE_SYSTEM = false

--- Tags are mod-owned: read from default_effects.json only, never from the user's
--- effects.json (and intentionally not written back by BuildJsonSnapshot).
---@type table<string, {tags: string[], set: table<string, true>}>
local defaultEffectTags = {}

--- Normalizes a raw json tags array: trims, lowercases, drops non-strings/empties, dedupes.
---@param rawTags any
---@return string[], table<string, true>
local function normalizeTags(rawTags)
    local tags = {}
    local set = {}
    if type(rawTags) == "table" then
        for _, tag in ipairs(rawTags) do
            if type(tag) == "string" then
                local normalized = tag:lower():match("^%s*(.-)%s*$")
                if normalized ~= "" and not set[normalized] then
                    table.insert(tags, normalized)
                    set[normalized] = true
                end
            end
        end
    end
    return tags, set
end

function ChaosEffectsRegistry.Initialize()
    --- Remove old effects
    ChaosEffectsRegistry.effects = {}
    ChaosEffectsRegistry.effectOrder = {}

    local enabledEffects = 0;
    local totalEffects = 0;

    ChaosEffectsRegistry.SyncEffectsForModVersion()

    ---@type table | nil
    local defaultEffectsData = ChaosFileReader.ReadJsonFile("default_effects.json")

    for k in pairs(defaultEffectTags) do defaultEffectTags[k] = nil end
    if defaultEffectsData and type(defaultEffectsData.effects) == "table" then
        for _, defEffect in ipairs(defaultEffectsData.effects) do
            if type(defEffect) == "table" and type(defEffect.id) == "string" and defEffect.tags ~= nil then
                local tags, set = normalizeTags(defEffect.tags)
                if #tags > 0 then
                    defaultEffectTags[defEffect.id] = { tags = tags, set = set }
                end
            end
        end
    end

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
            print("[ChaosEffectsRegistry] Added " ..
                tostring(addedCount) .. " missing effect(s) from default_effects.json; saving effects.json")
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

    ChaosEffectsRegistry.EnsureRecentEffectsLoaded()
end

--- If VERSION.txt is missing, empty or different from the current mod version,
--- overwrite the user's effects.json with the shipped default_effects.json
--- and rewrite VERSION.txt. Must run before effects.json is loaded into memory.
function ChaosEffectsRegistry.SyncEffectsForModVersion()
    local currentVersion = ""
    if ChaosMod.modData then
        currentVersion = ChaosMod.modData:getModVersion() or ""
    end

    local storedRaw = ChaosFileReader.ReadFileFromCacheAllLines("ChaosMod/VERSION.txt")
    local storedVersion = ""
    if storedRaw then
        storedVersion = storedRaw:match("^%s*(.-)%s*$") or ""
    end

    if storedVersion == currentVersion then
        return
    end

    -- If VERSION.txt is newer than the current mod version (the user downgraded
    -- the mod), keep the user's effects.json untouched and leave VERSION.txt as
    -- the newer marker. Only an upgrade (or unparseable/missing stored version)
    -- resets effects.json to the shipped defaults.
    if ChaosUtils.CompareVersions(storedVersion, currentVersion) > 0 then
        print(string.format(
            "[ChaosEffectsRegistry] Stored version '%s' is newer than current '%s'; keeping effects.json (downgrade)",
            storedVersion, currentVersion))
        return
    end

    print(string.format(
        "[ChaosEffectsRegistry] Mod version changed ('%s' -> '%s'); replacing effects.json with defaults",
        storedVersion, currentVersion))

    local defaults = ChaosFileReader.ReadJsonFile("default_effects.json")
    if defaults then
        local existingRaw = ChaosFileReader.ReadFileFromCacheAllLines("ChaosMod/effects.json")
        if existingRaw then
            if ChaosFileReader.WriteTextToCache("ChaosMod/effects.json.backup", existingRaw) then
                print("[ChaosEffectsRegistry] Backed up effects.json to effects.json.backup")
            else
                print("[ChaosEffectsRegistry] Failed to write effects.json.backup; proceeding with overwrite")
            end
        end
        ChaosFileReader.WriteJsonToCache("ChaosMod/effects.json", defaults)
    else
        print("[ChaosEffectsRegistry] default_effects.json not found; cannot replace effects.json")
    end

    ChaosFileReader.WriteTextToCache("ChaosMod/VERSION.txt", currentVersion)
end

---@alias ChaosEffectPickType "default" | "donate"

---@type table<string, boolean>
local recentEffectsSet = {}
---@type string[]
local recentEffectsQueue = {}

local RECENT_EFFECTS_FILE = "ChaosMod/recent_effects.txt"
local RECENT_EFFECTS_SAVE_INTERVAL_MS = 5000
local recentEffectsLoaded = false
local recentEffectsDirty = false
local recentEffectsLastWriteMs = 0

---@return integer
local function getRecentEffectsMax()
    local v = ChaosConfig.recent_effects_block_buffer
    if type(v) ~= "number" or v < 0 then return 90 end
    return math.floor(v)
end

local function writeRecentEffectsToDisk()
    local maxBuffer = getRecentEffectsMax()
    if maxBuffer <= 0 then
        -- Blocklist disabled: leave the file as-is so re-enabling restores history.
        recentEffectsDirty = false
        return
    end
    local content = table.concat(recentEffectsQueue, "\n")
    ChaosFileReader.WriteTextToCache(RECENT_EFFECTS_FILE, content)
    recentEffectsDirty = false
    recentEffectsLastWriteMs = getTimestampMs()
end

local function loadRecentEffectsFromDisk()
    if ChaosConfig.persist_recent_effects == false then return end

    local maxBuffer = getRecentEffectsMax()
    if maxBuffer <= 0 then return end

    local lines = ChaosFileReader.ReadFileArrayFromCacheAllLines(RECENT_EFFECTS_FILE)
    if not lines then return end

    for _, line in ipairs(lines) do
        if type(line) == "string" then
            local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" and not recentEffectsSet[trimmed] then
                table.insert(recentEffectsQueue, trimmed)
                recentEffectsSet[trimmed] = true
            end
        end
    end

    -- Keep newest N if the saved file is larger than the current cap.
    while #recentEffectsQueue > maxBuffer do
        local evicted = table.remove(recentEffectsQueue, 1)
        recentEffectsSet[evicted] = nil
    end
end

--- Loads the persisted recent-effects blocklist from disk on first call. Subsequent
--- calls are no-ops so re-running `Initialize` (settings save, save load) doesn't
--- repopulate the in-RAM queue.
function ChaosEffectsRegistry.EnsureRecentEffectsLoaded()
    if recentEffectsLoaded then return end
    recentEffectsLoaded = true
    loadRecentEffectsFromDisk()
end

--- Driven from `ChaosMod.OnTick`. Flushes a pending blocklist write to disk when
--- the throttle window has elapsed since the last write.
function ChaosEffectsRegistry.TickRecentEffectsSave()
    if not recentEffectsDirty then return end
    if getRecentEffectsMax() <= 0 then
        recentEffectsDirty = false
        return
    end
    if (getTimestampMs() - recentEffectsLastWriteMs) >= RECENT_EFFECTS_SAVE_INTERVAL_MS then
        writeRecentEffectsToDisk()
    end
end

---@param id string
local function addToBlocklist(id)
    local maxBuffer = getRecentEffectsMax()
    while #recentEffectsQueue >= maxBuffer do
        if maxBuffer <= 0 then
            -- Buffer disabled: clear and skip insertion below.
            for k in pairs(recentEffectsSet) do recentEffectsSet[k] = nil end
            for i = #recentEffectsQueue, 1, -1 do recentEffectsQueue[i] = nil end
            return
        end
        local evicted = table.remove(recentEffectsQueue, 1)
        recentEffectsSet[evicted] = nil
    end
    table.insert(recentEffectsQueue, id)
    recentEffectsSet[id] = true

    recentEffectsDirty = true
    if (getTimestampMs() - recentEffectsLastWriteMs) >= RECENT_EFFECTS_SAVE_INTERVAL_MS then
        writeRecentEffectsToDisk()
    end
end

--- Adds an effect id to the recent-effects blocklist if it isn't already in it.
---@param id string
function ChaosEffectsRegistry.AddToBlocklist(id)
    if type(id) ~= "string" or id == "" then return end
    if recentEffectsSet[id] then return end
    addToBlocklist(id)
end

---@param id string
---@return boolean
function ChaosEffectsRegistry.IsInBlocklist(id)
    return recentEffectsSet[id] == true
end

---@class ChaosGameContext
---@field inside_car boolean
---@field player_health number -- overall body health, 0-100
---@field has_npc_companions boolean
---@field number_npc_companions number
---@field has_weapon_inventory boolean
---@field in_building boolean
---@field zombies_in_radius_six number
---@field wounds_number_not_bandaged number
---@field has_melee_weapon_in_hand boolean
---@field has_last_death boolean
---@field is_night_time boolean
---@field has_private_car_nearby boolean
---@field nearest_car_dist number -- 2D distance to the nearest loaded vehicle; 0 when inside one, -1 when none found
---@field has_zombie_infection boolean -- true Knox/zombie infection
---@field cars_nearby number -- number of loaded vehicles within CARS_NEARBY_RADIUS

local ZOMBIES_CONTEXT_RADIUS = 6
local PRIVATE_CAR_NEARBY_RADIUS = 8
local CARS_NEARBY_RADIUS = 15

--- Builds a snapshot of the current game state used for context-aware effect
--- weighting. Only called when `ChaosConfig.context_aware_system` is enabled.
---@return ChaosGameContext
function ChaosEffectsRegistry.BuildGameContext()
    ---@type ChaosGameContext
    local context = {
        inside_car = false,
        player_health = 100,
        has_npc_companions = false,
        number_npc_companions = 0,
        has_weapon_inventory = false,
        in_building = false,
        zombies_in_radius_six = 0,
        wounds_number_not_bandaged = 0,
        has_melee_weapon_in_hand = false,
        has_last_death = false,
        is_night_time = false,
        has_private_car_nearby = false,
        nearest_car_dist = -1,
        has_zombie_infection = false,
        cars_nearby = 0,
    }

    local player = getPlayer()
    if not player then return context end

    context.inside_car = player:getVehicle() ~= nil
    context.in_building = player:getBuilding() ~= nil

    local bodyDamage = player:getBodyDamage()
    if bodyDamage then
        context.player_health = bodyDamage:getOverallBodyHealth()
        context.has_zombie_infection = bodyDamage:IsInfected()
        local bodyParts = bodyDamage:getBodyParts()
        if bodyParts then
            for i = 0, bodyParts:size() - 1 do
                local part = bodyParts:get(i)
                if part and part:HasInjury() and not part:bandaged() then
                    context.wounds_number_not_bandaged = context.wounds_number_not_bandaged + 1
                end
            end
        end
    end

    if ChaosNPCUtils and ChaosNPCUtils.npcList then
        for i = 0, ChaosNPCUtils.npcList:size() - 1 do
            local npc = ChaosNPCUtils.npcList:get(i)
            if npc and npc.zombie and npc.zombie:isAlive() and npc:IsFriendlyToPlayer() then
                context.number_npc_companions = context.number_npc_companions + 1
            end
        end
        context.has_npc_companions = context.number_npc_companions > 0
    end

    local inventory = player:getInventory()
    if inventory then
        ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
            if item and item:IsWeapon() then
                context.has_weapon_inventory = true
            end
        end)
    end

    local primary = player:getPrimaryHandItem()
    if primary and primary:IsWeapon() then
        ---@type HandWeapon
        local handWeapon = primary
        if handWeapon.isRanged and not handWeapon:isRanged() then
            context.has_melee_weapon_in_hand = true
        end
    end

    local zombies = ChaosZombie.GetNearestZombies(player:getX(), player:getY(), ZOMBIES_CONTEXT_RADIUS, true,
        player:getZ())
    context.zombies_in_radius_six = zombies and zombies:size() or 0

    local deathX = ChaosUtils.GetLatestDeathPosition()
    context.has_last_death = deathX ~= nil

    local climateManager = getClimateManager()
    if climateManager then
        context.is_night_time = climateManager:getNightStrength() > 0.5
    end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if context.inside_car then
        context.has_private_car_nearby = true
    elseif vehicle then
        context.has_private_car_nearby = ChaosUtils.isInRange(player:getX(), player:getY(),
            vehicle:getX(), vehicle:getY(), PRIVATE_CAR_NEARBY_RADIUS)
    end

    if context.inside_car then
        context.nearest_car_dist = 0
    end
    local cell = getCell()
    local cellVehicles = cell and cell:getVehicles()
    if cellVehicles then
        local px, py = player:getX(), player:getY()
        local iterator = cellVehicles:iterator()
        while iterator:hasNext() do
            local cellVehicle = iterator:next()
            if cellVehicle then
                local dist = ChaosUtils.distTo(px, py, cellVehicle:getX(), cellVehicle:getY())
                if not context.inside_car and (context.nearest_car_dist < 0 or dist < context.nearest_car_dist) then
                    context.nearest_car_dist = dist
                end
                if dist <= CARS_NEARBY_RADIUS then
                    context.cars_nearby = context.cars_nearby + 1
                end
            end
        end
    end

    return context
end

--- Returns the context-adjusted selection weight for an effect. Only affects
--- the selection pool in `GetRandomEffects`, never the stored effect data.
---@param effectId string
---@param chance number
---@param tags string[]
---@param priceGroup string
---@param gameContext ChaosGameContext
---@return number
function ChaosEffectsRegistry.UpdateEffectWeightByContext(effectId, chance, tags, priceGroup, gameContext)
    local effect = ChaosEffectsRegistry.effects[effectId]
    local tagsSet = effect and effect.tagsSet or nil

    local baseChance = chance

    --- Fast O(1) tag check for the weighting rules below.
    ---@param tag string
    ---@return boolean
    local function hasTag(tag)
        return tagsSet ~= nil and tagsSet[tag] == true
    end

    local contextCarsNearbyExcludingCurrent = gameContext.cars_nearby

    if gameContext.inside_car then
        contextCarsNearbyExcludingCurrent = contextCarsNearbyExcludingCurrent - 1
    end


    if hasTag("inside_car") then
        if gameContext.has_private_car_nearby then
            chance = chance * 15.0
        else
            chance = chance * 0.7
        end
    end

    if hasTag("not_inside_car") then
        if gameContext.inside_car then
            chance = baseChance * 0.25
        end
    end

    if hasTag("cars_nearby") then
        if contextCarsNearbyExcludingCurrent > 0 then
            chance = baseChance * 5.0
        else
            chance = baseChance * 0.5
        end
    end

    if effectId == "cure_player_virus" then
        if gameContext.has_zombie_infection then
            chance = baseChance * 20.0
        else
            chance = baseChance * 0.25
        end
    end


    if gameContext.has_last_death == false then
        if effectId == "teleport_to_last_death" then
            chance = 0.0
        end
    end

    if hasTag("heal") then
        if gameContext.player_health < 25 then
            chance = baseChance * 30.0
        elseif gameContext.player_health < 50 then
            chance = baseChance * 10.0
        elseif gameContext.player_health > 99 then
            chance = baseChance * 0.1
        end
    end

    if gameContext.player_health > 50 and gameContext.wounds_number_not_bandaged > 0 then
        if hasTag("heal_wounds") then
            chance = baseChance * 5.0
        end
    end

    if hasTag("building") then
        if gameContext.in_building then
            chance = baseChance * 5.0
        else
            chance = baseChance * 0.5
        end
    end

    if gameContext.number_npc_companions > 0 then
        if effectId == "npcs_betray_player" then
            chance = baseChance * 3.0
        end
    end

    if gameContext.number_npc_companions > 1 then
        if effectId == "npc_fight_each_other" then
            chance = baseChance * 5.0
        end
    end

    return chance
end

--- Returns an array of randomly selected effect IDs using weighted random selection.
--- Picked effects are added to a rolling blocklist (size = `recent_effects_block_buffer`)
--- and cannot be re-selected until evicted. Pass `addToBlock = false` to roll an
--- effect without inserting it into the blocklist (used for the secret random_effect
--- backing in streamer-mode voting).
---@param amount integer
---@param pickType ChaosEffectPickType
---@param addToBlock boolean | nil -- default true
---@return string[]
function ChaosEffectsRegistry.GetRandomEffects(amount, pickType, addToBlock)
    local shouldBlock = addToBlock ~= false
    local pool = {}
    local totalWeight = 0.0

    local ignoreChances = ChaosConfig.ignore_effect_chances == true
    ---@type ChaosGameContext | nil
    local gameContext = nil
    if ChaosConfig.context_aware_system == true then
        gameContext = ChaosEffectsRegistry.BuildGameContext()
        if DEBUG_LOGS_CONTEXT_AWARE_SYSTEM then
            print(string.format(
                "[ChaosMod] Game context: inside_car=%s, player_health=%.1f, has_npc_companions=%s, number_npc_companions=%d, has_weapon_inventory=%s, in_building=%s, zombies_in_radius_six=%d, wounds_number_not_bandaged=%d, has_melee_weapon_in_hand=%s, has_last_death=%s, is_night_time=%s, has_private_car_nearby=%s, nearest_car_dist=%.1f, has_zombie_infection=%s, cars_nearby=%d",
                tostring(gameContext.inside_car), gameContext.player_health, tostring(gameContext.has_npc_companions),
                gameContext.number_npc_companions, tostring(gameContext.has_weapon_inventory),
                tostring(gameContext.in_building), gameContext.zombies_in_radius_six,
                gameContext.wounds_number_not_bandaged, tostring(gameContext.has_melee_weapon_in_hand),
                tostring(gameContext.has_last_death), tostring(gameContext.is_night_time),
                tostring(gameContext.has_private_car_nearby), gameContext.nearest_car_dist,
                tostring(gameContext.has_zombie_infection), gameContext.cars_nearby))
        end
    end
    for id, effect in pairs(ChaosEffectsRegistry.effects) do
        local eligible = (pickType == "donate") and effect.enabled_donate or effect.enabled
        if eligible and effect.chance > 0 and not recentEffectsSet[id] then
            local weight = ignoreChances and 1 or effect.chance
            if gameContext then
                local oldWeight = weight
                weight = ChaosEffectsRegistry.UpdateEffectWeightByContext(id, weight, effect.tags,
                    effect.price_group, gameContext)

                if DEBUG_LOGS_CONTEXT_AWARE_SYSTEM and oldWeight ~= weight then
                    print("Modified effect ID " ..
                        tostring(id) .. " chance from " .. tostring(oldWeight) .. " to " .. tostring(weight))
                end
            end
            if weight > 0 then
                table.insert(pool, { id = id, chance = weight })
                totalWeight = totalWeight + weight
            end
        end
    end

    local result = {}

    for _ = 1, amount do
        if totalWeight <= 0 then break end

        local roll = ChaosUtils.RandFloat(0, totalWeight)
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
            if shouldBlock then
                addToBlocklist(picked)
            end
            totalWeight = totalWeight - pool[pickedIndex].chance
            table.remove(pool, pickedIndex)
        end
    end

    return result
end

--- Picks a random enabled effect id with no duration, excluding `excludeId`.
--- Does not touch the blocklist; used purely for fake vote display names.
---@param excludeId string | nil
---@return string | nil
function ChaosEffectsRegistry.GetRandomNoDurationEffectId(excludeId)
    local pool = {}
    for id, effect in pairs(ChaosEffectsRegistry.effects) do
        if effect.enabled and effect.withDuration == false and effect.chance > 0 and id ~= excludeId then
            pool[#pool + 1] = id
        end
    end
    if #pool == 0 then return nil end
    return pool[ChaosUtils.RandArrayIndex(pool)]
end

--- Returns true if the effect has the given tag (case-insensitive, trimmed).
--- Tags are mod-owned and always come from default_effects.json.
---@param effectId string
---@param tag string
---@return boolean
function ChaosEffectsRegistry.HasTag(effectId, tag)
    if type(effectId) ~= "string" or type(tag) ~= "string" then return false end
    local effect = ChaosEffectsRegistry.effects and ChaosEffectsRegistry.effects[effectId]
    if not effect or not effect.tagsSet then return false end
    local normalized = tag:lower():match("^%s*(.-)%s*$")
    return effect.tagsSet[normalized] == true
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

    local tagsEntry = defaultEffectTags[effectId]

    ---@type ChaosEffectDataEntry
    local newEffectData = {
        id = effectId,
        name = ChaosLocalization.GetString("effects", effectId),
        enabled = effectJsonData.enabled or false,
        chance = tonumber(effectJsonData.chance) or 0,
        withDuration = effectJsonData.withDuration or false,
        duration = effectJsonData.duration or 0,
        class = effectClass,
        disableEffects = {},
        enabled_donate = effectJsonData.enabled_donate or false,
        price_group = effectJsonData.price_group or "",
        tags = tagsEntry and tagsEntry.tags or {},
        tagsSet = tagsEntry and tagsEntry.set or {},
    }

    -- Push disable_effects from json to new effect data
    if effectJsonData.disable_effects then
        for _, disableEffectId in ipairs(effectJsonData.disable_effects) do
            table.insert(newEffectData.disableEffects, disableEffectId)
        end
    end

    return newEffectData
end

--- Refreshes the cached localized `name` on every registered effect using the currently
--- loaded language data. Call after `ChaosLocalization.ReloadLanguages()` so UI that reads
--- `effect.name` (e.g. the in-game effect selection window) shows the new translations
--- without requiring the mod to be restarted.
function ChaosEffectsRegistry.RefreshEffectNames()
    if not ChaosEffectsRegistry.effects then return end
    for id, effect in pairs(ChaosEffectsRegistry.effects) do
        effect.name = ChaosLocalization.GetString("effects", id)
    end
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
