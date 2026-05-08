---@class ChaosUtils
---@field lastUsedVehicle BaseVehicle?
---@field playerPositionHistory table<integer, {x: number, y: number, z: number}>
---@field positionSampleMs integer
---@field isSleeping boolean -- Whether the player is sleeping this tick
---@field lastIsSleeping boolean -- Whether the player was sleeping last tick
---@field sleepWorldLocation {x: number, y: number, z: number} | nil -- World position where player last fell asleep
---@field playerSpawnPoint {x: number, y: number, z: number} | nil -- World position where player first spawned this save
---@field playerPreviousPositions table<integer, {x: number, y: number, z: number}> -- Last 2 recorded player world positions, oldest first
---@field playerPreviousPositionsSampleMs integer
ChaosUtils = ChaosUtils or {
    lastUsedVehicle = nil,
    playerPositionHistory = {},
    positionSampleMs = 0,
    isSleeping = false,
    lastIsSleeping = false,
    sleepWorldLocation = nil,
    playerSpawnPoint = nil,
    playerPreviousPositions = {},
    playerPreviousPositionsSampleMs = 0
}

local SLEEP_MOD_DATA_KEY = "ChaosMod_SleepData"

--- Loads the last sleep position from global mod data.
function ChaosUtils.LoadSleepData()
    local md = ModData.getOrCreate(SLEEP_MOD_DATA_KEY)
    if md["x"] and md["y"] and md["z"] then
        local x, y, z = md["x"] --[[@as number]], md["y"] --[[@as number]], md["z"] --[[@as number]]
        ChaosUtils.sleepWorldLocation = { x = x, y = y, z = z }
        print(string.format("[ChaosUtils] Loaded last sleep position: %.1f, %.1f, %.1f", x, y, z))
    end
end

--- Saves the current sleep position to global mod data.
local function saveSleepData()
    if not ChaosUtils.sleepWorldLocation then return end
    local md = ModData.getOrCreate(SLEEP_MOD_DATA_KEY)
    md["x"] = ChaosUtils.sleepWorldLocation.x
    md["y"] = ChaosUtils.sleepWorldLocation.y
    md["z"] = ChaosUtils.sleepWorldLocation.z
    ModData.transmit(SLEEP_MOD_DATA_KEY)
end

--- Forces the player to wake up immediately.
---@param player IsoPlayer
function ChaosUtils.ForceWakeUpPlayer(player)
    local sleepingEvent = getSleepingEvent()
    sleepingEvent:wakeUp(player)
    player:setLastHourSleeped(math.floor(player:getHoursSurvived()) - 2)
end

--- Tracks player sleep state each tick. Call from OnTick when mod is enabled.
function ChaosUtils.sleepHandleTick()
    local player = getPlayer()
    if not player then return end

    ChaosUtils.lastIsSleeping = ChaosUtils.isSleeping
    ChaosUtils.isSleeping = player:isAsleep()

    -- Transition: was awake last tick, now sleeping — record position
    if ChaosUtils.isSleeping and not ChaosUtils.lastIsSleeping then
        local loc = { x = player:getX(), y = player:getY(), z = player:getZ() }
        ChaosUtils.sleepWorldLocation = loc
        saveSleepData()
        print(string.format("[ChaosUtils] Player fell asleep at %.1f, %.1f, %.1f", loc.x, loc.y, loc.z))
    end
end

local POSITION_SAMPLE_INTERVAL_MS = 1000
local POSITION_HISTORY_MAX = 60
local PREVIOUS_LOCATION_SAMPLE_INTERVAL_MS = 60000
local PREVIOUS_LOCATION_MAX = 2

--- Records the local player's position once per second (call only when ChaosMod is enabled).
---@param deltaMs integer
function ChaosUtils.TrackPlayerPosition(deltaMs)
    ChaosUtils.positionSampleMs = ChaosUtils.positionSampleMs + deltaMs
    if ChaosUtils.positionSampleMs < POSITION_SAMPLE_INTERVAL_MS then return end
    ChaosUtils.positionSampleMs = ChaosUtils.positionSampleMs - POSITION_SAMPLE_INTERVAL_MS

    local player = getPlayer()
    if not player then return end
    if not player:getSquare() then return end

    table.insert(ChaosUtils.playerPositionHistory, {
        x = player:getX(),
        y = player:getY(),
        z = player:getZ()
    })

    while #ChaosUtils.playerPositionHistory > POSITION_HISTORY_MAX do
        table.remove(ChaosUtils.playerPositionHistory, 1)
    end
end

--- Records the player's location every 60 seconds, keeping only the last 2 entries (oldest first).
---@param deltaMs integer
function ChaosUtils.TrackPlayerPreviousPositions(deltaMs)
    ChaosUtils.playerPreviousPositionsSampleMs = ChaosUtils.playerPreviousPositionsSampleMs + deltaMs
    if ChaosUtils.playerPreviousPositionsSampleMs < PREVIOUS_LOCATION_SAMPLE_INTERVAL_MS then return end
    ChaosUtils.playerPreviousPositionsSampleMs = ChaosUtils.playerPreviousPositionsSampleMs - PREVIOUS_LOCATION_SAMPLE_INTERVAL_MS

    local player = getPlayer()
    if not player then return end
    if not player:getSquare() then return end

    table.insert(ChaosUtils.playerPreviousPositions, {
        x = player:getX(),
        y = player:getY(),
        z = player:getZ()
    })

    while #ChaosUtils.playerPreviousPositions > PREVIOUS_LOCATION_MAX do
        table.remove(ChaosUtils.playerPreviousPositions, 1)
    end
end

---@param obj IsoObject
function ChaosUtils.RemovePropExplosion(obj)
    if not obj then return end

    if instanceof(obj, "IsoWindow") then
        ---@type IsoWindow
        local window = obj
        if not window:isSmashed() then
            window:smashWindow()
        end
        return
    end

    local containerCount = obj:getContainerCount()
    if not containerCount or containerCount == 0 then return end
    local sq = obj:getSquare()
    if not sq then return end
    for i = 0, containerCount - 1 do
        local container = obj:getContainerByIndex(i)
        if container then
            local items = container:getItems()
            ---@type InventoryItem[]
            local snapshot = {}
            for j = 0, items:size() - 1 do
                table.insert(snapshot, items:get(j))
            end
            for _, item in ipairs(snapshot) do
                local ox = ChaosUtils.RandFloat(0.15, 0.85)
                local oy = ChaosUtils.RandFloat(0.15, 0.85)
                sq:AddWorldInventoryItem(item, ox, oy, 0.0)
            end
        end
    end

    local square = obj:getSquare()
    if square then
        square:RemoveTileObject(obj)
    end
    obj:removeFromSquare()
    obj:removeFromWorld()
end

---@param square IsoGridSquare
---@param explosionRange integer | nil defaults to 5
---@param shouldRemoveProps boolean | nil defaults to true
function ChaosUtils.TriggerExplosionAt(square, explosionRange, shouldRemoveProps)
    explosionRange = explosionRange or 5
    if shouldRemoveProps == nil then shouldRemoveProps = true end

    if shouldRemoveProps then
        local x, y, z = square:getX(), square:getY(), square:getZ()
        ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
            if sq then
                ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                    ChaosUtils.RemovePropExplosion(obj)
                end)
            end
        end, 0, explosionRange, false, false, true, z, z)
    end

    local weapon = instanceItem("Base.PipeBomb")
    local fakeZombie = getFakeAttacker()
    local trap = IsoTrap.new(fakeZombie, weapon, square:getCell(), square)

    square:AddTileObject(trap)

    trap:setFireRange(0)
    trap:setExplosionRange(explosionRange)
    trap:setExplosionPower(100)
    trap:setSmokeRange(5)
    trap:setNoiseRange(20)
    trap:setInstantExplosion(false)
    trap:setExplosionSound("BigExplosion")

    trap:triggerExplosion(false)
end

---@type table<integer, PerkFactory.Perk>
SKILL_EXP_IDS = {
    Perks.Doctor,
    Perks.Axe,
    Perks.Blunt,
    Perks.Aiming,
    Perks.Reloading,
    Perks.Woodwork,
    Perks.Cooking,
    Perks.Electricity,
    Perks.Mechanics,
    Perks.Tailoring,
    Perks.Fishing,
    Perks.PlantScavenging,
    Perks.Farming,
    Perks.Sprinting,
    Perks.Lightfoot,
    Perks.Sneak,
    Perks.Blacksmith,
    Perks.Butchering,
    Perks.Carpentry,
    Perks.Carving,
    Perks.Combat,
    Perks.Crafting,
    Perks.Husbandry,
    Perks.MetalWelding
}

TOOL_ITEM_IDS = {
    "Base.Hammer",
    "Base.Screwdriver",
    "Base.Wrench",
    "Base.PocketKnife",
    "Base.Saw",
    "Base.BlowTorch",
    "Base.Pliers",
    "Base.BoltCutters",
    "Base.Scissors",
    "Base.Crowbar",
    "Base.HandAxe",
    "Base.Jack",
    "Base.TireIron",
    "Base.LugWrench",
    "Base.TinOpener",
    "Base.PickAxe",
    "Base.Needle"
}


---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function ChaosUtils.distTo(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param maxDist number
---@return boolean
function ChaosUtils.isInRange(x1, y1, x2, y2, maxDist)
    return ChaosUtils.distTo(x1, y1, x2, y2) <= maxDist
end

---@param square IsoGridSquare
---@return number darkMulti
function ChaosUtils.getSquareDarkMulti(square)
    -- getDarkMulti(playerIndex) exists on IsoGridSquare
    return square:getDarkMulti(0)
end

function ChaosUtils.updateModId()
    local modDirectoryTable = getModDirectoryTable()
    for _, modDirectory in ipairs(modDirectoryTable) do
        -- Check if modDirectory contains "ChaosMod"
        if string.find(modDirectory, "ChaosMod") then
            local modInfo = getModInfo(modDirectory)
            if modInfo then
                ChaosMod.modData = modInfo
                local modId = modInfo:getId()
                print("[ChaosMod] Mod ID found: " .. tostring(modId))
                ChaosMod.modId = modId
            end
            return
        end
    end
end

---@param soundname string
---@param skipCheck boolean | nil
function ChaosUtils.PlayUISound(soundname, skipCheck)
    skipCheck = skipCheck or false
    if not skipCheck and not ChaosConfig.IsUISoundsEnabled() then
        return nil
    end

    local soundManager = getSoundManager()
    if not soundManager then
        print("[ChaosUtils] Sound manager not found")
        return nil
    end
    return soundManager:playUISound(soundname)
end

---@param targetHours integer
---@param targetMinutes integer
function ChaosUtils.SetWorldTime(targetHours, targetMinutes)
    ---@type GameTime
    local gameTime = GameTime:getInstance()
    if not gameTime then return end

    local currentTime = gameTime:getTimeOfDay()
    local targetTime = targetHours + (targetMinutes / 60)

    local year = gameTime:getYear()
    local month = gameTime:getMonth()
    local dayOfMonth = gameTime:getDayPlusOne()

    if currentTime > targetTime then
        dayOfMonth = dayOfMonth + 1

        local daysInMonth = gameTime:daysInMonth(year, month)
        if dayOfMonth > daysInMonth then
            dayOfMonth = 1
            month = month + 1

            if month > 11 then
                month = 0
                year = year + 1
            end
        end
    end

    gameTime:updateCalendar(year, month, dayOfMonth, targetHours, targetMinutes)
    gameTime:setTimeOfDay(targetTime)
end

---@param climateManager ClimateManager
---@param climateType integer
---@param overrideEnabled boolean
---@param valueOverride number
function ChaosUtils.SetClimateFloatOverride(climateManager, climateType, overrideEnabled, valueOverride)
    local climateFloat = climateManager:getClimateFloat(climateType)
    if not climateFloat then return end

    if overrideEnabled then
        climateFloat:setEnableOverride(overrideEnabled)
        climateFloat:setOverride(valueOverride, 1.0)
    else
        climateFloat:setEnableOverride(false)
    end
end

---@param x number
---@param y number
---@param z integer
---@param minRadius integer
---@param maxRadius integer
---@param maxTries integer | nil
---@param checkEmptiness boolean?
---@return IsoGridSquare | nil
function ChaosUtils.GetRandomSquareAroundPosition(x, y, z, minRadius, maxRadius, maxTries, checkEmptiness)
    local cell = getCell()
    if not cell then return nil end
    checkEmptiness = checkEmptiness or false

    maxTries = maxTries or 50
    local minSq = minRadius * minRadius
    local maxSq = maxRadius * maxRadius

    for _ = 1, maxTries do
        local dx = ZombRand(-maxRadius, maxRadius + 1)
        local dy = ZombRand(-maxRadius, maxRadius + 1)
        local distSq = dx * dx + dy * dy

        if distSq >= minSq and distSq <= maxSq then
            local sq = cell:getGridSquare(x + dx, y + dy, z)
            if sq and sq:isSolidFloor() then
                if checkEmptiness == false then
                    return sq
                else
                    if sq:isFree(false) then
                        return sq
                    end
                end
            end
        end
    end

    return nil
end

---@param value unknown
---@return integer
local function _normalizeBFSZOffset(value)
    if type(value) ~= "number" then return 0 end
    if value % 1 ~= 0 then return 0 end
    return value
end

---@param square IsoGridSquare | nil
---@param checkFloor boolean
---@param onlyEmpty boolean
---@param allowInteriors boolean
---@return boolean
local function _isValidBFSSquare(square, checkFloor, onlyEmpty, allowInteriors)
    if not square then return false end

    if checkFloor and not square:isSolidFloor() then
        return false
    end

    if not allowInteriors and not square:isOutside() then
        return false
    end

    if onlyEmpty and not square:isFree(false) then
        return false
    end

    return true
end

---@param cell IsoCell
---@param originX number
---@param originY number
---@param targetX integer
---@param targetY integer
---@param z integer
---@param callback fun(square: IsoGridSquare): boolean?
---@param minDistance number
---@param maxDistance number
---@param checkFloor boolean
---@param onlyEmpty boolean
---@param allowInteriors boolean
---@return boolean
local function _checkSquareAtZ(cell, originX, originY, targetX, targetY, z, callback, minDistance, maxDistance,
                               checkFloor, onlyEmpty, allowInteriors)
    local dist = ChaosUtils.distTo(originX, originY, targetX, targetY)
    if dist < minDistance or dist > maxDistance then
        return false
    end

    local square = cell:getGridSquare(targetX, targetY, z)
    if not _isValidBFSSquare(square, checkFloor, onlyEmpty, allowInteriors) then
        return false
    end

    return callback(square) == true
end

---@param cell IsoCell
---@param originX number
---@param originY number
---@param targetX integer
---@param targetY integer
---@param callback fun(square: IsoGridSquare): boolean?
---@param minDistance number
---@param maxDistance number
---@param checkFloor boolean
---@param onlyEmpty boolean
---@param allowInteriors boolean
---@param minZ integer
---@param maxZ integer
---@return boolean
local function _checkSquareAcrossZ(cell, originX, originY, targetX, targetY, callback, minDistance, maxDistance,
                                   checkFloor, onlyEmpty, allowInteriors, minZ, maxZ)
    for currentZ = minZ, maxZ do
        if _checkSquareAtZ(cell, originX, originY, targetX, targetY, currentZ, callback, minDistance, maxDistance,
                checkFloor, onlyEmpty, allowInteriors) then
            return true
        end
    end

    return false
end

--- Breadth-first XY scan around a world position. Traversal order is BFS by cardinal neighbors.
--- The callback is invoked only for squares that match the filters and whose 2D distance is within range.
--- Absolute Z levels are evaluated per visited XY.
---@param x integer
---@param y integer
---@param callback fun(square: IsoGridSquare): boolean?
---@param minDistance number
---@param maxDistance number
---@param checkFloor boolean?
---@param onlyEmpty boolean?
---@param allowInteriors boolean?
---@param minZ integer?
---@param maxZ integer?
---@return boolean
function ChaosUtils.GetTilesBFS_2D(x, y, callback, minDistance, maxDistance, checkFloor, onlyEmpty, allowInteriors,
                                   minZ, maxZ)
    local cell = getCell()
    if not cell then return false end
    if type(callback) ~= "function" then return false end

    checkFloor = checkFloor == true
    onlyEmpty = onlyEmpty == true
    allowInteriors = allowInteriors ~= false
    minDistance = minDistance or 0
    maxDistance = maxDistance or 0

    if maxDistance < 0 then return false end
    if minDistance < 0 then minDistance = 0 end
    if minDistance > maxDistance then return false end

    minZ = _normalizeBFSZOffset(minZ)
    maxZ = _normalizeBFSZOffset(maxZ)
    if minZ > maxZ then return false end

    ---@type table<integer, {x: integer, y: integer}>
    local queue = {
        { x = x, y = y }
    }
    local head = 1

    ---@type table<string, boolean>
    local visited = {}
    visited[tostring(x) .. ":" .. tostring(y)] = true

    while head <= #queue do
        local node = queue[head]
        head = head + 1

        local nodeX = node.x
        local nodeY = node.y
        local dist = ChaosUtils.distTo(x, y, nodeX, nodeY)

        if dist <= maxDistance then
            if _checkSquareAcrossZ(cell, x, y, nodeX, nodeY, callback, minDistance, maxDistance, checkFloor,
                    onlyEmpty, allowInteriors, minZ, maxZ) then
                return true
            end
        end

        local neighbors = {
            { x = nodeX + 1, y = nodeY },
            { x = nodeX - 1, y = nodeY },
            { x = nodeX,     y = nodeY + 1 },
            { x = nodeX,     y = nodeY - 1 }
        }

        for i = 1, #neighbors do
            local neighbor = neighbors[i]
            local key = tostring(neighbor.x) .. ":" .. tostring(neighbor.y)
            if not visited[key] and ChaosUtils.distTo(x, y, neighbor.x, neighbor.y) <= maxDistance then
                visited[key] = true
                queue[#queue + 1] = neighbor
            end
        end
    end

    return false
end

--- Expanding square-ring XY scan around a world position using Chebyshev distance.
--- Ring 0 checks the center tile, ring 1 checks the 8 surrounding tiles, ring 2 checks the next 16, etc.
--- Each visited XY is checked against the 2D distance filters before callback dispatch.
---@param x integer
---@param y integer
---@param callback fun(square: IsoGridSquare): boolean?
---@param minDistance number
---@param maxDistance number
---@param checkFloor boolean?
---@param onlyEmpty boolean?
---@param allowInteriors boolean?
---@param minZ integer?
---@param maxZ integer?
---@return boolean
function ChaosUtils.SquareRingSearchTile_2D(x, y, callback, minDistance, maxDistance, checkFloor, onlyEmpty,
                                            allowInteriors, minZ, maxZ)
    local cell = getCell()
    if not cell then return false end
    if type(callback) ~= "function" then return false end

    checkFloor = checkFloor == true
    onlyEmpty = onlyEmpty == true
    allowInteriors = allowInteriors ~= false
    minDistance = minDistance or 0
    maxDistance = maxDistance or 0

    if maxDistance < 0 then return false end
    if minDistance < 0 then minDistance = 0 end
    if minDistance > maxDistance then return false end

    minZ = _normalizeBFSZOffset(minZ)
    maxZ = _normalizeBFSZOffset(maxZ)
    if minZ > maxZ then return false end

    local maxRing = math.ceil(maxDistance)

    for ring = 0, maxRing do
        if ring == 0 then
            if _checkSquareAcrossZ(cell, x, y, x, y, callback, minDistance, maxDistance, checkFloor, onlyEmpty,
                    allowInteriors, minZ, maxZ) then
                return true
            end
        else
            local minX = x - ring
            local maxX = x + ring
            local minY = y - ring
            local maxY = y + ring

            for currentX = minX, maxX do
                if _checkSquareAcrossZ(cell, x, y, currentX, minY, callback, minDistance, maxDistance, checkFloor,
                        onlyEmpty, allowInteriors, minZ, maxZ) then
                    return true
                end

                if _checkSquareAcrossZ(cell, x, y, currentX, maxY, callback, minDistance, maxDistance, checkFloor,
                        onlyEmpty, allowInteriors, minZ, maxZ) then
                    return true
                end
            end

            for currentY = minY + 1, maxY - 1 do
                if _checkSquareAcrossZ(cell, x, y, minX, currentY, callback, minDistance, maxDistance, checkFloor,
                        onlyEmpty, allowInteriors, minZ, maxZ) then
                    return true
                end

                if _checkSquareAcrossZ(cell, x, y, maxX, currentY, callback, minDistance, maxDistance, checkFloor,
                        onlyEmpty, allowInteriors, minZ, maxZ) then
                    return true
                end
            end
        end
    end

    return false
end

---@param a number
---@param b number
---@param t number
---@return number
function ChaosUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

---@param a table
---@param b table
---@param t number
---@return table
function ChaosUtils.LerpColor(a, b, t)
    return {
        r = ChaosUtils.Lerp(a.r, b.r, t),
        g = ChaosUtils.Lerp(a.g, b.g, t),
        b = ChaosUtils.Lerp(a.b, b.b, t),
    }
end

---@param player IsoPlayer
---@return BaseVehicle | nil
function ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not player then return nil end
    local vehicle = player:getVehicle()
    if vehicle then
        ChaosUtils.lastUsedVehicle = vehicle
    end
    return ChaosUtils.lastUsedVehicle
end

---@param weight number
---@return string
function ChaosUtils.FormatWeight(weight)
    local format = Core.getInstance():getOptionMeasurementFormat()

    local weightStr = ""
    if format == "Imperial" then
        local lbs = weight * 2.20462
        weightStr = string.format("%.1f lbs", lbs)
    else
        weightStr = string.format("%.1f kg", weight)
    end

    return weightStr
end

function ChaosUtils.AdjustVisibleZombiesForNPCs()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    local currentVisible = stats:getNumVisibleZombies()
    if currentVisible <= 0 then return end

    -- Count friendly NPC zombies that are visible (within 7 tiles, same room, not ghost/fakedead)
    local npcCount = 0
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local playerRoom = player:getCurrentSquare() and player:getCurrentSquare():getRoom() or nil

    local npcList = ChaosNPCUtils.npcList
    for i = 0, npcList:size() - 1 do
        ---@type ChaosNPC
        local npc = npcList:get(i)
        if npc and npc.zombie and not npc.zombie:isDead() then
            -- Only subtract NPCs that follow the player
            local npcRel = ChaosNPCRelations.GetRelationForNPC(npc, player)
            if npcRel == ChaosNPCRelationType.FOLLOW then
                local zombie = npc.zombie
                local dist = IsoUtils.DistanceTo(zombie:getX(), zombie:getY(), px, py)
                local zz = zombie:getZ()

                if dist < 7.0
                    and zz >= pz - 1.0
                    and not zombie:isFakeDead()
                then
                    local zombieRoom = zombie:getCurrentSquare() and zombie:getCurrentSquare():getRoom() or nil
                    if zombieRoom == playerRoom then
                        npcCount = npcCount + 1

                        if dist < 4.0 then
                            npcCount = npcCount + 2
                        end
                    end
                end
            end
        end
    end

    if npcCount > 0 then
        local adjusted = math.max(0, currentVisible - npcCount)
        stats:setNumVisibleZombies(adjusted)
        if npcCount > currentVisible then
            player:getStats():set(CharacterStat.PANIC, 0)
        end
    end
end

---@param item InventoryItem
---@return string
function ChaosUtils.GetShortTextureIconName(item)
    if not item then return "" end
    local textureIcon = item:getIcon()
    if not textureIcon then return "" end
    local textureIconName = textureIcon:getName()
    if not textureIconName then return "" end
    return string.sub(textureIconName, 6, -1)
end

---@param itemId string
---@return string
function ChaosUtils.GetShortTextureIconNameByString(itemId)
    if not itemId then return "" end
    local item = instanceItem(itemId)
    if not item then return "" end
    return ChaosUtils.GetShortTextureIconName(item)
end

---@param item InventoryItem
---@return string
function ChaosUtils.GetImgCodeByItemTexture(item)
    if not item then return "" end
    local shortTextureIconName = ChaosUtils.GetShortTextureIconName(item)
    if not shortTextureIconName then return "" end
    return string.format("[img=%s]", shortTextureIconName)
end

---@param item string
---@return string
function ChaosUtils.GetImgCodeByItemTextureByString(item)
    if not item then return "" end
    local item = instanceItem(item)
    if not item then return "" end
    return ChaosUtils.GetImgCodeByItemTexture(item)
end

---@param container ItemContainer
---@param out table<integer, { item: InventoryItem }>
local function _collectItemsFromContainer(container, out)
    if not container then return end
    if not container.getItems then return end
    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            if item:IsInventoryContainer() then
                ---@type InventoryContainer
                local inner = item
                if inner then
                    _collectItemsFromContainer(inner:getInventory(), out)
                end
            else
                table.insert(out, { item = item })
            end
        end
    end
end

---@param player IsoPlayer
function ChaosUtils.RemoveRandomItem(player)
    if not player then return end
    local inventory = player:getInventory()
    if not inventory then return end

    ---@type table<integer, { item: InventoryItem }>
    local allItems = {}
    _collectItemsFromContainer(inventory, allItems)

    if #allItems == 0 then return end

    local randomIndex = math.floor(ZombRand(1, #allItems + 1))
    local randomItem = allItems[randomIndex]
    if not randomItem then return end

    local worn = player:getWornItems()
    if worn and worn:contains(randomItem.item) then
        player:removeWornItem(randomItem.item)
    end

    inventory:Remove(randomItem.item)

    ChaosPlayer.SayLineRemovedItem(player, randomItem.item)
end

---@param square IsoGridSquare
---@param callback fun(obj: IsoObject): boolean?
---@return boolean
function ChaosUtils.ForAllObjectsInSquare(square, callback)
    if not square then return false end
    if not callback then return false end
    local objects = square:getObjects()
    if not objects then return false end
    for i = objects:size() - 1, 0, -1 do
        local obj = objects:get(i)
        if obj then
            local result = callback(obj)
            if result == true then
                return true
            end
        end
    end
    return false
end

---@param obj IsoObject
---@param callback fun(container: ItemContainer)
function ChaosUtils.ForAllContainersInObject(obj, callback)
    if not obj then return end
    if not callback then return end
    if not obj:getContainerCount() then return end
    for i = 0, obj:getContainerCount() - 1 do
        local container = obj:getContainerByIndex(i)
        if container then
            callback(container)
        end
    end
end

---@param square IsoGridSquare
---@param callback fun(obj: IsoWorldInventoryObject): boolean?
---@return boolean
function ChaosUtils.ForAllWorldObjectsOnSquare(square, callback)
    if not square then return false end
    if not callback then return false end
    local worldObjects = square:getWorldObjects()
    if not worldObjects then return false end
    for i = worldObjects:size() - 1, 0, -1 do
        local obj = worldObjects:get(i)
        if obj then
            local result = callback(obj)
            if result == true then
                return true
            end
        end
    end
    return false
end

---Returns a pseudorandom integer between 0 and max - 1.
---@param max number Exclusive upper bound of the integer value.
---@return integer
function ChaosUtils.RandInteger(max)
    return math.floor(ZombRand(max))
end

---Returns a pseudorandom integer between min and max - 1.
---@param min number Inclusive lower bound of the random integer.
---@param max number Exclusive upper bound of the random integer.
---@return integer
function ChaosUtils.RandIntegerRange(min, max)
    return math.floor(ZombRand(min, max))
end

---Returns a pseudorandom float between min and max.
---@param min number Lower bound of the random float.
---@param max number Upper bound of the random float.
---@return number
function ChaosUtils.RandFloat(min, max)
    return ZombRandFloat(min, max)
end

---Returns a pseudorandom valid index into the given table (1-based).
---@param array table
---@return integer
function ChaosUtils.RandArrayIndex(array)
    return math.floor(ZombRand(#array)) + 1
end

---@param worldObject IsoWorldInventoryObject
---@param removeInventoryItem boolean | nil
---@return InventoryItem | nil
function ChaosUtils.RemoveWorldObject(worldObject, removeInventoryItem)
    if not worldObject then return nil end

    local square = worldObject:getSquare()
    if not square then return nil end

    if removeInventoryItem == nil then
        removeInventoryItem = true
    end

    local item = nil
    if worldObject.getItem then
        item = worldObject:getItem()
    end

    -- Detach item from world object first, otherwise Lua can keep a stale worldItem ref.
    if item then
        ---@diagnostic disable-next-line: param-type-mismatch
        item:setWorldItem(nil)
    end

    -- Proper removal path (handles MP sync too)
    square:transmitRemoveItemFromSquare(worldObject)

    if removeInventoryItem then
        if item then
            item:Remove()
        end
        return nil
    end

    return item
end
