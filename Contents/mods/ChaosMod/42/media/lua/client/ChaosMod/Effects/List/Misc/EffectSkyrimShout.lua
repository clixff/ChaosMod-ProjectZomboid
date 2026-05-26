---@class EffectSkyrimShout : ChaosEffectBase
---@field canShoutPrevious boolean
---@field didShout boolean
---@field isActive boolean
---@field isCharging boolean
---@field shoutCooldownMs integer
---@field onKeyPressed fun(key: integer)
EffectSkyrimShout          = ChaosEffectBase:derive("EffectSkyrimShout", "skyrim_shout")

local SHOUT_COOLDOWN_MS    = 2500
local CHARGE_DURATION_MS   = 1000
local REMINDER_INTERVAL_MS = 10000
local SHOUT_RADIUS         = 10
local FACING_DOT           = 0.2
local KNOCKBACK_IMPULSE    = 70.0
local ZOMBIE_DAMAGE        = 0.9
local DAMAGE_DELAY_MS      = 60
local REMINDER_TEXT        = "Press Q to Shout"
local SHOUT_SOUND          = "chaos_skyrim_shout"

---@param sq1 IsoGridSquare
---@param sq2 IsoGridSquare
---@return boolean
local function hasWallOrFenceBetween(sq1, sq2)
    if not sq1 or not sq2 or sq1 == sq2 then return false end
    if sq1:isWallTo(sq2) then return true end
    if sq1:isHoppableTo(sq2) then return true end
    if sq1:getHoppableThumpableTo(sq2) ~= nil then return true end
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

---@param self EffectSkyrimShout
local function activateShout(self)
    if not self.isActive then return end

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local cell = getCell()
    if not cell then return end

    local px = player:getX()
    local py = player:getY()
    local pz = math.floor(player:getZ())

    local light = IsoLightSource.new(
        square:getX(), square:getY(), square:getZ(),
        0.5, 0.8, 0.9,
        20, 15)
    cell:addLamppost(light)



    ChaosZombie.ForEachZombieInRange(px, py, SHOUT_RADIUS, function(zombie)
        if not zombie or zombie:isDead() then return end
        local zx = zombie:getX()
        local zy = zombie:getY()
        if not isPlayerFacingPoint(player, zx, zy) then return end
        if not hasLineOfSight(cell, px, py, zx, zy, pz) then return end

        ChaosPhysics.KnockbackCharacter(zombie, px, py, KNOCKBACK_IMPULSE, false)
        ChaosSpecialAction.AddNewAction(
            { zombie = zombie },
            DAMAGE_DELAY_MS,
            nil,
            function(d)
                local weapon = player:getPrimaryHandItem()
                if not weapon or not weapon:IsWeapon() then
                    weapon = instanceItem("Base.BareHands")
                end

                ---@type IsoZombie
                local z = d.zombie
                if z and z:isAlive() then
                    ChaosZombie.DamageZombie(z, ZOMBIE_DAMAGE, player)
                end
            end,
            nil,
            false)
    end, false, pz)

    local nearbyVehicles = ChaosVehicle.GetVehiclesNearby(square, SHOUT_RADIUS)
    for i = 0, nearbyVehicles:size() - 1 do
        local vehicle = nearbyVehicles:get(i)
        if vehicle then
            local vx = vehicle:getX()
            local vy = vehicle:getY()
            local vz = math.floor(vehicle:getZ())
            if vz == pz and isPlayerFacingPoint(player, vx, vy)
                and hasLineOfSight(cell, px, py, vx, vy, pz) then
                ChaosVehicle.AddVehicleImpulseAtExplosion(vehicle, px, py, player:getZ(), 5.0)
            end
        end
    end

    ChaosUtils.SquareRingSearchTile_2D(math.floor(px), math.floor(py), function(sq)
        if not sq then return end
        local sqX = sq:getX() + 0.5
        local sqY = sq:getY() + 0.5
        if not isPlayerFacingPoint(player, sqX, sqY) then return end
        if not hasLineOfSight(cell, px, py, sqX, sqY, pz) then return end

        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            ChaosUtils.RemovePropExplosion(obj)
        end)

        local tree = sq:getTree()
        if tree then
            sq:RemoveTileObject(tree)
            pcall(function() tree:removeFromWorld() end)
            pcall(function() tree:removeFromSquare() end)
            sq:AddWorldInventoryItem("Base.UnusableWood",
                ChaosUtils.RandFloat(0.1, 0.9),
                ChaosUtils.RandFloat(0.1, 0.9), 0)
        end
    end, 1, SHOUT_RADIUS, false, false, true, pz, pz)
end

---@param self EffectSkyrimShout
local function triggerShout(self)
    if not self.isActive then return end
    if self.isCharging then return end
    if self.shoutCooldownMs > 0 then return end

    local player = getPlayer()
    if not player then return end

    self.didShout = true
    self.isCharging = true
    self.shoutCooldownMs = SHOUT_COOLDOWN_MS

    -- player:playSound(SHOUT_SOUND)

    -- getClimateManager():getThunderStorm():triggerThunderEvent(
    --     math.floor(player:getX()), math.floor(player:getY()),
    --     true,  -- doStrike: plays "Thunder"
    --     false, -- doLightning: visual flash
    --     false  -- doRumble
    -- )

    print("Triggering shout")

    -- player:transmitPlayerVoiceSound("ShoutHey")

    local sq = player:getSquare()
    if sq then
        local emitter = getWorld():getFreeEmitter(sq:getX(), sq:getY(), sq:getZ())
        print("Emitter is " .. tostring(emitter))
        if emitter then
            local sound = emitter:playSound(SHOUT_SOUND)
            print("sound is " .. tostring(sound))
        end
        -- sq:playSound(SHOUT_SOUND)
        addSound(player, sq:getX(), sq:getY(), sq:getZ(), 50, 60)
    end

    ChaosSpecialAction.AddNewAction(
        { elapsedMs = 0 },
        SHOUT_COOLDOWN_MS,
        function(deltaMs, d)
            d.elapsedMs = d.elapsedMs + deltaMs
            local bar = UIManager.getProgressBar(0)
            if bar then
                bar:setValue(d.elapsedMs / SHOUT_COOLDOWN_MS)
            end
        end,
        function(_d) end,
        nil,
        false)

    ChaosSpecialAction.AddNewAction(
        { self = self },
        CHARGE_DURATION_MS,
        nil,
        function(d)
            d.self.isCharging = false
            activateShout(d.self)
        end,
        nil,
        false)
end

---@param self EffectSkyrimShout
local function startReminderLoop(self)
    ChaosSpecialAction.AddNewAction(
        { self = self },
        REMINDER_INTERVAL_MS,
        nil,
        function(d)
            local s = d.self
            if not s.isActive then return true end
            if s.didShout then return true end
            local player = getPlayer()
            if player then
                ChaosPlayer.SayLine(player, REMINDER_TEXT, 0.68, 0.90, 1.0)
            end
            return nil
        end,
        nil,
        true)
end

function EffectSkyrimShout:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    self.canShoutPrevious = player:isCanShout()
    player:setCanShout(false)

    self.isActive = true
    self.didShout = false
    self.isCharging = false
    self.shoutCooldownMs = 0

    ChaosPlayer.SayLine(player, REMINDER_TEXT, 0.68, 0.90, 1.0)
    startReminderLoop(self)

    self.onKeyPressed = function(key)
        if key ~= Keyboard.KEY_Q then return end
        triggerShout(self)
    end
    Events.OnKeyPressed.Add(self.onKeyPressed)
end

---@param deltaMs integer
function EffectSkyrimShout:OnTick(deltaMs)
    if self.shoutCooldownMs and self.shoutCooldownMs > 0 then
        self.shoutCooldownMs = self.shoutCooldownMs - deltaMs
        if self.shoutCooldownMs < 0 then
            self.shoutCooldownMs = 0
        end
    end
end

function EffectSkyrimShout:OnEnd()
    ChaosEffectBase:OnEnd()

    self.isActive = false

    local player = getPlayer()
    if player then
        player:setCanShout(self.canShoutPrevious == true)
    end

    if self.onKeyPressed then
        Events.OnKeyPressed.Remove(self.onKeyPressed)
        self.onKeyPressed = nil
    end
end
