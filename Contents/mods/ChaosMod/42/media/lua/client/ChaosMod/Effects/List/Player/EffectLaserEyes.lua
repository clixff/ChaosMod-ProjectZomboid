---@class EffectLaserEyes.DamagedZombie
---@field zombie IsoZombie
---@field time integer
---@field renderHighlight boolean

---@class EffectLaserEyes : ChaosEffectBase
---@field scanTimer ChaosManualTimer
---@field damageTimer ChaosManualTimer
---@field nearbyZombies ArrayList<IsoZombie>?
---@field damagedZombies table<integer, EffectLaserEyes.DamagedZombie>
EffectLaserEyes = ChaosEffectBase:derive("EffectLaserEyes", "laser_eyes")

---@type number
local LASER_RADIUS = 8.0
---@type number
local SCAN_RADIUS = LASER_RADIUS * 2.0
---@type integer
local SCAN_INTERVAL_MS = 500
---@type integer
local DAMAGE_INTERVAL_MS = 16
---@type number
local LASER_DAMAGE = 0.05
---@type integer
local HIGHLIGHT_DURATION_MS = 100
---@type number
local FACING_DOT = 0.9
---@type number
local EYE_OFFSET = 0.05
---@type number
local LASER_LOS_STEP = 0.1

-- Laser beam and zombie outline color (red).
local COLOR_R = 1.0
local COLOR_G = 0.2
local COLOR_B = 0.1
local COLOR_A = 1.0

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

    return false
end

---@param cell IsoCell
---@param fromX number
---@param fromY number
---@param toX number
---@param toY number
---@param z integer
---@return boolean
local function hasLineOfSight(cell, fromX, fromY, toX, toY, z)
    local dx = toX - fromX
    local dy = toY - fromY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.001 then return true end
    local steps = math.ceil(dist * 2)
    local prevSq = cell:getGridSquare(math.floor(fromX), math.floor(fromY), z)
    for i = 1, steps do
        local t = i / steps
        local sx = math.floor(fromX + dx * t)
        local sy = math.floor(fromY + dy * t)
        local sq = cell:getGridSquare(sx, sy, z)
        if not sq then return false end
        if prevSq and sq ~= prevSq then
            if hasWallOrFenceBetween(prevSq, sq) then return false end
            prevSq = sq
        end
    end
    return true
end

---@param player IsoPlayer
---@param targetX number
---@param targetY number
---@return boolean
local function isPlayerFacingPoint(player, targetX, targetY)
    local dx = targetX - player:getX()
    local dy = targetY - player:getY()
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then return true end
    dx = dx / len
    dy = dy / len
    local fx = player:getForwardDirectionX() or 0
    local fy = player:getForwardDirectionY() or 0
    return (dx * fx + dy * fy) >= FACING_DOT
end

---@param zombie IsoZombie
---@param player IsoPlayer
---@return boolean
local function isValidTarget(zombie, player)
    if not zombie or not zombie:isAlive() then return false end
    if not ChaosNPCUtils.IsNPC(zombie) then return true end
    local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
    if not npc then return true end
    local relation = ChaosNPCRelations.GetRelationForNPC(npc, player)
    return relation == ChaosNPCRelationType.ATTACK
end

---@param chr IsoGameCharacter
---@return number x, number y, number z
local function getApproxHeadPos(chr)
    local x = chr:getX()
    local y = chr:getY()
    local z = chr:getZ()

    if chr:isSeatedInVehicle() then
        return x, y, z + 0.5
    end

    if chr:isSitOnGround() then
        return x, y, z + 0.35
    end

    if chr:isFalling() then
        return x, y, z + 0.2
    end

    -- standing / walking
    return x, y, z + 0.5
end

---@param self EffectLaserEyes
---@param player IsoPlayer
local function scanNearbyZombies(self, player)
    local pz = math.floor(player:getZ())
    self.nearbyZombies = ChaosZombie.GetNearestZombies(player:getX(), player:getY(), SCAN_RADIUS, false, pz)
end

---@param self EffectLaserEyes
---@param player IsoPlayer
local function fireLasers(self, player)
    local zombies = self.nearbyZombies
    if not zombies then return end

    local cell = getCell()
    if not cell then return end

    local px = player:getX()
    local py = player:getY()
    local pz = math.floor(player:getZ())
    local now = getTimestampMs()

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie and zombie:isAlive() then
            local zx = zombie:getX()
            local zy = zombie:getY()
            local zz = math.floor(zombie:getZ())

            if ChaosUtils.isInRange(px, py, zx, zy, LASER_RADIUS)
                and zz == pz
                and isValidTarget(zombie, player)
                and isPlayerFacingPoint(player, zx, zy)
                and hasLineOfSight(cell, px, py, zx, zy, pz) then
                zombie:knockDown(false)
                ChaosZombie.DamageZombie(zombie, LASER_DAMAGE, player)
                zombie:setOnFire(true)

                self.damagedZombies[zombie:getID()] = {
                    zombie = zombie,
                    time = now,
                    renderHighlight = true,
                }
                zombie:setOutlineHighlight(0, true)
                zombie:setOutlineHighlightCol(0, COLOR_R, COLOR_G, COLOR_B, COLOR_A)
            end
        end
    end
end

---@param self EffectLaserEyes
local function updateHighlights(self)
    local now = getTimestampMs()
    for id, data in pairs(self.damagedZombies) do
        if data.renderHighlight and now - data.time >= HIGHLIGHT_DURATION_MS then
            data.renderHighlight = false
            if data.zombie then
                data.zombie:setOutlineHighlight(0, false)
            end
            self.damagedZombies[id] = nil
        end
    end
end

---@param player IsoPlayer
local function renderLasers(player)
    local hx, hy, hz = getApproxHeadPos(player)

    local fx = player:getLookDirectionX() or 0
    local fy = player:getLookDirectionY() or 0
    local flen = math.sqrt(fx * fx + fy * fy)
    if flen < 0.001 then return end
    fx = fx / flen
    fy = fy / flen

    -- Raycast once from the head center, then render both eye rays using that same visible length.
    local perpX = -fy * EYE_OFFSET
    local perpY = fx * EYE_OFFSET

    local square = player:getSquare()
    local endZ = (square and square:getZ() or math.floor(player:getZ())) + 0.2
    local centerZ = math.floor(hz)
    local cell = getCell()

    local visibleRadius = LASER_RADIUS
    if cell then
        local lastClear = 0.0
        local d = LASER_LOS_STEP

        while d <= LASER_RADIUS do
            local tx = hx + fx * d
            local ty = hy + fy * d
            local result = LosUtil.lineClear(
                cell,
                math.floor(hx), math.floor(hy), centerZ,
                math.floor(tx), math.floor(ty), centerZ,
                false
            )

            if tostring(result) ~= "Clear" then
                break
            end

            lastClear = d
            d = d + LASER_LOS_STEP
        end

        visibleRadius = lastClear
    end

    for _, sign in ipairs({ -1, 1 }) do
        local sx = hx + perpX * sign
        local sy = hy + perpY * sign
        local ex = sx + fx * visibleRadius
        local ey = sy + fy * visibleRadius
        renderLine(sx, sy, hz, ex, ey, endZ, COLOR_R, COLOR_G, COLOR_B, COLOR_A)
    end
end

function EffectLaserEyes:OnStart()
    ChaosEffectBase:OnStart()

    self.scanTimer = ChaosManualTimer.new(SCAN_INTERVAL_MS)
    self.damageTimer = ChaosManualTimer.new(DAMAGE_INTERVAL_MS)
    self.damagedZombies = {}

    local player = getPlayer()
    if player then
        scanNearbyZombies(self, player)
    end
end

---@param deltaMs integer
function EffectLaserEyes:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    renderLasers(player)

    self.scanTimer:add(deltaMs)
    if self.scanTimer:isEnded() then
        self.scanTimer:reset()
        scanNearbyZombies(self, player)
    end

    self.damageTimer:add(deltaMs)
    if self.damageTimer:isEnded() then
        self.damageTimer:reset()
        fireLasers(self, player)
    end

    updateHighlights(self)
end

function EffectLaserEyes:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.damagedZombies then
        for _, data in pairs(self.damagedZombies) do
            if data.zombie then
                data.zombie:setOutlineHighlight(0, false)
            end
        end
        self.damagedZombies = {}
    end

    self.nearbyZombies = nil
end
