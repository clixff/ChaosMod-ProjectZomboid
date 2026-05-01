EffectSmashNearbyWindows = ChaosEffectBase:derive("EffectSmashNearbyWindows", "smash_nearby_windows")

function EffectSmashNearbyWindows:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSmashNearbyWindows] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 15
    local x, y, z = square:getX(), square:getY(), square:getZ()

    local cell = getCell()

    local countSmashed = 0

    local Z = square:getZ()

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
    end, 0, radius, false, false, true, Z - 1, Z + 3)


    print("[EffectSmashNearbyWindows] Smashed " .. tostring(countSmashed) .. " windows")
end
