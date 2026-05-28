---@class PortalState
---@field square IsoGridSquare?
---@field centerX integer
---@field centerY integer
---@field centerZ integer
---@field marker WorldMarkers.GridSquareMarker?
---@field colorR number
---@field colorG number
---@field colorB number

---@class EffectUnstablePortals : ChaosEffectBase
---@field portalA PortalState  -- blue portal
---@field portalB PortalState  -- orange portal
---@field ready boolean
EffectUnstablePortals = ChaosEffectBase:derive("EffectUnstablePortals", "unstable_portals")

local PORTAL_RADIUS = 2
local MARKER_SIZE = PORTAL_RADIUS * math.sqrt(2.0)

local BLUE_R, BLUE_G, BLUE_B = 0.1, 0.6, 1.0
local ORANGE_R, ORANGE_G, ORANGE_B = 1.0, 0.5, 0.05

local BLUE_MIN_RADIUS = 2
local BLUE_MAX_RADIUS = 4
local FAR_MIN_RADIUS = 50
local FAR_MAX_RADIUS = 80
local SPAWN_TRIES = 80

local TELEPORT_PIVOT_OFFSET = 2.0
local TELEPORT_PIVOT_JITTER = 1.0
local TELEPORT_SEARCH_RADIUS = 12

---@param portal PortalState
---@param square IsoGridSquare
local function setPortalPosition(portal, square)
    portal.square = square
    portal.centerX = square:getX()
    portal.centerY = square:getY()
    portal.centerZ = square:getZ()
end

---@param portal PortalState
local function rebuildPortalMarker(portal)
    if portal.marker then
        portal.marker:remove()
        portal.marker = nil
    end
    if not portal.square then return end

    local markers = getWorldMarkers()
    if not markers then return end

    portal.marker = markers:addGridSquareMarker(
        portal.square, portal.colorR, portal.colorG, portal.colorB, true, MARKER_SIZE)
    if portal.marker then
        portal.marker:setScaleCircleTexture(false)
    end
end

---@param dest PortalState
---@return IsoGridSquare?
local function findTeleportSquareNearPortal(dest)
    local angle = ChaosUtils.RandFloat(0, math.pi * 2)
    local pivotR = PORTAL_RADIUS + TELEPORT_PIVOT_OFFSET + ChaosUtils.RandFloat(0, TELEPORT_PIVOT_JITTER)
    local pivotX = math.floor(dest.centerX + math.cos(angle) * pivotR)
    local pivotY = math.floor(dest.centerY + math.sin(angle) * pivotR)

    local found = nil
    ChaosUtils.SquareRingSearchTile_2D(pivotX, pivotY, function(sq)
        local sx, sy = sq:getX(), sq:getY()
        local dx = sx - dest.centerX
        local dy = sy - dest.centerY
        if (dx * dx + dy * dy) <= (PORTAL_RADIUS * PORTAL_RADIUS) then
            return false
        end
        found = sq
        return true
    end, 0, TELEPORT_SEARCH_RADIUS, true, true, true, dest.centerZ, dest.centerZ)

    return found
end

---@param zombie IsoZombie
---@param square IsoGridSquare
local function teleportZombieTo(zombie, square)
    zombie:setX(square:getX() + 0.5)
    zombie:setY(square:getY() + 0.5)
    zombie:setZ(square:getZ())
    zombie:setCurrentSquareFromPosition()
end

---@param self EffectUnstablePortals
---@param player IsoPlayer
---@param portal PortalState
local function movePortalNearPlayer(self, player, portal)
    local newSquare = ChaosPlayer.GetRandomSquareAroundPlayer(
        player, 0, FAR_MIN_RADIUS, FAR_MAX_RADIUS, SPAWN_TRIES, false, true, false)

    print("Tried to move portal near player. Result: " .. tostring(newSquare ~= nil))

    if not newSquare then return end
    setPortalPosition(portal, newSquare)
    rebuildPortalMarker(portal)
end

---@param self EffectUnstablePortals
---@param source PortalState
---@param dest PortalState
local function processPortal(self, source, dest)
    local player = getPlayer()
    if not player then return end

    local srcX = source.centerX
    local srcY = source.centerY
    local srcZ = source.centerZ

    local playerTeleported = false
    local px = player:getX()
    local py = player:getY()
    local pz = math.floor(player:getZ())

    if pz == srcZ and ChaosUtils.isInRange(px, py, srcX + 0.5, srcY + 0.5, PORTAL_RADIUS) then
        local destSquare = findTeleportSquareNearPortal(dest)
        if destSquare then
            ChaosVehicle.ExitVehicle(player)
            player:teleportTo(destSquare:getX(), destSquare:getY(), destSquare:getZ())
            playerTeleported = true
        else
            ChaosVehicle.ExitVehicle(player)
            player:teleportTo(dest.centerX + PORTAL_RADIUS + 2, dest.centerY, dest.centerZ)
            playerTeleported = true
        end
    end

    ChaosZombie.ForEachZombieInRange(srcX + 0.5, srcY + 0.5, PORTAL_RADIUS, function(zombie)
        if not zombie or zombie:isDead() then return end
        local destSquare = findTeleportSquareNearPortal(dest)
        if destSquare then
            teleportZombieTo(zombie, destSquare)
        end
    end, false, srcZ)

    if playerTeleported then
        movePortalNearPlayer(self, player, source)
    end
end

function EffectUnstablePortals:OnStart()
    ChaosEffectBase:OnStart()
    self.ready = false

    local player = getPlayer()
    if not player then return end

    local playerZ = math.floor(player:getZ())

    local blueSquare = ChaosPlayer.GetRandomSquareAroundPlayer(
        player, playerZ, BLUE_MIN_RADIUS, BLUE_MAX_RADIUS, SPAWN_TRIES, false, true, false)
    if not blueSquare then
        blueSquare = ChaosPlayer.GetRandomSquareAroundPlayer(
            player, 0, BLUE_MIN_RADIUS, BLUE_MAX_RADIUS, SPAWN_TRIES, false, true, false)
    end
    if not blueSquare then return end

    local orangeSquare = ChaosPlayer.GetRandomSquareAroundPlayer(
        player, 0, FAR_MIN_RADIUS, FAR_MAX_RADIUS, SPAWN_TRIES, false, true, false)
    if not orangeSquare then return end

    self.portalA = {
        square = nil,
        centerX = 0,
        centerY = 0,
        centerZ = 0,
        colorR = BLUE_R,
        colorG = BLUE_G,
        colorB = BLUE_B,
        marker = nil,
    }
    self.portalB = {
        square = nil,
        centerX = 0,
        centerY = 0,
        centerZ = 0,
        colorR = ORANGE_R,
        colorG = ORANGE_G,
        colorB = ORANGE_B,
        marker = nil,
    }

    setPortalPosition(self.portalA, blueSquare)
    setPortalPosition(self.portalB, orangeSquare)
    rebuildPortalMarker(self.portalA)
    rebuildPortalMarker(self.portalB)

    self.ready = true
end

---@param deltaMs integer
function EffectUnstablePortals:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    if not self.ready then return end

    processPortal(self, self.portalA, self.portalB)
    processPortal(self, self.portalB, self.portalA)
end

function EffectUnstablePortals:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.portalA and self.portalA.marker then
        self.portalA.marker:remove()
        self.portalA.marker = nil
    end
    if self.portalB and self.portalB.marker then
        self.portalB.marker:remove()
        self.portalB.marker = nil
    end
    if self.portalA then self.portalA.square = nil end
    if self.portalB then self.portalB.square = nil end
end
