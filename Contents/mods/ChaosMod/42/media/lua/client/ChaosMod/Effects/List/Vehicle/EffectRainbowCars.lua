EffectRainbowCars = ChaosEffectBase:derive("EffectRainbowCars", "rainbow_cars")

local RADIUS = 25
local HUE_SPEED = 0.15

---@param vehicle BaseVehicle
---@param time number
local function setVehicleRainbowColor(vehicle, time)
    local hue = (time * HUE_SPEED) % 1.0
    vehicle:setColorHSV(hue, 1.0, 1.0)
end

function EffectRainbowCars:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRainbowCars] OnStart " .. tostring(self.effectId))
end

function EffectRainbowCars:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    local time = ChaosMod.lastTimeTickMs / 1000.0

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            setVehicleRainbowColor(vehicle, time)
        end
    end
end
