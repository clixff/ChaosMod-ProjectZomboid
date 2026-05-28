---@class ChaosOilPuddle
---@field x integer
---@field y integer
---@field z integer
---@field centerX number
---@field centerY number
---@field square IsoGridSquare
---@field marker WorldMarkers.GridSquareMarker?
---@field playerCooldownMs integer

---@class ChaosOilKnockedZombie
---@field zombie IsoZombie
---@field highlightMs integer

---@class EffectSlipperyOilPuddles : ChaosEffectBase
---@field puddles ChaosOilPuddle[]
---@field playerHighlightMs integer
---@field knockedZombies table<integer, ChaosOilKnockedZombie>
---@field markerUpdateTimer ChaosManualTimer
---@field playerCheckTimer ChaosManualTimer
---@field zombieCheckTimer ChaosManualTimer
EffectSlipperyOilPuddles = ChaosEffectBase:derive("EffectSlipperyOilPuddles", "slippery_oil_puddles")

local SEARCH_RANGE = 80
local MIN_SPAWN_DIST_FROM_PLAYER = 4.0
local SPAWN_CHANCE = 0.1
local MIN_DIST_BETWEEN_PUDDLES = 4.0
local PUDDLE_RADIUS = 2.0
local MARKER_RADIUS = PUDDLE_RADIUS * math.sqrt(2.0)
local PLAYER_KNOCKDOWN_COOLDOWN_MS = 8000
local HIGHLIGHT_DURATION_MS = 600
local MARKER_RENDER_RADIUS = 10.0
local MARKER_RENDER_Z_DIFF = 0.6
local MARKER_UPDATE_INTERVAL_MS = 100
local PLAYER_CHECK_INTERVAL_MS = 16
local ZOMBIE_CHECK_INTERVAL_MS = 1000
local ZOMBIE_SCAN_RADIUS = 30

local COLOR_R = 0.05
local COLOR_G = 0.05
local COLOR_B = 0.05

---@param puddles ChaosOilPuddle[]
---@param x integer
---@param y integer
---@return boolean
local function hasPuddleNearby(puddles, x, y)
    for i = 1, #puddles do
        local p = puddles[i]
        if ChaosUtils.isInRange(p.x, p.y, x, y, MIN_DIST_BETWEEN_PUDDLES) then
            return true
        end
    end
    return false
end

---@param character IsoGameCharacter
local function applyBlackHighlight(character)
    ChaosUtils.SetCharacterOutlineHighlightEnabled(0, character, COLOR_R, COLOR_G, COLOR_B, 1.0)
end

---@param character IsoGameCharacter?
local function clearBlackHighlight(character)
    if not character then return end
    ChaosUtils.SetCharacterOutlineHighlightDisabled(character)
end

---@param player IsoPlayer
local function triggerFall(player)
    player:clearVariable("BumpFallType")
    player:setBumpStaggered(true)
    player:setBumpType("stagger")
    player:setBumpFall(true)
    player:setBumpFallType("pushedBehind")
end

---@param self EffectSlipperyOilPuddles
---@param player IsoPlayer
local function knockdownPlayer(self, player)
    triggerFall(player)
    self.playerHighlightMs = HIGHLIGHT_DURATION_MS
    applyBlackHighlight(player)
end

---@param self EffectSlipperyOilPuddles
---@param zombie IsoZombie
local function knockdownZombie(self, zombie)
    zombie:setKnockedDown(true)
    applyBlackHighlight(zombie)
    self.knockedZombies[zombie:getID()] = {
        zombie = zombie,
        highlightMs = HIGHLIGHT_DURATION_MS,
    }
end

---@param puddle ChaosOilPuddle
local function createMarker(puddle)
    if puddle.marker then return end
    local markers = getWorldMarkers()
    if not markers then return end
    puddle.marker = markers:addGridSquareMarker(puddle.square, COLOR_R, COLOR_G, COLOR_B, true, MARKER_RADIUS)
    if puddle.marker then
        puddle.marker:setScaleCircleTexture(false)
    end
end

---@param puddle ChaosOilPuddle
local function removeMarker(puddle)
    if not puddle.marker then return end
    puddle.marker:remove()
    puddle.marker = nil
end

---@param puddles ChaosOilPuddle[]
---@param player IsoPlayer
local function updatePuddleMarkers(puddles, player)
    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()
    for i = 1, #puddles do
        local puddle = puddles[i]
        local inRange = ChaosUtils.isInRange(px, py, puddle.centerX, puddle.centerY, MARKER_RENDER_RADIUS)
            and math.abs(pz - puddle.z) <= MARKER_RENDER_Z_DIFF
        if inRange and not puddle.marker then
            createMarker(puddle)
        elseif not inRange and puddle.marker then
            removeMarker(puddle)
        end
    end
end

---@param puddles ChaosOilPuddle[]
---@param cx number
---@param cy number
---@param cz integer
---@return ChaosOilPuddle?
local function findPuddleAt(puddles, cx, cy, cz)
    for i = 1, #puddles do
        local puddle = puddles[i]
        if puddle.z == cz and ChaosUtils.isInRange(cx, cy, puddle.centerX, puddle.centerY, PUDDLE_RADIUS) then
            return puddle
        end
    end
    return nil
end

---@param self EffectSlipperyOilPuddles
---@param player IsoPlayer
local function checkZombiesInPuddles(self, player)
    local px = player:getX()
    local py = player:getY()
    local pz = math.floor(player:getZ())

    ChaosZombie.ForEachZombieInRange(px, py, ZOMBIE_SCAN_RADIUS, function(zombie)
        if not zombie or not zombie:isAlive() then return end
        if zombie:getVehicle() then return end
        if self.knockedZombies[zombie:getID()] then return end

        local zz = math.floor(zombie:getZ())
        local puddle = findPuddleAt(self.puddles, zombie:getX(), zombie:getY(), zz)
        if puddle then
            knockdownZombie(self, zombie)
        end
    end, false, pz)
end

---@param self EffectSlipperyOilPuddles
---@param deltaMs integer
local function tickKnockedZombies(self, deltaMs)
    for id, entry in pairs(self.knockedZombies) do
        entry.highlightMs = entry.highlightMs - deltaMs
        if entry.highlightMs <= 0 then
            clearBlackHighlight(entry.zombie)
            self.knockedZombies[id] = nil
        else
            applyBlackHighlight(entry.zombie)
        end
    end
end

function EffectSlipperyOilPuddles:OnStart()
    ChaosEffectBase:OnStart()

    self.puddles = {}
    self.playerHighlightMs = 0
    self.knockedZombies = {}
    self.markerUpdateTimer = ChaosManualTimer.new(MARKER_UPDATE_INTERVAL_MS)
    self.playerCheckTimer = ChaosManualTimer.new(PLAYER_CHECK_INTERVAL_MS)
    self.zombieCheckTimer = ChaosManualTimer.new(ZOMBIE_CHECK_INTERVAL_MS)

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local px = playerSquare:getX()
    local py = playerSquare:getY()
    local pz = playerSquare:getZ()

    local puddles = self.puddles

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end
        if ChaosUtils.RandFloat(0, 1) > SPAWN_CHANCE then return end

        local sx = sq:getX()
        local sy = sq:getY()
        if hasPuddleNearby(puddles, sx, sy) then return end

        ---@type ChaosOilPuddle
        local puddle = {
            x = sx,
            y = sy,
            z = sq:getZ(),
            centerX = sx + 0.5,
            centerY = sy + 0.5,
            square = sq,
            marker = nil,
            playerCooldownMs = 0,
        }
        puddles[#puddles + 1] = puddle
    end, MIN_SPAWN_DIST_FROM_PLAYER, SEARCH_RANGE, true, false, true, pz - 1, pz + 2)

    updatePuddleMarkers(puddles, player)
end

---@param deltaMs integer
function EffectSlipperyOilPuddles:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    self.markerUpdateTimer:add(deltaMs)
    if self.markerUpdateTimer:isEnded() then
        self.markerUpdateTimer:reset()
        updatePuddleMarkers(self.puddles, player)
    end

    self.playerCheckTimer:add(deltaMs)
    if self.playerCheckTimer:isEnded() then
        self.playerCheckTimer:reset()
        local px = player:getX()
        local py = player:getY()
        local playerZ = math.floor(player:getZ())
        local playerInVehicle = player:getVehicle() ~= nil

        for i = 1, #self.puddles do
            local puddle = self.puddles[i]
            if puddle.playerCooldownMs > 0 then
                puddle.playerCooldownMs = puddle.playerCooldownMs - PLAYER_CHECK_INTERVAL_MS
            end

            if not playerInVehicle and puddle.playerCooldownMs <= 0
                and playerZ == puddle.z
                and ChaosUtils.isInRange(px, py, puddle.centerX, puddle.centerY, PUDDLE_RADIUS) then
                knockdownPlayer(self, player)
                puddle.playerCooldownMs = PLAYER_KNOCKDOWN_COOLDOWN_MS
            end
        end
    end

    self.zombieCheckTimer:add(deltaMs)
    if self.zombieCheckTimer:isEnded() then
        self.zombieCheckTimer:reset()
        checkZombiesInPuddles(self, player)
    end

    if self.playerHighlightMs > 0 then
        self.playerHighlightMs = self.playerHighlightMs - deltaMs
        if self.playerHighlightMs <= 0 then
            clearBlackHighlight(player)
        else
            applyBlackHighlight(player)
        end
    end

    tickKnockedZombies(self, deltaMs)
end

function EffectSlipperyOilPuddles:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.puddles then
        for i = 1, #self.puddles do
            removeMarker(self.puddles[i])
        end
        self.puddles = {}
    end

    if self.knockedZombies then
        for id, entry in pairs(self.knockedZombies) do
            clearBlackHighlight(entry.zombie)
            self.knockedZombies[id] = nil
        end
    end

    clearBlackHighlight(getPlayer())
    self.playerHighlightMs = 0
end
