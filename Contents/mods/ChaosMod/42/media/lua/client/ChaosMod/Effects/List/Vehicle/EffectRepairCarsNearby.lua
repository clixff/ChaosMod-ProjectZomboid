---@class EffectRepairCarsNearby : ChaosEffectBase
EffectRepairCarsNearby = ChaosEffectBase:derive("EffectRepairCarsNearby", "repair_cars_nearby")

local RADIUS = 45

local WRECK_TO_NORMAL = {
    -- Burnt
    PickupBurnt = "Base.PickUpTruck",
    PickupSpecialBurnt = "Base.PickUpTruck",
    PickUpVanBurnt = "Base.PickUpVan",
    PickUpVanLightsBurnt = "Base.PickUpVanLightsFire",
    CarNormalBurnt = "Base.CarNormal",
    TaxiBurnt = "Base.CarTaxi",
    NormalCarBurntPolice = "Base.CarLightsPolice",
    ModernCarBurnt = "Base.ModernCar",
    ModernCar02Burnt = "Base.ModernCar02",
    SportsCarBurnt = "Base.SportsCar",
    SmallCarBurnt = "Base.SmallCar",
    SmallCar02Burnt = "Base.SmallCar02",
    VanBurnt = "Base.Van",
    VanSeatsBurnt = "Base.VanSeats",
    VanRadioBurnt = "Base.VanRadio",
    SUVBurnt = "Base.SUV",
    OffRoadBurnt = "Base.OffRoad",
    LuxuryCarBurnt = "Base.CarLuxury",
    AmbulanceBurnt = "Base.VanAmbulance",
    RaceCarBurnt = "Base.RaceCar",

    -- Smashed base families
    CarNormal = "Base.CarNormal",
    CarSmall = "Base.SmallCar",
    CarSmall02 = "Base.SmallCar02",
    CarStationWagon = "Base.CarStationWagon",
    CarLuxury = "Base.CarLuxury",
    ModernCar = "Base.ModernCar",
    ModernCar02 = "Base.ModernCar02",
    PickUpTruck = "Base.PickUpTruck",
    PickUpTruckLights = "Base.PickUpTruckLightsFire",
    PickUpVan = "Base.PickUpVan",
    PickUpVanLights = "Base.PickUpVanLightsFire",
    StepVan = "Base.StepVan",
    StepVanMail = "Base.StepVanMail",
    SUV = "Base.SUV",
    OffRoad = "Base.OffRoad",
}

local function scriptExists(scriptName)
    return getScriptManager():getVehicle(scriptName) ~= nil
end

---@param vehicle BaseVehicle
local function getNormalScriptForWreck(vehicle)
    local full = vehicle:getScriptName()
    if not full then return nil end

    local name = full:gsub("^Base%.", "")

    if WRECK_TO_NORMAL[name] and scriptExists(WRECK_TO_NORMAL[name]) then
        return WRECK_TO_NORMAL[name]
    end

    local family = name
        :gsub("SmashedFront$", "")
        :gsub("SmashedRear$", "")
        :gsub("SmashedLeft$", "")
        :gsub("SmashedRight$", "")

    if family ~= name and WRECK_TO_NORMAL[family] and scriptExists(WRECK_TO_NORMAL[family]) then
        return WRECK_TO_NORMAL[family]
    end

    return nil
end

---@param vehicle BaseVehicle
local function fullyRepairVehicle(vehicle)
    if not vehicle then return end

    local normalScript = getNormalScriptForWreck(vehicle)
    if normalScript then
        vehicle:setScriptName(normalScript)
        vehicle:setScript()
    end

    vehicle:repair()

    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            part:repair()

            local door = part:getDoor()
            if door then
                door:setLockBroken(false)
                door:setOpen(false)
                vehicle:transmitPartDoor(part)
            end

            local window = part:getWindow()
            if window then
                window:setOpen(false)
                window:setOpenDelta(0.0)
                vehicle:transmitPartWindow(part)
            end

            local wheelIndex = part:getWheelIndex()
            if wheelIndex ~= -1 then
                local capacity = part:getContainerCapacity()
                if capacity and capacity > 0 then
                    part:setContainerContentAmount(capacity, true, true)
                    vehicle:transmitPartModData(part)
                    vehicle:setTireInflation(wheelIndex, 1.0)
                else
                    vehicle:setTireInflation(wheelIndex, 1.0)
                end
            end
        end
    end

    vehicle:updatePartStats()
    vehicle:updateBulletStats()
end

function EffectRepairCarsNearby:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    if not vehicles then return end

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            fullyRepairVehicle(vehicle)
        end
    end
end

function EffectRepairCarsNearby:OnEnd()
    ChaosEffectBase:OnEnd()
end
