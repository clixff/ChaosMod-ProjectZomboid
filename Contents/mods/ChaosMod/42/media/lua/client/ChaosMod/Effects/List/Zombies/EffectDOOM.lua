---@class EffectDOOM : ChaosEffectBase
---@field spawnedZombies ArrayList<IsoZombie>
---@field shotgun HandWeapon | nil
---@field attackFinishedHandler fun(player: IsoPlayer, weapon: HandWeapon) | nil
---@field zombieMoveTimerMs integer
EffectDOOM = ChaosEffectBase:derive("EffectDOOM", "doom")

local ZOMBIES_TO_SPAWN = 30
local MIN_SPAWN_RADIUS = 8
local MAX_SPAWN_RADIUS = 10
local MAX_BFS_RADIUS = 6
local ZOMBIE_MOVE_INTERVAL_MS = 1000

---@param weapon HandWeapon | nil
local function refillShotgun(weapon)
    if not weapon then return end
    if weapon:getFullType() ~= "Base.Shotgun" then return end

    weapon:setCurrentAmmoCount(5)
    weapon:setRoundChambered(true)
    weapon:setSpentRoundChambered(false)

    weapon:setJammed(false)
    weapon:setJamGunChance(0)
end

---@param player IsoPlayer
---@param item InventoryItem | nil
local function removeItemFromPlayer(player, item)
    if not player or not item then return end

    player:removeFromHands(item)

    local worn = player:getWornItems()
    if worn and worn:contains(item) then
        player:removeWornItem(item)
    end

    item:Remove()
end

---@param zombie IsoZombie | nil
local function removeZombie(zombie)
    if not zombie then return end

    pcall(function()
        zombie:removeFromWorld()
        zombie:removeFromSquare()
    end)
end

---@param usedSquares table<string, boolean>
---@param square IsoGridSquare | nil
---@return boolean
local function isUnusedSquare(usedSquares, square)
    if not square then return false end

    local key = tostring(square:getX()) .. ":" .. tostring(square:getY()) .. ":" .. tostring(square:getZ())
    return usedSquares[key] ~= true
end

---@param usedSquares table<string, boolean>
---@param square IsoGridSquare | nil
local function markSquareUsed(usedSquares, square)
    if not square then return end

    local key = tostring(square:getX()) .. ":" .. tostring(square:getY()) .. ":" .. tostring(square:getZ())
    usedSquares[key] = true
end

---@param x integer
---@param y integer
---@param targetZ integer
---@return IsoGridSquare[]
function EffectDOOM.CollectSpawnCandidates(x, y, targetZ)
    ---@type IsoGridSquare[]
    local squares = {}

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(square)
        if square then
            squares[#squares + 1] = square
        end
        return false
    end, MIN_SPAWN_RADIUS, MAX_SPAWN_RADIUS, false, false, true, targetZ, targetZ)

    return squares
end

---@param square IsoGridSquare | nil
---@param usedSquares table<string, boolean>
---@return IsoGridSquare | nil
function EffectDOOM.ResolveSpawnSquare(square, usedSquares)
    if not square then return nil end

    if square:isFree(false) and isUnusedSquare(usedSquares, square) then
        return square
    end

    local resolvedSquare = nil
    local z = square:getZ()

    ChaosUtils.GetTilesBFS_2D(square:getX(), square:getY(), function(candidate)
        if candidate and candidate:isFree(false) and isUnusedSquare(usedSquares, candidate) then
            resolvedSquare = candidate
            return true
        end

        return false
    end, 0, MAX_BFS_RADIUS, true, true, true, z, z)

    return resolvedSquare
end

---@param player IsoPlayer
---@param targetZ integer
---@param usedSquares table<string, boolean>
function EffectDOOM:SpawnZombiesFromZLevel(player, targetZ, usedSquares)
    local square = player:getSquare()
    if not square then return end

    local candidates = EffectDOOM.CollectSpawnCandidates(square:getX(), square:getY(), targetZ)

    while #candidates > 0 and self.spawnedZombies:size() < ZOMBIES_TO_SPAWN do
        local candidateIndex = ChaosUtils.RandArrayIndex(candidates)
        local candidateSquare = table.remove(candidates, candidateIndex)
        local spawnSquare = EffectDOOM.ResolveSpawnSquare(candidateSquare, usedSquares)

        if spawnSquare then
            local zombies = ChaosZombie.SpawnZombieAt(spawnSquare:getX(), spawnSquare:getY(), spawnSquare:getZ(), 1,
                "Tourist", 50)
            if zombies and zombies:size() > 0 then
                local zombie = zombies:getFirst()
                if zombie then
                    self.spawnedZombies:add(zombie)
                    markSquareUsed(usedSquares, spawnSquare)
                end
            end
        end
    end
end

function EffectDOOM:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    self.spawnedZombies = ArrayList.new()

    local primaryItem = player:getPrimaryHandItem()
    if primaryItem then
        player:removeFromHands(primaryItem)
    end

    local secondaryItem = player:getSecondaryHandItem()
    if secondaryItem and secondaryItem ~= primaryItem then
        player:removeFromHands(secondaryItem)
    end

    local inventory = player:getInventory()
    if inventory then
        local shotgun = inventory:AddItem("Base.Shotgun")
        if shotgun then
            self.shotgun = shotgun
            player:setPrimaryHandItem(shotgun)
            player:setSecondaryHandItem(shotgun)
            refillShotgun(shotgun)
            ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "unlimited_ammo"),
                ChaosPlayerChatColors.green)
        end
    end

    self.attackFinishedHandler = function(attackPlayer, weapon)
        if not attackPlayer or attackPlayer ~= player then return end
        refillShotgun(weapon)
        if self.shotgun then
            refillShotgun(self.shotgun)
        end
    end
    Events.OnPlayerAttackFinished.Add(self.attackFinishedHandler)

    self.zombieMoveTimerMs = 0

    local usedSquares = {}
    local playerZ = playerSquare:getZ()

    self:SpawnZombiesFromZLevel(player, playerZ, usedSquares)
    if self.spawnedZombies:size() < ZOMBIES_TO_SPAWN and playerZ ~= 0 then
        self:SpawnZombiesFromZLevel(player, 0, usedSquares)
    end
end

---@param deltaMs integer
function EffectDOOM:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    if self.shotgun then
        refillShotgun(self.shotgun)
    end

    self.zombieMoveTimerMs = self.zombieMoveTimerMs + deltaMs
    if self.zombieMoveTimerMs < ZOMBIE_MOVE_INTERVAL_MS then
        return
    end
    self.zombieMoveTimerMs = 0

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()

    for i = 0, self.spawnedZombies:size() - 1 do
        local zombie = self.spawnedZombies:get(i)
        if zombie and zombie:isAlive() then
            ChaosZombie.MoveToLocation(zombie, x, y, z, false, false, true, false)
        end
    end
end

function EffectDOOM:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.attackFinishedHandler then
        Events.OnPlayerAttackFinished.Remove(self.attackFinishedHandler)
        self.attackFinishedHandler = nil
    end

    local player = getPlayer()
    if player and self.shotgun then
        removeItemFromPlayer(player, self.shotgun)
    end
    self.shotgun = nil

    if self.spawnedZombies then
        for i = 0, self.spawnedZombies:size() - 1 do
            removeZombie(self.spawnedZombies:get(i))
        end
        self.spawnedZombies:clear()
    end
end
