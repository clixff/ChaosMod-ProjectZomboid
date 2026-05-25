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

}

local SMASHED_FAMILY_TO_NORMAL = {
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

    -- Only burnt exact names are converted here. Do not convert already-valid
    -- vehicles such as Base.CarNormal, otherwise they get a script reload and
    -- can change skin/color.
    if string.find(name, "Burnt", 1, true) and WRECK_TO_NORMAL[name] and scriptExists(WRECK_TO_NORMAL[name]) then
        return WRECK_TO_NORMAL[name]
    end

    local family = name
        :gsub("SmashedFront$", "")
        :gsub("SmashedRear$", "")
        :gsub("SmashedLeft$", "")
        :gsub("SmashedRight$", "")

    if family ~= name and SMASHED_FAMILY_TO_NORMAL[family] and scriptExists(SMASHED_FAMILY_TO_NORMAL[family]) then
        return SMASHED_FAMILY_TO_NORMAL[family]
    end

    return nil
end

---@param vehicle BaseVehicle
---@param scriptName string
local function safeSetVehicleScript(vehicle, scriptName)
    if not vehicle or not scriptName or not scriptExists(scriptName) then return false end

    local hue = vehicle:getColorHue()
    local saturation = vehicle:getColorSaturation()
    local value = vehicle:getColorValue()
    local skinIndex = vehicle:getSkinIndex()

    vehicle:setScriptName(scriptName)
    -- setScript() alone can leave Bullet physics with the old wheel count,
    -- which causes invalid wheel-index crashes during tire init/inflation.
    vehicle:scriptReloaded(true)

    if hue and saturation and value then
        vehicle:setColorHSV(hue, saturation, value)
    end
    if skinIndex and skinIndex >= 0 and skinIndex < vehicle:getSkinCount() then
        vehicle:setSkinIndex(skinIndex)
        vehicle:updateSkin()
    end

    return true
end

---@param vehicle BaseVehicle
local function fullyRepairVehicle(vehicle)
    if not vehicle then return end

    local normalScript = getNormalScriptForWreck(vehicle)
    if normalScript then
        safeSetVehicleScript(vehicle, normalScript)
    end

    vehicle:repair()

    local script = vehicle:getScript()
    local wheelCount = script and script:getWheelCount() or 0

    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            local door = part:getDoor()
            if door then
                -- Fix broken locks, but don't lock/unlock or open/close doors.
                if door:isLockBroken() then
                    door:setLockBroken(false)
                    vehicle:transmitPartDoor(part)
                end
            end

            local wheelIndex = part:getWheelIndex()
            if wheelIndex and wheelIndex >= 0 and wheelIndex < wheelCount then
                local capacity = part:getContainerCapacity()
                if capacity and capacity > 0 then
                    part:setContainerContentAmount(capacity, true, true)
                    vehicle:transmitPartModData(part)
                end
                vehicle:setTireInflation(wheelIndex, 1.0)
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
