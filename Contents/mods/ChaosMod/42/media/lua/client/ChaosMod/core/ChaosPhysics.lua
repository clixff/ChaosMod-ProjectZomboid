---ChaosPhysics is a small physics-helper module. Knockback motion is the
---first feature; other physics primitives can be added alongside it.
---@class ChaosPhysics
ChaosPhysics = ChaosPhysics or {}

-- Knockback tuning ---------------------------------------------------------

local KNOCKBACK_KNOCKDOWN_DELAY_MS = 30
local KNOCKBACK_STATE_WAIT_INTERVAL_MS = 16
local KNOCKBACK_STATE_WAIT_MAX_MS = 250

-- Hard cap on the knockback motion action (protection only — not a tuning value).
local KNOCKBACK_MAX_DURATION_MS = 3000

-- End-check interval. Motion runs on tickFn (PZ tick rate); endFn runs on
-- this interval and reports whether the action should end.
local KNOCKBACK_END_CHECK_INTERVAL_MS = 100

-- Exponential velocity deceleration. v(t+dt) = v(t) * exp(-KNOCKBACK_DAMPING * dt).
-- Tuned to feel like a real impulse: sharp initial push, smooth trail-off.
local KNOCKBACK_DAMPING = 6.0

-- When current speed drops below this, the knockback motion ends early.
local KNOCKBACK_MIN_SPEED = 0.1

-- Shared geometry helpers --------------------------------------------------

---@param sq1 IsoGridSquare
---@param sq2 IsoGridSquare
---@return boolean
local function hasWallBetween(sq1, sq2)
    if not sq1 or not sq2 or sq1 == sq2 then return false end
    if sq1:isWallTo(sq2) then return true end
    if sq1:isHoppableTo(sq2) then return true end
    if sq1:getHoppableThumpableTo(sq2) ~= nil then return true end
    return false
end

---@param character IsoGameCharacter
---@param stepX number
---@param stepY number
---@return boolean blocked
local function moveCharacterStep(character, stepX, stepY)
    if not character then return true end

    local cx = character:getX()
    local cy = character:getY()
    local cz = character:getZ()
    local nx = cx + stepX
    local ny = cy + stepY

    local cell = getCell()
    if not cell then return true end

    local fromSquare = character:getCurrentSquare()
    if not fromSquare then
        fromSquare = cell:getGridSquare(math.floor(cx), math.floor(cy), math.floor(cz))
    end
    if not fromSquare then return true end

    local toFloorX = math.floor(nx)
    local toFloorY = math.floor(ny)

    if toFloorX ~= fromSquare:getX() or toFloorY ~= fromSquare:getY() then
        local toSquare = cell:getGridSquare(toFloorX, toFloorY, math.floor(cz))
        if not toSquare then return true end
        if hasWallBetween(fromSquare, toSquare) then return true end
    end

    character:setX(nx)
    character:setY(ny)
    return false
end

-- Knockback ----------------------------------------------------------------

---@param character IsoGameCharacter
local function KnockbackAnimationEnd(character)
    if not character then return end

    print("KnockbackAnimationEnd")

    -- character:setBumpDone(true)
    -- character:setBumpType("")
    -- character:setBumpStaggered(false)
    -- character:setBumpFall(false)
    -- if instanceof(character, "IsoZombie") then
    --     -- BumpedState waits for BumpAnimFinished=true to transition back to
    --     -- idle; without this the zombie stays stuck with an empty BumpType.
    --     character:setVariable("BumpAnimFinished", true)
    -- end
    -- character:postAnimationFinishing()
end

---@param victim IsoGameCharacter
---@param dirX number
---@param dirY number
---@param impulse number
local function startKnockbackMotion(victim, dirX, dirY, impulse)
    local data = {
        victim = victim,
        vx = dirX * impulse,
        vy = dirY * impulse,
        elapsedMs = 0,
    }

    ChaosSpecialAction.AddNewAction(data, KNOCKBACK_END_CHECK_INTERVAL_MS,
        function(deltaMs, d)
            d.elapsedMs = d.elapsedMs + deltaMs

            local v = d.victim
            if not v then
                d.vx = 0
                d.vy = 0
                return
            end

            local dt = deltaMs / 1000.0
            local blocked = moveCharacterStep(v, d.vx * dt, d.vy * dt)
            if blocked then
                d.vx = 0
                d.vy = 0
                return
            end



            local decay = math.exp(-KNOCKBACK_DAMPING * dt)
            d.vx = d.vx * decay
            d.vy = d.vy * decay
        end,
        function(d)
            ---@type IsoGameCharacter
            local victim = d.victim
            local speed = math.sqrt(d.vx * d.vx + d.vy * d.vy)

            -- print("[startKnockbackMotion] speed: " .. tostring(speed) .. ", elapsedMs: " .. tostring(d.elapsedMs))

            ---@type IsoGameCharacter
            local v = data.victim

            -- if instanceof(v, "IsoZombie") then
            --     local bt = v:getBumpType()
            --     local actionName = v:getActionStateName()
            --     print("[[startKnockbackMotion] rearm_bump. bt = " ..
            --         tostring(bt) .. " action state = " .. actionName)
            --     if bt == nil or bt == "" or bt ~= "ChaosOnGround" or actionName ~= "bumped" then
            --         v:setBumpType("ChaosOnGround")
            --         v:setVariable("BumpAnimFinished", false)
            --     end
            -- end

            if speed < KNOCKBACK_MIN_SPEED or d.elapsedMs >= KNOCKBACK_MAX_DURATION_MS then
                if victim then
                    KnockbackAnimationEnd(victim)
                end
                return true
            end
            return nil
        end,
        nil,
        true)
end

---@param victim IsoZombie
---@param dirX number
---@param dirY number
---@param impulse number
local function startKnockbackWhenZombieFalls(victim, dirX, dirY, impulse)
    ChaosSpecialAction.AddNewAction(
        {
            victim = victim,
            dirX = dirX,
            dirY = dirY,
            impulse = impulse,
            waitedMs = 0,
        },
        KNOCKBACK_STATE_WAIT_INTERVAL_MS,
        function(deltaMs, d)
            d.waitedMs = d.waitedMs + deltaMs
        end,
        function(d)
            local v = d.victim
            if not v then return true end

            local stateName = v:getCurrentActionContextStateName()
            -- print(string.format("[ChaosPhysics.KnockbackWhenZombieFalls] State: %s. Waited: %d", stateName), d.waitedMs)
            if stateName == "falldown" or stateName == "falling" then
                startKnockbackMotion(v, d.dirX, d.dirY, d.impulse)
                return true
            end

            if d.waitedMs >= KNOCKBACK_STATE_WAIT_MAX_MS then
                startKnockbackMotion(v, d.dirX, d.dirY, d.impulse)
                return true
            end

            return nil
        end,
        nil,
        true)
end

---Apply a knockback impulse to a character. Schedules a delayed knockdown,
---then starts a motion that decelerates exponentially until the character
---almost stops (or hits a wall).
---@param victim IsoGameCharacter
---@param fromX number  -- world X of the impulse origin (attacker position)
---@param fromY number  -- world Y of the impulse origin (attacker position)
---@param impulse number  -- initial speed in tiles/sec (caller-tuned strength)
---@param hitFromBehind boolean  -- forwarded to victim:knockDown(...)
function ChaosPhysics.KnockbackCharacter(victim, fromX, fromY, impulse, hitFromBehind)
    if not victim then return end
    if not impulse or impulse <= 0 then return end

    local dx = victim:getX() - fromX
    local dy = victim:getY() - fromY
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.0001 then
        local angle = ChaosUtils.RandFloat(0.0, math.pi * 2.0)
        dx = math.cos(angle)
        dy = math.sin(angle)
    else
        dx = dx / len
        dy = dy / len
    end

    ChaosSpecialAction.AddNewAction(
        {
            victim = victim,
            hitFromBehind = hitFromBehind == true,
            dirX = dx,
            dirY = dy,
            impulse = impulse,
        },
        KNOCKBACK_KNOCKDOWN_DELAY_MS,
        nil,
        function(d)
            local v = d.victim
            if not v then return end
            if v:isDead() or v:getHealth() <= 0 then return end

            if instanceof(v, "IsoZombie") then
                ---@cast v IsoZombie
                v:knockDown(d.hitFromBehind)
                -- v:setVariable("BumpAnimFinished", false)
                -- v:setBumpType("")
                -- v:setBumpType("ChaosOnGround")
                startKnockbackMotion(v, d.dirX, d.dirY, d.impulse)
                -- print("[ChaosPhysics.KnockbackCharacter] Bumped zombie " .. tostring(v:getID()))
            else
                startKnockbackMotion(v, d.dirX, d.dirY, d.impulse)
            end
        end,
        nil,
        false)
end

return ChaosPhysics
