---@class EffectEveryRoomHasAZombie : ChaosEffectBase
EffectEveryRoomHasAZombie = ChaosEffectBase:derive("EffectEveryRoomHasAZombie", "every_room_has_a_zombie")

local SEARCH_RADIUS = 70
local AGGRO_DIST = 15

function EffectEveryRoomHasAZombie:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local playerZ = playerSquare:getZ()
    local playerX = player:getX()
    local playerY = player:getY()
    local cell = getCell()
    if not cell then return end

    ---@type table<RoomDef|IsoRoom, boolean>
    local visitedRooms = {}
    local spawnedCount = 0

    ChaosUtils.SquareRingSearchTile_2D(playerSquare:getX(), playerSquare:getY(), function(sq)
        if not sq then return end

        local currentZ = sq:getZ()
        local currentSquare = sq

        while currentSquare do
            local room = currentSquare:getRoom()
            if not room then break end

            -- Use the actual room/RoomDef object as the visited key, not getRoomIDString().
            -- getRoomIDString() is only the square's serialized meta-room id and is easy to
            -- log many times while iterating all tiles in the same room.
            local roomDef = room:getRoomDef()
            local roomKey = roomDef or room
            if not visitedRooms[roomKey] then
                visitedRooms[roomKey] = true

                local spawnSquare = room:getRandomFreeSquare() or room:getRandomSquare() or currentSquare
                local sx, sy, sz = spawnSquare:getX(), spawnSquare:getY(), spawnSquare:getZ()
                print("[EffectEveryRoomHasAZombie] Room: " .. tostring(roomDef and roomDef:getIDString() or currentSquare:getRoomIDString()) .. " spawn: " .. sx .. "," .. sy .. "," .. sz)
                local zombies = ChaosZombie.SpawnZombieAt(sx, sy, sz, 1, "Tourist", 50)
                if zombies and zombies:size() > 0 then
                    local zombie = zombies:getFirst()
                    if zombie then
                        zombie:dressInRandomOutfit()
                        spawnedCount = spawnedCount + 1

                        if sz == playerZ and ChaosUtils.distTo(sx, sy, playerX, playerY) < AGGRO_DIST then
                            ChaosZombie.MoveToPlayerSpotted(zombie, player)
                        end
                    end
                end
            end

            currentZ = currentZ + 1
            currentSquare = cell:getGridSquare(currentSquare:getX(), currentSquare:getY(), currentZ)
        end
    end, 0, SEARCH_RADIUS, false, false, true, playerZ, playerZ)

    print("[EffectEveryRoomHasAZombie] Spawned zombies: " .. tostring(spawnedCount))
end
