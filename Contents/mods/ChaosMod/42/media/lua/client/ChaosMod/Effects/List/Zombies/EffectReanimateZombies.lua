EffectReanimateZombies = ChaosEffectBase:derive("EffectReanimateZombies", "reanimate_zombies")

function EffectReanimateZombies:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    local radius = 40

    local minZ = z - 1
    local maxZ = z + 2
    local cell = getCell()

    local countReanimated = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            local objects = sq:getStaticMovingObjects()
            for i = 0, objects:size() - 1 do
                local obj = objects:get(i)
                if instanceof(obj, "IsoDeadBody") then
                    ---@type IsoDeadBody
                    local deadBody = obj
                    if deadBody.reanimate then
                        deadBody:reanimate()
                        countReanimated = countReanimated + 1
                    end
                end
            end
        end
    end, 0, radius, false, false, true, minZ, maxZ)

    print("[EffectReanimateZombies] Reanimated " .. tostring(countReanimated) .. " zombies")
end
