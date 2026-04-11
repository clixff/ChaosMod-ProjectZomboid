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
function ChaosVehicle.spawnVehicleNearPlayer(scriptName, radius, maxTries, addKey, setRandomFuel)
    local player = getPlayer()
    if not player then return nil end
    local x  = player:getX()
    local y  = player:getY()
    local z  = player:getZ()

    radius   = radius or 12
    maxTries = maxTries or 80


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

---@param square IsoGridSquare
---@param radius number
---@return ArrayList<BaseVehicle>
function ChaosVehicle.GetVehiclesNearby(square, radius)
    if not square then return ArrayList:new() end
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local vehicles = getCell():getVehicles()
    ---@type ArrayList<BaseVehicle>
    local nearbyVehicles = ArrayList:new()
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
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

---@return string
function ChaosVehicle.GetRandomVehicleName()
    local randomIndex = math.floor(ZombRandBetween(1, #VEHICLES_RANDOM_1 + 1))
    local str = VEHICLES_RANDOM_1[randomIndex]
    if not str then return "Base.CarNormal" end
    return str
end

function ChaosVehicle.SetRandomVehicleColors(vehicle)
    if not vehicle then return end
    local randomIndex = math.floor(ZombRandBetween(1, #VEHICLE_COLORS + 1))
    local color = VEHICLE_COLORS[randomIndex]
    if not color then return end
    vehicle:setColorHSV(color.hue, color.sat, color.val)
end
