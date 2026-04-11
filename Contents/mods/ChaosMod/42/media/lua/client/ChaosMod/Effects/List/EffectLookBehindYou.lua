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
EffectLookBehindYou = ChaosEffectBase:derive("EffectLookBehindYou", "look_behind_you")


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
    print("[EffectLookBehindYou] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = getSquareBehindPlayer(player, 4)
    if not square then return end

    self.squareToSpawnOn = square

    print("[EffectLookBehindYou] Square: " .. tostring(square))

    local roll = ZombRand(0, 5) -- 0-4
    if roll < 4 then
        self.isFakeSpawn = true
        self.status = EffectLookBehindYouStatus.SHOULD_SPAWN_OBJECT_WHEN_LOOKING
    else
        self.status = EffectLookBehindYouStatus.SPAWNED_ZOMBIE
        -- Spawn 1 zombie at the square.
        spawnZombie(self.squareToSpawnOn)
    end
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
            -- Roll random number to decide if we should spawn object or zombie
            local roll = ZombRand(0, 5) -- 0-4
            if roll < 4 then
                self.status = EffectLookBehindYouStatus.SHOULD_REMOVE_OBJECT_WHEN_NOT_LOOKING
            else
                self.isFakeSpawn = false
                self.status = EffectLookBehindYouStatus.SPAWNED_ZOMBIE
                spawnZombie(self.squareToSpawnOn)
                return
            end


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
