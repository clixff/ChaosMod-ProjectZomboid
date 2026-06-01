---@class EffectZombiesMagnet : ChaosEffectBase
---@field marker WorldMarkers.GridSquareMarker?
EffectZombiesMagnet = ChaosEffectBase:derive("EffectZombiesMagnet", "zombies_magnet")

local SEARCH_RADIUS = 35.0
local ORBIT_RADIUS  = 8.0
local PULL_SPEED    = 5.0

---@param sq1 IsoGridSquare
---@param sq2 IsoGridSquare
---@return boolean
local function hasWallOrFenceBetween(sq1, sq2)
    if not sq1 or not sq2 or sq1 == sq2 then
        return false
    end

    if sq1:isWallTo(sq2) then
        return true
    end

    if sq1:isHoppableTo(sq2) then
        return true
    end

    if sq1:getHoppableThumpableTo(sq2) ~= nil then
        return true
    end

    return false
end

---@param character IsoGameCharacter
---@param stepX number
---@param stepY number
local function moveCharacterByStep(character, stepX, stepY)
    if not character then return end

    local cx = character:getX()
    local cy = character:getY()
    local cz = character:getZ()

    local nx = cx + stepX
    local ny = cy + stepY

    local cell = getCell()
    if not cell then return end

    local fromSquare = character:getCurrentSquare()
    if not fromSquare then
        fromSquare = cell:getGridSquare(math.floor(cx), math.floor(cy), math.floor(cz))
    end
    if not fromSquare then return end

    local toFloorX = math.floor(nx)
    local toFloorY = math.floor(ny)
    local toFloorZ = math.floor(cz)

    if toFloorX ~= fromSquare:getX() or toFloorY ~= fromSquare:getY() then
        local toSquare = cell:getGridSquare(toFloorX, toFloorY, toFloorZ)
        if not toSquare then return end
        if hasWallOrFenceBetween(fromSquare, toSquare) then
            return
        end
    end

    character:setX(nx)
    character:setY(ny)
end

function EffectZombiesMagnet:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end
    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ() + 0.0

    local playerSquare = player:getSquare()

    if playerSquare then
        local markers = getWorldMarkers()
        if markers then
            self.marker = markers:addGridSquareMarker(
                playerSquare,
                1.0, 0.0, 0.0,
                true, -- fading alpha
                1.0
            )
            if self.marker then
                self.marker:setScaleCircleTexture(false)
                self.marker:setSize(ORBIT_RADIUS * math.sqrt(2.0))
            end
        end
    end
end

---@param deltaMs integer
function EffectZombiesMagnet:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()

    if self.marker then
        self.marker:setPos(math.floor(px), math.floor(py), math.floor(pz))
    end

    local moveStep = PULL_SPEED * (deltaMs / 1000.0)

    ChaosZombie.ForEachZombieInRange(px, py, SEARCH_RADIUS, function(zombie)
        local zx = zombie:getX()
        local zy = zombie:getY()

        local dx = zx - px
        local dy = zy - py
        local dist = math.sqrt(dx * dx + dy * dy)

        local targetX, targetY
        if dist < 0.0001 then
            targetX = px + ORBIT_RADIUS
            targetY = py
        else
            targetX = px + (dx / dist) * ORBIT_RADIUS
            targetY = py + (dy / dist) * ORBIT_RADIUS
        end

        local mdx = targetX - zx
        local mdy = targetY - zy
        local moveDist = math.sqrt(mdx * mdx + mdy * mdy)

        if moveDist < 0.0001 then return end

        local stepX, stepY
        if moveStep >= moveDist then
            stepX = mdx
            stepY = mdy
        else
            stepX = (mdx / moveDist) * moveStep
            stepY = (mdy / moveDist) * moveStep
        end

        moveCharacterByStep(zombie, stepX, stepY)
    end, true, pz)
end

function EffectZombiesMagnet:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.marker then
        self.marker:remove()
        self.marker = nil
    end
end
