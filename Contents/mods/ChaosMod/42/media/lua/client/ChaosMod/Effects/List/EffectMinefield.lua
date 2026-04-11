---@class EffectMinefield : ChaosEffectBase
---@field spawnedMines table<string, IsoObject>
EffectMinefield = ChaosEffectBase:derive("EffectMinefield", "minefield")

local MINE_SPRITE = "constructedobjects_01_18"
local MINEFIELD_RADIUS = 30
local MINE_SPAWN_CHANCE = 40
local MINE_CLEAR_RADIUS = 2
local EXPLOSION_RADIUS = 3
local MINE_SPAWN_MIN_RADIUS = 3
local MINE_TRIGGER_CENTER_RADIUS = 0.25

---@type EffectMinefield | nil
local LATEST_EFFECT_INSTANCE = nil


---@param zombie IsoZombie
local function HandleZombieUpdate(zombie)
    if not zombie then return end
    if zombie:isDead() then return end

    local square = zombie:getSquare()
    if not square then return end

    if not LATEST_EFFECT_INSTANCE then return end

    LATEST_EFFECT_INSTANCE:TriggerMineAtSquare(square, zombie)
end

---@param x integer
---@param y integer
---@param z integer
---@return string
local function tileKey(x, y, z)
    return x .. "," .. y .. "," .. z
end

---@param square IsoGridSquare
---@return string
local function squareKey(square)
    return tileKey(square:getX(), square:getY(), square:getZ())
end

---@param square IsoGridSquare
---@return boolean
local function isValidMineSquare(square)
    return square ~= nil and square:TreatAsSolidFloor()
end

---@param square IsoGridSquare
function EffectMinefield:SpawnMine(square)
    if not isValidMineSquare(square) then return end

    local key = squareKey(square)
    if self.spawnedMines[key] then return end

    local mine = IsoObject.new(square, MINE_SPRITE)
    if not mine then return end

    mine:setSquare(square)
    mine:addToWorld()
    square:AddTileObject(mine)
    self.spawnedMines[key] = mine
end

---@param key string
function EffectMinefield:RemoveMineByKey(key)
    local mine = self.spawnedMines[key]
    if not mine then return end

    local square = mine:getSquare()
    if square then
        square:RemoveTileObject(mine)
    end

    mine:removeFromWorld()
    mine:removeFromSquare()
    self.spawnedMines[key] = nil
end

function EffectMinefield:ClearSpawnedMines()
    local keys = {}
    for key, _ in pairs(self.spawnedMines) do
        table.insert(keys, key)
    end

    for _, key in ipairs(keys) do
        self:RemoveMineByKey(key)
    end

    self.spawnedMines = {}
end

---@param centerSquare IsoGridSquare
function EffectMinefield:RemoveMinesInRadius(centerSquare)
    local centerX = centerSquare:getX()
    local centerY = centerSquare:getY()
    local centerZ = centerSquare:getZ()

    for x = centerX - MINE_CLEAR_RADIUS, centerX + MINE_CLEAR_RADIUS do
        for y = centerY - MINE_CLEAR_RADIUS, centerY + MINE_CLEAR_RADIUS do
            if ChaosUtils.isInRange(centerX, centerY, x, y, MINE_CLEAR_RADIUS) then
                self:RemoveMineByKey(tileKey(x, y, centerZ))
            end
        end
    end
end

---@param centerSquare IsoGridSquare
function EffectMinefield:SpawnMinefield(centerSquare)
    local centerX = centerSquare:getX()
    local centerY = centerSquare:getY()
    local centerZ = centerSquare:getZ()
    local playerKey = squareKey(centerSquare)

    for x = centerX - MINEFIELD_RADIUS, centerX + MINEFIELD_RADIUS do
        for y = centerY - MINEFIELD_RADIUS, centerY + MINEFIELD_RADIUS do
            local isInMaxRadius = ChaosUtils.isInRange(centerX, centerY, x, y, MINEFIELD_RADIUS)
            local isOutsideMinRadius = not ChaosUtils.isInRange(centerX, centerY, x, y, MINE_SPAWN_MIN_RADIUS)
            if isInMaxRadius and isOutsideMinRadius then
                local square = getCell():getGridSquare(x, y, centerZ)
                if square and squareKey(square) ~= playerKey and ZombRand(100) < MINE_SPAWN_CHANCE then
                    self:SpawnMine(square)
                end
            end
        end
    end
end

---@param square IsoGridSquare
---@param character IsoGameCharacter | nil
function EffectMinefield:TriggerMineAtSquare(square, character)
    if not square then return end
    if not character then return end

    local key = squareKey(square)
    print("[EffectMinefield] Try Trigger mine at square: " .. key .. " with character: " .. tostring(character))
    if not self.spawnedMines[key] then return end

    local tileCenterX = square:getX() + 0.5
    local tileCenterY = square:getY() + 0.5
    local distToCenter = ChaosUtils.distTo(character:getX(), character:getY(), tileCenterX, tileCenterY)
    if distToCenter > MINE_TRIGGER_CENTER_RADIUS then return end

    self:RemoveMinesInRadius(square)

    ChaosVehicle.ExitVehicle(character)

    if instanceof(character, "IsoZombie") then
        print("[EffectMinefield] Zombie died")
        character:setHealth(0)

        ---@diagnostic disable-next-line: param-type-mismatch
        character:DoDeath(instanceItem("Base.BareHands"), nil)
    end

    ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)

    if instanceof(character, "IsoPlayer") then
        character:setKnockedDown(true)
    end
end

function EffectMinefield:OnStart()
    ChaosEffectBase:OnStart()
    LATEST_EFFECT_INSTANCE = self
    self.spawnedMines = {}
    -- Events.OnZombieUpdate.Add(HandleZombieUpdate)

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    self:SpawnMinefield(square)
    print("[EffectMinefield] OnStart " .. tostring(self.effectId))
end

---@param _deltaMs integer
function EffectMinefield:OnTick(_deltaMs)
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    self:TriggerMineAtSquare(square, player)
end

function EffectMinefield:OnEnd()
    ChaosEffectBase:OnEnd()
    -- Events.OnZombieUpdate.Remove(HandleZombieUpdate)
    self:ClearSpawnedMines()
    print("[EffectMinefield] OnEnd")
end
