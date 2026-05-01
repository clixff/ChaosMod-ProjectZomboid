---@class EffectEveryTVSpawnsAGirl : ChaosEffectBase
EffectEveryTVSpawnsAGirl = ChaosEffectBase:derive("EffectEveryTVSpawnsAGirl", "every_tv_spawns_a_girl")

local function spawnGirlAtTV(obj, player, playerX, playerY)
    if not obj or not instanceof(obj, "IsoTelevision") then
        return false
    end

    local square = obj:getSquare()
    if not square then
        return false
    end

    local zombies = ChaosZombie.SpawnZombieAt(square:getX(), square:getY(), square:getZ(), 1, "WeddingDress", 100)
    if not zombies or zombies:size() == 0 then
        return false
    end

    local zombie = zombies:getFirst()
    if not zombie then
        return false
    end

    zombie:setTurnAlertedValues(playerX, playerY)
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

    for dz = -1, 2 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                local sq = cell:getGridSquare(x + dx, y + dy, z + dz)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        if spawnGirlAtTV(objects:get(i), player, playerX, playerY) then
                            countSpawned = countSpawned + 1
                        end
                    end
                end
            end
        end
    end

    print("[EffectEveryTVSpawnsAGirl] Spawned " .. tostring(countSpawned) .. " girls from TVs")
end
