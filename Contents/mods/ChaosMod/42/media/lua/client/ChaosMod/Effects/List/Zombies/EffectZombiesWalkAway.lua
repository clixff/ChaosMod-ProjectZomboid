---@class EffectZombiesWalkAway : ChaosEffectBase
EffectZombiesWalkAway = ChaosEffectBase:derive("EffectZombiesWalkAway", "zombies_walk_away")

local USELESS_DURATION_MS = 10000
local WALK_AWAY_DISTANCE = 30
local ZOMBIE_RANGE = 30

---@param zombie IsoZombie
local function clearZombieTarget(zombie)
    zombie:clearAggroList()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setTarget(nil)
    zombie:setTargetSeenTime(0)
end

---@param zombie IsoZombie
---@param tx integer
---@param ty integer
---@param tz integer
local function forceZombieToPoint(zombie, tx, ty, tz)
    -- IsoZombie.spotted() ignores players while isUseless() is true, but
    -- WalkTowardState.enter() immediately sends useless zombies back to idle.
    -- So start/enter the movement state first, then mark the zombie useless.
    zombie:setUseless(false)
    clearZombieTarget(zombie)

    local pfb = zombie:getPathFindBehavior2()
    pfb:cancel()
    pfb:reset()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setPath2(nil)

    zombie:setTurnAlertedValues(tx, ty)
    zombie:pathToSound(tx, ty, tz)       -- sets PathFindBehavior2 goal + bMoving/bPathfind via pathToAux()
    zombie:setLastHeardSound(tx, ty, tz)

    local usePathFind = false
    pcall(function()
        usePathFind = zombie:getVariableBoolean("bPathfind") == true
    end)

    if usePathFind then
        zombie:changeState(PathFindState.instance())
    else
        zombie:changeState(WalkTowardState.instance())
    end

    zombie:setUseless(true)
end

---@param data table
local function restoreZombies(data)
    for _, obj in ipairs(data.objects) do
        local zombie = obj.zombie
        if zombie then
            zombie:setUseless(obj.wasUseless == true)
        end
    end
end

function EffectZombiesWalkAway:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ---@type table<integer, {zombie: IsoZombie, pos: { x: integer, y: integer, z: integer }, wasUseless: boolean, retryMs: integer }>
    local objects = {}

    ChaosZombie.ForEachZombieInRange(px, py, ZOMBIE_RANGE, function(zombie)
        if not zombie or not zombie:isAlive() then return end
        local zx = zombie:getX()
        local zy = zombie:getY()
        local zz = zombie:getZ()

        local dx = zx - px
        local dy = zy - py
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < 0.01 then return end

        local nx = dx / dist
        local ny = dy / dist

        local tx = math.floor(zx + nx * WALK_AWAY_DISTANCE)
        local ty = math.floor(zy + ny * WALK_AWAY_DISTANCE)
        local tz = math.floor(zz)

        local wasUseless = zombie:isUseless()
        forceZombieToPoint(zombie, tx, ty, tz)

        table.insert(objects, {
            zombie = zombie,
            pos = { x = tx, y = ty, z = tz },
            wasUseless = wasUseless,
            retryMs = 0
        })
    end, true, nil)

    ChaosSpecialAction.AddNewAction({ objects = objects }, USELESS_DURATION_MS,
        function(deltaMs, data)
            for _, obj in ipairs(data.objects) do
                ---@type IsoZombie
                local zombie = obj.zombie
                if zombie and zombie:isAlive() then
                    clearZombieTarget(zombie)
                    zombie:setUseless(true)
                    zombie:setLastHeardSound(obj.pos.x, obj.pos.y, obj.pos.z)

                    -- If another state bumped it back to idle before it reached the point,
                    -- re-enter movement, but not every tick (that would cancel pathfinding).
                    obj.retryMs = (obj.retryMs or 0) - deltaMs
                    if obj.retryMs <= 0
                        and zombie:isCurrentState(ZombieIdleState.instance())
                        and math.abs(zombie:getX() - obj.pos.x) + math.abs(zombie:getY() - obj.pos.y) > 2 then
                        forceZombieToPoint(zombie, obj.pos.x, obj.pos.y, obj.pos.z)
                        obj.retryMs = 500
                    end
                end
            end
        end,
        restoreZombies,
        restoreZombies)
end
