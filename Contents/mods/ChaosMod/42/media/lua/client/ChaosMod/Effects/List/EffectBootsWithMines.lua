---@class EffectBootsWithMines : ChaosEffectBase
---@field startDelayMs integer
---@field lastSquareX integer | nil
---@field lastSquareY integer | nil
---@field lastSquareZ integer | nil
---@field visitedTiles table<string, boolean>
---@field spawnedObjects table<integer, IsoObject>
EffectBootsWithMines = ChaosEffectBase:derive("EffectBootsWithMines", "boots_with_mines")

local START_DELAY_MS = 1500

---@param x integer
---@param y integer
---@return string
local function tileKey(x, y)
    return x .. "," .. y
end

---@param _square IsoGridSquare
function EffectBootsWithMines:SpawnNewObject(_square)
    -- spawn fake sprite
    local sprite = "constructedobjects_01_18"
    local prop = IsoObject.new(_square, sprite)
    if prop then
        prop:setSquare(_square)
        prop:addToWorld()
        _square:AddTileObject(prop)
        table.insert(self.spawnedObjects, prop)
    end
end

function EffectBootsWithMines:ClearSpawnedObjects()
    for _, prop in ipairs(self.spawnedObjects) do
        local square = prop:getSquare()
        if square then
            square:RemoveTileObject(prop)
        end
        prop:removeFromWorld()
        prop:removeFromSquare()
    end
    self.spawnedObjects = {}
end

function EffectBootsWithMines:OnStart()
    ChaosEffectBase:OnStart()
    self.startDelayMs = 0
    self.lastSquareX = nil
    self.lastSquareY = nil
    self.lastSquareZ = nil
    self.visitedTiles = {}
    self.spawnedObjects = {}
    print("[EffectBootsWithMines] OnStart " .. tostring(self.effectId))
end

function EffectBootsWithMines:OnTick(deltaMs)
    self.startDelayMs = self.startDelayMs + deltaMs
    if self.startDelayMs < START_DELAY_MS then return end

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local currentX = square:getX()
    local currentY = square:getY()
    local currentZ = square:getZ()

    -- Initialise on first tick after delay
    if self.lastSquareX == nil then
        self.lastSquareX = currentX
        self.lastSquareY = currentY
        self.lastSquareZ = currentZ
        return
    end

    -- Nothing to do if the player hasn't moved to a new square
    if currentX == self.lastSquareX and currentY == self.lastSquareY then
        return
    end

    -- Safe cast: nil case is handled by the guard above
    local prevX = self.lastSquareX --[[@as integer]]
    local prevY = self.lastSquareY --[[@as integer]]
    local prevZ = self.lastSquareZ --[[@as integer]]
    local prevKey = tileKey(prevX, prevY)
    local currentKey = tileKey(currentX, currentY)

    -- Store the previous square as visited and place a (future) object there
    if not self.visitedTiles[prevKey] then
        self.visitedTiles[prevKey] = true
        local prevSquare = getCell():getGridSquare(prevX, prevY, prevZ)
        if prevSquare then
            self:SpawnNewObject(prevSquare)
        end
    end

    -- If the player stepped onto an already-visited square, trigger the mine
    if self.visitedTiles[currentKey] then
        print("[EffectBootsWithMines] Mine triggered at " .. currentKey)

        ChaosVehicle.ExitVehicle(player)
        ChaosUtils.TriggerExplosionAt(square, 3)

        player:setKnockedDown(true)

        self.visitedTiles = {}
        self:ClearSpawnedObjects()
    end

    self.lastSquareX = currentX
    self.lastSquareY = currentY
    self.lastSquareZ = currentZ
end

function EffectBootsWithMines:OnEnd()
    ChaosEffectBase:OnEnd()
    self:ClearSpawnedObjects()
    self.visitedTiles = {}
    print("[EffectBootsWithMines] OnEnd")
end
