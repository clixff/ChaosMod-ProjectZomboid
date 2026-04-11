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

    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = cell:getGridSquare(x + dx, y + dy, z)
            if sq then
                local objects = sq:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if instanceof(obj, "IsoWindow") then
                        ---@type IsoWindow
                        local window = obj
                        if window:isSmashed() == false then
                            window:smashWindow()
                            countSmashed = countSmashed + 1
                        end
                    end
                end
            end
        end
    end

    print("[EffectSmashNearbyWindows] Smashed " .. tostring(countSmashed) .. " windows")
end
