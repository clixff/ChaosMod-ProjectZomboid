---@diagnostic disable: invert-if
---@enum EffectLookBehindYouStatus
local EffectLookBehindYouStatus = {
    IDLE = "idle",
    SPAWNED_ZOMBIE = "spawned-zombie",
    SHOULD_SPAWN_OBJECT_WHEN_LOOKING = "should-spawn-object-when-looking",
    SHOULD_REMOVE_OBJECT_WHEN_NOT_LOOKING = "should-remove-object-when-not-looking",
}

local MAX_RESPAWN_OBJECT_TIMER_MS = 1000
local MAX_UPDATE_SQUARE_TIMER_MS = 1000


---@class EffectLookBehindYou : ChaosEffectBase
---@field isFakeSpawn boolean
---@field squareToSpawnOn IsoGridSquare
---@field soundPlayed boolean
---@field status EffectLookBehindYouStatus
---@field objectSpawned IsoObject | nil
---@field checkTest boolean
---@field respawnObjectTimerMs integer
---@field updateSquareTimerMs integer
---@field isObjectSpawned boolean
---@field spawnedObjectCount integer
EffectLookBehindYou = ChaosEffectBase:derive("EffectLookBehindYou", "look_behind_you")

-- Returns true if the next appearance should be a zombie.
-- fakeChance starts at 0.5 and drops by 0.1 per spawned fake object,
-- expressed as ZombRand(0,10) integers: fakeMax = max(0, 5 - count).
---@param spawnedCount integer
---@return boolean
local function shouldSpawnZombie(spawnedCount)
    local fakeMax = math.max(0, 5 - spawnedCount)
    return ZombRand(0, 10) >= fakeMax
end


---@param player IsoPlayer
---@param tilesBack integer
---@return IsoGridSquare|nil
local function getSquareBehindPlayer(player, tilesBack)
    if not player then return nil end

    local cell = getCell()
    if not cell then return nil end

    -- Player facing direction -> vector (8-dir)
    local dir = player:getDir()
    if not dir then return nil end

    local v = dir:ToVector()
    if not v then return nil end

    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()

    local bx = math.floor(px - (v:getX() * tilesBack))
    local by = math.floor(py - (v:getY() * tilesBack))
    local bz = math.floor(pz)

    return cell:getGridSquare(bx, by, bz)
end

---@param oldSquare IsoGridSquare
---@return IsoGridSquare | nil
local function getRandomSquareNearby(oldSquare)
    if not oldSquare then return nil end

    local x = oldSquare:getX()
    local y = oldSquare:getY()
    local z = oldSquare:getZ()

    local newX = x + ZombRand(-2, 3)
    local newY = y + ZombRand(-2, 3)
    local newZ = z

    return getCell():getGridSquare(newX, newY, newZ)
end

---@param square IsoGridSquare
local function spawnZombie(square)
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local zombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
    if not zombies or zombies:size() == 0 then
        print("[EffectLookBehindYou] Failed to spawn zombie")
        return
    end
    return zombies:get(0)
end

function EffectLookBehindYou:OnStart()
    ChaosEffectBase:OnStart()
    self.status = EffectLookBehindYouStatus.IDLE
    self.updateSquareTimerMs = 0
    self.respawnObjectTimerMs = MAX_RESPAWN_OBJECT_TIMER_MS
    self.spawnedObjectCount = 0
    print("[EffectLookBehindYou] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = getSquareBehindPlayer(player, 4)
    if not square then return end

    self.squareToSpawnOn = square

    print("[EffectLookBehindYou] Square: " .. tostring(square))


    self.isFakeSpawn = true
    self.status = EffectLookBehindYouStatus.SHOULD_SPAWN_OBJECT_WHEN_LOOKING
end

---@param square IsoGridSquare
---@return IsoObject | nil
local function spawnNewObject(square)
    local objectName = "vegetation_ornamental_01_49"
    local obj = IsoObject.new(square, objectName)
    if not obj then
        print("[EffectLookBehindYou] Failed to spawn object")
        return
    end
    return obj
end

function EffectLookBehindYou:OnTick(deltaMs)
    if not self.isFakeSpawn then
        return
    end

    if not self.squareToSpawnOn then
        return
    end

    local canSee = self.squareToSpawnOn:isCanSee(0)

    if not self.isObjectSpawned then
        self.updateSquareTimerMs = self.updateSquareTimerMs + deltaMs
        if self.updateSquareTimerMs >= MAX_UPDATE_SQUARE_TIMER_MS then
            self.updateSquareTimerMs = 0
            self.squareToSpawnOn = getSquareBehindPlayer(getPlayer(), 4)
        end
    end

    -- If object is not spawned, we need to check if player can see the tile
    -- If player can see tile, we need to spawn the object
    if self.status == EffectLookBehindYouStatus.SHOULD_SPAWN_OBJECT_WHEN_LOOKING then
        local canActuallySpawnBasedOnTimer = self.respawnObjectTimerMs >= MAX_RESPAWN_OBJECT_TIMER_MS
        -- If we can see it, check if timer is expired
        if canSee and canActuallySpawnBasedOnTimer then
            if shouldSpawnZombie(self.spawnedObjectCount) then
                self.isFakeSpawn = false
                self.status = EffectLookBehindYouStatus.SPAWNED_ZOMBIE
                spawnZombie(self.squareToSpawnOn)
                return
            end

            self.status = EffectLookBehindYouStatus.SHOULD_REMOVE_OBJECT_WHEN_NOT_LOOKING

            -- Spawn the object
            if self.objectSpawned == nil then
                self.objectSpawned = spawnNewObject(self.squareToSpawnOn)
            end

            if not self.objectSpawned then
                return
            end

            self.objectSpawned:setSquare(self.squareToSpawnOn)
            self.objectSpawned:addToWorld()
            self.squareToSpawnOn:AddTileObject(self.objectSpawned)
            self.isObjectSpawned = true
            self.spawnedObjectCount = self.spawnedObjectCount + 1

            if not self.soundPlayed then
                ChaosUtils.PlayUISound("ZombieSurprisedPlayer", true)
                self.soundPlayed = true
            end
            -- If we should spawn it and can't see, we need to wait some time
        elseif not canSee then
            self.respawnObjectTimerMs = self.respawnObjectTimerMs + deltaMs
        end
        -- If player has seen object, we need to check if player can see the tile
        -- If player can't see tile, we need to remove objectd and find new tile to spawn on
    elseif self.status == EffectLookBehindYouStatus.SHOULD_REMOVE_OBJECT_WHEN_NOT_LOOKING then
        if not canSee then
            self.status = EffectLookBehindYouStatus.SHOULD_SPAWN_OBJECT_WHEN_LOOKING

            -- Remove the object
            if self.objectSpawned then
                self.objectSpawned:removeFromWorld()

                if self.squareToSpawnOn then
                    self.squareToSpawnOn:RemoveTileObject(self.objectSpawned)
                end

                self.objectSpawned:removeFromSquare()
                print("[EffectLookBehindYou] Removed object")
                self.isObjectSpawned = false
                self.squareToSpawnOn = getRandomSquareNearby(self.squareToSpawnOn)
                self.respawnObjectTimerMs = 0
            end
        end
    end
end

function EffectLookBehindYou:OnEnd()
    print("[EffectLookBehindYou] OnEnd")
    if self.objectSpawned then
        self.objectSpawned:removeFromWorld()

        if self.squareToSpawnOn then
            self.squareToSpawnOn:RemoveTileObject(self.objectSpawned)
        end

        self.objectSpawned:removeFromSquare()
        self.objectSpawned = nil
    end
end
