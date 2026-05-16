ChaosVehicle = ChaosVehicle or {}


VEHICLE_COLORS = {
    { name = "Red",    hue = 0.00, sat = 0.90, val = 0.85 },
    { name = "Orange", hue = 0.07, sat = 0.90, val = 0.90 },
    { name = "Yellow", hue = 0.14, sat = 0.85, val = 0.95 },
    { name = "Lime",   hue = 0.25, sat = 0.80, val = 0.75 },
    { name = "Green",  hue = 0.35, sat = 0.85, val = 0.65 },
    { name = "Teal",   hue = 0.48, sat = 0.80, val = 0.65 },
    { name = "Blue",   hue = 0.60, sat = 0.85, val = 0.80 },
    { name = "Purple", hue = 0.75, sat = 0.80, val = 0.70 },
    { name = "Pink",   hue = 0.88, sat = 0.60, val = 0.90 },
    { name = "White",  hue = 0.00, sat = 0.00, val = 0.97 },
    { name = "Silver", hue = 0.60, sat = 0.05, val = 0.75 },
    { name = "Black",  hue = 0.00, sat = 0.00, val = 0.08 },
    { name = "Brown",  hue = 0.07, sat = 0.70, val = 0.45 },
    { name = "Cream",  hue = 0.10, sat = 0.20, val = 0.95 },
}

VEHICLES_RANDOM_1 = {
    "Base.CarNormal",
    "Base.VanAmbulance",
    "Base.CarStationWagon",
    "Base.SportsCar",
    "Base.PickUpTruck",
    "Base.SmallCar",
    "Base.ModernCar02",
    "Base.StepVan",
    "Base.PickUpVan",
    "Base.ModernCar",
    "Base.OffRoad",
    "Base.SUV",
    "Base.Van",
    "Base.SmallCar02",
    "Base.CarLuxury",
    "Base.CarTaxi",
    "Base.CarLightsRanger",
}

---@type table<integer, string>
VEHICLE_TIRES = {
    "TireFrontLeft",
    "TireFrontRight",
    "TireRearLeft",
    "TireRearRight"
}

---@type table<integer, string>
VEHICLE_WINDOWS = {
    "Windshield",
    "WindshieldRear",
    "WindowFrontLeft",
    "WindowFrontRight",
    "WindowMiddleLeft",
    "WindowMiddleRight",
    "WindowRearLeft",
    "WindowRearRight",
}

---@type table<integer, string>
VEHICLE_DOORS = {
    "DoorFrontLeft",
    "DoorFrontRight",
    "DoorMiddleLeft",
    "DoorMiddleRight",
    "DoorRearLeft",
    "DoorRearRight",
    "TrunkDoor",
    "EngineDoor",
}

---@param x number
---@param y number
---@param z number
---@param scriptName string
---@param dir IsoDirections
---@param skinIndex number | nil
---@return BaseVehicle
function ChaosVehicle.spawnVehicleAt(x, y, z, scriptName, dir, skinIndex)
    local x1 = math.floor(x)
    local y1 = math.floor(y)
    local z1 = math.floor(z)
    local square = getCell():getGridSquare(x1, y1, z1)
    ---@diagnostic disable-next-line: param-type-mismatch
    local vehicle = addVehicleDebug(scriptName, dir, skinIndex, square)
    return vehicle
end

--- Spawns a vehicle near the player
---@param scriptName string
---@param radius number
---@param maxTries number
---@return BaseVehicle | nil
---@param addKey boolean
---@param setRandomFuel boolean
---@param setRandomCondition boolean | nil
function ChaosVehicle.spawnVehicleNearPlayer(scriptName, radius, maxTries, addKey, setRandomFuel, setRandomCondition)
    local player = getPlayer()
    if not player then return nil end
    local x  = player:getX()
    local y  = player:getY()
    local z  = 0

    radius   = radius or 12
    maxTries = maxTries or 80
    if setRandomCondition == nil then
        setRandomCondition = true
    end


    for i = 1, maxTries do
        local dx = ZombRand(-radius, radius + 1)
        local dy = ZombRand(-radius, radius + 1)

        local square = getCell():getGridSquare(x + dx, y + dy, z)

        if square then
            -- Check that car can be spawned here
            if square:isOutside()
                and square:isSolidFloor()
                and square:isFree(false)
                and square:isNotBlocked(false)
                and square:isSafeToSpawn()
            then
                local dir = player:getDir()
                local skinIndex = nil
                local vehicle = ChaosVehicle.spawnVehicleAt(x + dx, y + dy, z, scriptName, dir, skinIndex)
                if vehicle then
                    if addKey then
                        ChaosVehicle.giveKeyItemToPlayer(vehicle)
                    end
                    if setRandomFuel then
                        ChaosVehicle.setRandomFuelPercent(vehicle, 0.1, 0.9)
                    end
                    if setRandomCondition then
                        ChaosVehicle.SetRandomVehiclePartsCondition(vehicle)
                    end
                    return vehicle
                end
            end
        end
    end
    return nil
end

--- Puts a key on the door of the vehicle
---@param vehicle BaseVehicle
function ChaosVehicle.giveKeyItemToPlayer(vehicle)
    if not vehicle then return end
    local player = getPlayer()
    if not player then return end

    local key = vehicle:createVehicleKey()
    -- vehicle:setKeyIsOnDoor()
    if key then
        print("[ChaosVehicle] Giving key to player" .. tostring(key))
        player:getInventory():AddItem(key)
    end
end

---@param vehicle BaseVehicle
---@param percent number
function ChaosVehicle.setFuelPercent(vehicle, percent)
    if not vehicle then return end
    local gasTankPart = vehicle:getPartById("GasTank")
    if gasTankPart then
        local maxValue = gasTankPart:getContainerCapacity()

        local newValue = maxValue * percent
        gasTankPart:setContainerContentAmount(newValue)
    end
end

---@param vehicle BaseVehicle
---@param min number
---@param max number
function ChaosVehicle.setRandomFuelPercent(vehicle, min, max)
    if not vehicle then return end
    local percent = ZombRandFloat(min, max)
    ChaosVehicle.setFuelPercent(vehicle, percent)
end

---@param vehicle BaseVehicle
---@param minCondition integer | nil defaults to 0
---@param maxCondition integer | nil defaults to 100
function ChaosVehicle.SetRandomVehiclePartsCondition(vehicle, minCondition, maxCondition)
    if not vehicle then return end

    minCondition = minCondition or 0
    maxCondition = maxCondition or 100

    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            local condition = ChaosUtils.RandIntegerRange(minCondition, maxCondition + 1)
            part:setCondition(condition)
            vehicle:transmitPartCondition(part)
        end
    end
end

---@param square IsoGridSquare
---@param radius number
---@return ArrayList<BaseVehicle>
function ChaosVehicle.GetVehiclesNearby(square, radius)
    local nearbyVehicles = ArrayList:new()
    if not square then
        return nearbyVehicles
    end
    local x = square:getX()
    local y = square:getY()
    local vehicles = getCell():getVehicles()
    local iterator = vehicles:iterator()
    while iterator:hasNext() do
        local vehicle = iterator:next()
        if vehicle then
            local vehicleX = vehicle:getX()
            local vehicleY = vehicle:getY()
            if ChaosUtils.isInRange(x, y, vehicleX, vehicleY, radius) then
                nearbyVehicles:add(vehicle)
            end
        end
    end
    return nearbyVehicles
end

---@param vehicle BaseVehicle
---@param skipDriver boolean
---@return integer
function ChaosVehicle.FindFreeSeat(vehicle, skipDriver)
    local startSeat = skipDriver and 1 or 0

    local max = vehicle:getMaxPassengers()
    for i = startSeat, max do
        if vehicle:isSeatOccupied(i) == false then
            return i
        end
    end
    return -1
end

---@param character IsoGameCharacter
function ChaosVehicle.ExitVehicle(character)
    if not character then return end
    local vehicle = character:getVehicle()
    if not vehicle then return end
    vehicle:exit(character)
end

---@param vehicle BaseVehicle
function ChaosVehicle.DamageVehicleFromExplosion(vehicle)
    if not vehicle then return end

    for _, windowName in ipairs(VEHICLE_WINDOWS) do
        local part = vehicle:getPartById(windowName)
        if part and part:getInventoryItem() then
            ---@diagnostic disable-next-line: param-type-mismatch
            part:setInventoryItem(nil, 10)
            vehicle:transmitPartItem(part)
        end
    end

    for _, wheelName in ipairs(VEHICLE_TIRES) do
        local part = vehicle:getPartById(wheelName)
        if part and part:getInventoryItem() then
            if ChaosUtils.RandInteger(2) == 0 then
                local wheelId = part:getWheelIndex()
                if wheelId then
                    vehicle:setTireRemoved(wheelId, true)
                end
                ---@diagnostic disable-next-line: param-type-mismatch
                part:setInventoryItem(nil, 10)
                vehicle:transmitPartItem(part)
            end
        end
    end

    for _, doorName in ipairs(VEHICLE_DOORS) do
        local part = vehicle:getPartById(doorName)
        if part and part:getInventoryItem() then
            if ChaosUtils.RandInteger(2) == 0 then
                ---@diagnostic disable-next-line: param-type-mismatch
                part:setInventoryItem(nil, 10)
                vehicle:transmitPartItem(part)
            end
        end
    end

    local enginePart = vehicle:getPartById("Engine")
    if enginePart then
        enginePart:damage(50)
        vehicle:transmitEngine()
    end

    local gasTankPart = vehicle:getPartById("GasTank")
    if gasTankPart then
        gasTankPart:damage(50)
        vehicle:transmitPartItem(gasTankPart)
    end

    local batteryPart = vehicle:getPartById("Battery")
    if batteryPart then
        batteryPart:damage(50)
        vehicle:transmitPartItem(batteryPart)
    end

    vehicle:crash(50, true)
    vehicle:updatePartStats()
end

---@return string
function ChaosVehicle.GetRandomVehicleName()
    local randomIndex = ChaosUtils.RandArrayIndex(VEHICLES_RANDOM_1)
    local str = VEHICLES_RANDOM_1[randomIndex]
    if not str then return "Base.CarNormal" end
    return str
end

---@param vehicle BaseVehicle
function ChaosVehicle.SetRandomVehicleColors(vehicle)
    if not vehicle then return end
    local randomIndex = ChaosUtils.RandArrayIndex(VEHICLE_COLORS)
    local color = VEHICLE_COLORS[randomIndex]
    if not color then return end
    vehicle:setColorHSV(color.hue, color.sat, color.val)
end
