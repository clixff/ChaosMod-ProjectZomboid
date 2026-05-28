EffectSmashNearbyWindows = ChaosEffectBase:derive("EffectSmashNearbyWindows", "smash_nearby_windows")

local BUILDING_WINDOW_RADIUS = 15
local VEHICLE_WINDOW_RADIUS = 50

function EffectSmashNearbyWindows:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSmashNearbyWindows] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local x, y = square:getX(), square:getY()
    local Z = square:getZ()

    local countSmashed = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if not obj or not instanceof(obj, "IsoWindow") then
                    return false
                end
                ---@type IsoWindow
                local window = obj
                if window:isSmashed() == false then
                    window:smashWindow()
                    countSmashed = countSmashed + 1
                end
            end)
        end
    end, 0, BUILDING_WINDOW_RADIUS, false, false, true, Z - 1, Z + 3)

    local nearbyVehicles = ChaosVehicle.GetVehiclesNearby(square, VEHICLE_WINDOW_RADIUS)
    if nearbyVehicles then
        for i = 0, nearbyVehicles:size() - 1 do
            local vehicle = nearbyVehicles:get(i)
            if vehicle then
                local changed = false
                for j = 0, vehicle:getPartCount() - 1 do
                    local part = vehicle:getPartByIndex(j)
                    if part and part:getWindow() and part:getInventoryItem() then
                        ---@diagnostic disable-next-line: param-type-mismatch
                        part:setInventoryItem(nil, 10)
                        vehicle:transmitPartItem(part)
                        countSmashed = countSmashed + 1
                        changed = true
                    end
                end
                if changed then
                    vehicle:updatePartStats()
                end
            end
        end
    end

    print("[EffectSmashNearbyWindows] Smashed " .. tostring(countSmashed) .. " windows")
end
