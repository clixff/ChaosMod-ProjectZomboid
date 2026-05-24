---@class EffectEnergyShield : ChaosEffectBase
---@field marker WorldMarkers.GridSquareMarker?
EffectEnergyShield = ChaosEffectBase:derive("EffectEnergyShield", "energy_shield")

local ORBIT_RADIUS = 6.0
local PUSH_SPEED = 15.0
local INNER_BAND = ORBIT_RADIUS - 1.0
local OUTER_BAND = ORBIT_RADIUS + 0.5

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

function EffectEnergyShield:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local modData = player:getModData()
    if modData then
        modData.CHAOS_SHIELD_ENABLED = true
        modData.CHAOS_SHIELD_RADIUS = ORBIT_RADIUS
    end

    local playerSquare = player:getSquare()
    if playerSquare then
        local markers = getWorldMarkers()
        if markers then
            self.marker = markers:addGridSquareMarker(
                playerSquare,
                0.68, 0.90, 1.0,
                true,
                ORBIT_RADIUS + 2.0
            )
            if self.marker then
                self.marker:setScaleCircleTexture(true)
            end
        end
    end
end

---@param deltaMs integer
function EffectEnergyShield:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()

    if self.marker then
        self.marker:setPos(math.floor(px), math.floor(py), math.floor(pz))
    end

    local moveStep = PUSH_SPEED * (deltaMs / 1000.0)

    ChaosZombie.ForEachZombieInRange(px, py, OUTER_BAND, function(zombie)
        local zx = zombie:getX()
        local zy = zombie:getY()

        local dx = zx - px
        local dy = zy - py
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < INNER_BAND then return end

        local targetX, targetY
        if dist < 0.0001 then
            targetX = px + OUTER_BAND
            targetY = py
        else
            targetX = px + (dx / dist) * OUTER_BAND
            targetY = py + (dy / dist) * OUTER_BAND
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
    end, false, pz)
end

function EffectEnergyShield:OnEnd()
    ChaosEffectBase:OnEnd()

    local player = getPlayer()
    if player then
        local modData = player:getModData()
        if modData then
            modData.CHAOS_SHIELD_ENABLED = nil
            modData.CHAOS_SHIELD_RADIUS = nil
        end
    end

    if self.marker then
        self.marker:remove()
        self.marker = nil
    end
end
