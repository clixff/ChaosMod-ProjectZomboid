---@class ChaosUtils
---@field lastUsedVehicle BaseVehicle?
---@field playerPositionHistory table<integer, {x: number, y: number, z: number}>
---@field positionSampleMs integer
---@field isSleeping boolean -- Whether the player is sleeping this tick
---@field lastIsSleeping boolean -- Whether the player was sleeping last tick
---@field sleepWorldLocation {x: number, y: number, z: number} | nil -- World position where player last fell asleep
ChaosUtils = ChaosUtils or {
    lastUsedVehicle = nil,
    playerPositionHistory = {},
    positionSampleMs = 0,
    isSleeping = false,
    lastIsSleeping = false,
    sleepWorldLocation = nil
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

---@param square IsoGridSquare
---@param explosionRange integer | nil defaults to 5
function ChaosUtils.TriggerExplosionAt(square, explosionRange)
    explosionRange = explosionRange or 5

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
---@return IsoGridSquare | nil
function ChaosUtils.GetRandomSquareAroundPosition(x, y, z, minRadius, maxRadius, maxTries)
    local cell = getCell()
    if not cell then return nil end

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
                return sq
            end
        end
    end

    return nil
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
            -- Only subtract friendly NPCs (PLAYERS group)
            if npc.npcGroup == ChaosNPCGroup.PLAYERS then
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

---@param item string
---@return string
function ChaosUtils.GetShortTextureIconNameByString(item)
    if not item then return "" end
    local item = instanceItem(item)
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
