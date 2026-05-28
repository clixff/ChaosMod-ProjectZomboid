---@class EffectZombieSpawnerNearby : ChaosEffectBase
---@field crate IsoThumpable | nil
---@field spawnTimer ChaosManualTimer
EffectZombieSpawnerNearby = ChaosEffectBase:derive("EffectZombieSpawnerNearby", "zombie_spawner_nearby")

local SPAWN_INTERVAL_MS = 4000
local MIN_DIST_FROM_PLAYER = 5
local MAX_DIST_FROM_PLAYER = 10
local SPAWN_SEARCH_MIN_RADIUS = 2
local SPAWN_SEARCH_MAX_RADIUS = 10

---@param square IsoGridSquare?
---@return IsoThumpable | nil
local function spawnStaticMilitaryCrate(square)
    if not square then return nil end

    local sprite = "location_military_generic_01_1"
    ---@diagnostic disable-next-line: param-type-mismatch
    local obj = IsoThumpable.new(getCell(), square, sprite, false, nil)

    obj:setName("Military Crate")
    obj:setIsThumpable(false)
    obj:setIsContainer(false)
    obj:setCanBarricade(false)
    obj:setBlockAllTheSquare(false)
    obj:setCanPassThrough(true)
    obj:setIsDismantable(false)
    obj:setCanBePlastered(false)

    square:AddSpecialObject(obj)

    if isServer() then
        obj:transmitCompleteItemToClients()
    end

    return obj
end

function EffectZombieSpawnerNearby:OnStart()
    ChaosEffectBase:OnStart()
    self.crate = nil
    self.spawnTimer = ChaosManualTimer.new(SPAWN_INTERVAL_MS)

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil,
        MIN_DIST_FROM_PLAYER, MAX_DIST_FROM_PLAYER, 50, true, true, false)
    if not square then return end

    self.crate = spawnStaticMilitaryCrate(square)
end

---@param deltaMs integer
function EffectZombieSpawnerNearby:OnTick(deltaMs)
    if not self.crate then return end

    self.spawnTimer:add(deltaMs)
    if not self.spawnTimer:isEnded() then return end
    self.spawnTimer:reset()

    local crateSquare = self.crate:getSquare()
    if not crateSquare then return end

    local cx = crateSquare:getX()
    local cy = crateSquare:getY()
    local cz = crateSquare:getZ()

    ChaosUtils.SquareRingSearchTile_2D(cx, cy, function(sq)
        if not sq then return false end
        local zombies = ChaosZombie.SpawnZombieAt(sq:getX(), sq:getY(), sq:getZ(), 1, "Tourist", 50)
        if zombies and not zombies:isEmpty() then
            local zombie = zombies:getFirst()
            if zombie then
                zombie:dressInRandomOutfit()

                local player = getPlayer()
                if player then
                    local px = math.floor(player:getX())
                    local py = math.floor(player:getY())
                    local pz = math.floor(player:getZ())

                    zombie:pathToSound(px, py, pz)
                    zombie:setLastHeardSound(px, py, pz)
                end
            end
        end
        return true
    end, SPAWN_SEARCH_MIN_RADIUS, SPAWN_SEARCH_MAX_RADIUS, true, true, true, cz, cz)
end

function EffectZombieSpawnerNearby:OnEnd()
    ChaosEffectBase:OnEnd()

    local crate = self.crate
    if not crate then return end
    local square = crate:getSquare()
    if not square then return end

    square:transmitRemoveItemFromSquare(crate)
end
