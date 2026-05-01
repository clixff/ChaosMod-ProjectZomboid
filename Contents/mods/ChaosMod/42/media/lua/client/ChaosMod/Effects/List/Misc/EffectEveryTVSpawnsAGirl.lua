---@class EffectEveryTVSpawnsAGirl : ChaosEffectBase
EffectEveryTVSpawnsAGirl = ChaosEffectBase:derive("EffectEveryTVSpawnsAGirl", "every_tv_spawns_a_girl")

---@param obj IsoObject
---@param player IsoPlayer
---@param playerX number
---@param playerY number
---@return boolean
local function spawnGirlAtTV(obj, player, playerX, playerY)
    if not obj or not instanceof(obj, "IsoTelevision") then
        return false
    end

    local square = obj:getSquare()
    if not square then
        return false
    end

    local newSquare = square;
    local originalRoom = square:getRoom();
    local Z = square:getZ();


    ChaosUtils.SquareRingSearchTile_2D(square:getX(), square:getY(), function(sq)
        if sq and sq:isInARoom() and sq:getRoom() == originalRoom then
            newSquare = sq;
            return true
        end
    end, 0, 3, true, true, true, Z - 1, Z + 2)

    if not newSquare then
        return false
    end

    local zombies = ChaosZombie.SpawnZombieAt(newSquare:getX(), newSquare:getY(), newSquare:getZ(), 1, "WeddingDress",
        100)
    if not zombies or zombies:size() == 0 then
        return false
    end

    local zombie = zombies:getFirst()
    if not zombie then
        return false
    end

    zombie:setTurnAlertedValues(math.floor(playerX), math.floor(playerY))
    return true
end

function EffectEveryTVSpawnsAGirl:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local radius = 60
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local playerX = math.floor(player:getX())
    local playerY = math.floor(player:getY())
    local cell = getCell()
    local countSpawned = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if spawnGirlAtTV(obj, player, playerX, playerY) then
                    countSpawned = countSpawned + 1
                end
            end)
        end
    end, 0, radius, false, false, true, -1, 2)

    print("[EffectEveryTVSpawnsAGirl] Spawned " .. tostring(countSpawned) .. " girls from TVs")
end
