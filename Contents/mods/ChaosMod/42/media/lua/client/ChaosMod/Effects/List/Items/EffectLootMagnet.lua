---@class EffectLootMagnet : ChaosEffectBase
---@field pulseTimer ChaosManualTimer
EffectLootMagnet = ChaosEffectBase:derive("EffectLootMagnet", "loot_magnet")

local PULSE_INTERVAL_MS = 300
local SEARCH_RADIUS = 25
local DROP_RADIUS = 2.0
local PLAYER_SAFE_RADIUS = 2.0

-- Max items pulled per type, per pulse.
local VEHICLE_PULL_LIMIT = 30
local DEAD_BODY_PULL_LIMIT = 30
local FLOOR_PULL_LIMIT = 30
local CONTAINER_PULL_LIMIT = 30

--- Collects free squares around the player to scatter the pulled loot onto.
---@param px integer
---@param py integer
---@return IsoGridSquare[]
local function collectCandidateSquares(px, py)
    ---@type IsoGridSquare[]
    local candidates = {}

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            candidates[#candidates + 1] = sq
        end
        return false
    end, 0.0, DROP_RADIUS, false, true, true)

    return candidates
end

--- Drops a single item onto a random candidate square near the player.
---@param candidates IsoGridSquare[]
---@param item InventoryItem?
---@return boolean
local function dropItemNearPlayer(candidates, item)
    if not item or #candidates == 0 then return false end

    local square = candidates[ChaosUtils.RandArrayIndex(candidates)]
    if not square then return false end

    local offX = ChaosUtils.RandFloat(0.15, 0.85)
    local offY = ChaosUtils.RandFloat(0.15, 0.85)
    square:AddWorldInventoryItem(item, offX, offY, 0.0)
    return true
end

--- Pulls up to `limit` items out of a container and scatters them near the player.
---@param container ItemContainer?
---@param candidates IsoGridSquare[]
---@param limit integer
---@return integer
local function pullContainer(container, candidates, limit)
    if not container or limit <= 0 then return 0 end

    local items = container:getItems()
    if not items then return 0 end

    local count = 0
    for i = items:size() - 1, 0, -1 do
        if count >= limit then break end
        local item = items:get(i)
        if item then
            container:Remove(item)
            if dropItemNearPlayer(candidates, item) then
                count = count + 1
            end
        end
    end

    return count
end

--- a) Pulls loot out of every vehicle part container in range, up to `limit` items.
---@param vehicles ArrayList<BaseVehicle>?
---@param candidates IsoGridSquare[]
---@param limit integer
---@return integer
local function pullVehicles(vehicles, candidates, limit)
    if not vehicles then return 0 end

    local count = 0
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            for p = 0, vehicle:getPartCount() - 1 do
                if count >= limit then break end
                local part = vehicle:getPartByIndex(p)
                if part then
                    count = count + pullContainer(part:getItemContainer(), candidates, limit - count)
                end
            end
        end
    end

    return count
end

--- b) Pulls loot out of every dead body lying on a square, up to `limit` items.
---@param sq IsoGridSquare
---@param candidates IsoGridSquare[]
---@param limit integer
---@return integer
local function pullDeadBodies(sq, candidates, limit)
    local bodies = sq:getDeadBodys()
    if not bodies then return 0 end

    local count = 0
    for i = 0, bodies:size() - 1 do
        if count >= limit then break end
        local body = bodies:get(i)
        if body then
            ---@diagnostic disable-next-line: undefined-field
            count = count + pullContainer(body:getContainer(), candidates, limit - count)
        end
    end

    return count
end

--- c) Pulls loose items lying on the floor (skipping ones already next to the player), up to `limit` items.
---@param sq IsoGridSquare
---@param candidates IsoGridSquare[]
---@param limit integer
---@return integer
local function pullFloorItems(sq, candidates, limit)
    local count = 0

    ChaosUtils.ForAllWorldObjectsOnSquare(sq, function(worldObj)
        if count >= limit then return end
        if not worldObj then return end

        local item = worldObj:getItem()
        if not item then return end

        local itemSquare = worldObj:getSquare()
        if itemSquare then
            itemSquare:transmitRemoveItemFromSquare(worldObj)
        else
            worldObj:removeFromWorld()
            worldObj:removeFromSquare()
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        item:setWorldItem(nil)

        if dropItemNearPlayer(candidates, item) then
            count = count + 1
        end
    end)

    return count
end

--- d) Pulls loot out of every furniture/object container on a square, up to `limit` items.
---@param sq IsoGridSquare
---@param candidates IsoGridSquare[]
---@param limit integer
---@return integer
local function pullObjectContainers(sq, candidates, limit)
    local count = 0

    ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
        ChaosUtils.ForAllContainersInObject(obj, function(container)
            if count < limit then
                count = count + pullContainer(container, candidates, limit - count)
            end
        end)
    end)

    return count
end

function EffectLootMagnet:OnStart()
    ChaosEffectBase:OnStart()

    self.pulseTimer = ChaosManualTimer.new(PULSE_INTERVAL_MS)
end

--- Runs one magnet pulse: gathers nearby loot and scatters it around the player.
local function runPulse()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px, py, pz = square:getX(), square:getY(), square:getZ()

    local candidates = collectCandidateSquares(px, py)
    if #candidates == 0 then return end

    -- a) Vehicles in range.
    local vehicleTotal = pullVehicles(ChaosVehicle.GetVehiclesNearby(square, SEARCH_RADIUS), candidates,
        VEHICLE_PULL_LIMIT)

    local minZ = pz - 1

    if pz == -1 then
        minZ = -1
    end

    local deadBodyTotal = 0
    local containerTotal = 0
    local floorTotal = 0

    -- b) c) d) Dead bodies, floor items, and object containers across the Z stack.
    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end

        if deadBodyTotal < DEAD_BODY_PULL_LIMIT then
            deadBodyTotal = deadBodyTotal + pullDeadBodies(sq, candidates, DEAD_BODY_PULL_LIMIT - deadBodyTotal)
        end

        if containerTotal < CONTAINER_PULL_LIMIT then
            containerTotal = containerTotal + pullObjectContainers(sq, candidates, CONTAINER_PULL_LIMIT - containerTotal)
        end

        if floorTotal < FLOOR_PULL_LIMIT and not ChaosUtils.isInRange(px, py, sq:getX(), sq:getY(), PLAYER_SAFE_RADIUS) then
            floorTotal = floorTotal + pullFloorItems(sq, candidates, FLOOR_PULL_LIMIT - floorTotal)
        end

        -- Stop scanning once every per-type budget is spent.
        if deadBodyTotal >= DEAD_BODY_PULL_LIMIT and containerTotal >= CONTAINER_PULL_LIMIT
            and floorTotal >= FLOOR_PULL_LIMIT then
            return true
        end
    end, 0, SEARCH_RADIUS, false, false, true, minZ, pz + 2)

    local pulledCount = vehicleTotal + deadBodyTotal + containerTotal + floorTotal

    if pulledCount > 0 then
        print("[EffectLootMagnet] Pulled " .. tostring(pulledCount) .. " items toward the player")
    end
end

---@param deltaMs integer
function EffectLootMagnet:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    self.pulseTimer:add(deltaMs)
    if self.pulseTimer:isEnded() then
        self.pulseTimer:reset()
        runPulse()
    end
end

function EffectLootMagnet:OnEnd()
    ChaosEffectBase:OnEnd()
end
