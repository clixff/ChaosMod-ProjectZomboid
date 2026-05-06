---@class EffectTeleportToNearestBed : ChaosEffectBase
EffectTeleportToNearestBed = ChaosEffectBase:derive("EffectTeleportToNearestBed", "teleport_to_nearest_bed")



function EffectTeleportToNearestBed:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local px, py, pz = square:getX(), square:getY(), square:getZ()
    local radius = 90

    ---@type IsoGridSquare | nil
    local bestSq = nil
    ---@type IsoObject | nil
    local bedObject = nil

    print("Bed tag is " .. tostring(IsoFlagType.bed))

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return false end

        local hasBed = false

        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            if not obj then return false end
            local isTent = obj:isTent()
            local isBedLike = obj:getProperties():has("BedType")
            local isChair = ISWorldObjectContextMenu.chairCheck(obj)

            if isBedLike then
                print("Found bed-like object " ..
                    tostring(obj:getTileName()) ..
                    " " .. tostring(obj:getSpriteName()) .. " with chair check " .. tostring(isChair))
            end
            if isTent or (isBedLike and isChair ~= true) then
                hasBed = true
                bedObject = obj
                return true
            end

            return false
        end)

        if hasBed then
            bestSq = sq
            return true
        end

        return false
    end, 0, radius, true, false, true, pz - 1, pz + 2)

    if not bestSq then
        print("[EffectTeleportToNearestBed] No bed found nearby")
        return
    end

    -- Find free square near bed
    local x = bestSq:getX()
    local y = bestSq:getY()
    local z = bestSq:getZ()

    ChaosUtils.GetTilesBFS_2D(x, y, function(sq)
        if sq then
            local isFree = sq:isFree(false)
            if isFree then
                bestSq = sq
                return true
            end
        end
    end, 0, 10, true, true, true, z, z)

    ChaosPlayer.TeleportPlayer(player, bestSq)

    if bedObject then
        player:faceThisObject(bedObject)
    end

    if bedObject then
        local itemName = bedObject:getTileName()

        ChaosPlayer.SayLineByColor(player, string.format("Teleported to %s", itemName),
            ChaosPlayerChatColors.red)
    end


    print(string.format("[EffectTeleportToNearestBed] Teleported to bed at %d, %d, %d", bestSq:getX(), bestSq:getY(),
        bestSq:getZ()))
end
