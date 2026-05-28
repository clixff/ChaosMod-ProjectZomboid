---@class EffectFireSnake : ChaosEffectBase
---@field headX integer
---@field headY integer
---@field moveTimer ChaosManualTimer
---@field started boolean
EffectFireSnake = ChaosEffectBase:derive("EffectFireSnake", "fire_snake")

local SPAWN_MIN_RADIUS = 15
local SPAWN_MAX_RADIUS = 20
local SPAWN_MAX_TRIES = 50
local MOVE_COOLDOWN_FAST_MS = 350
local MOVE_COOLDOWN_SLOW_MS = 600
local MOBILITY_FAST_THRESHOLD = 0.65

local NORMAL_WALK_SPEED = 0.796

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

---@return number
local function GetPlayerMobilityFloat(player)
    if not player then return 0 end

    local bd = player:getBodyDamage()
    local base = 0.8

    -- main non-leg penalties
    base = base - player:getMoodleLevel(MoodleType.ENDURANCE) * 0.15
    base = base - player:getMoodleLevel(MoodleType.HEAVY_LOAD) * 0.15

    -- torso injuries
    for i = BodyPartType.ToIndex(BodyPartType.Torso_Upper),
    BodyPartType.ToIndex(BodyPartType.Neck) do
        local part = bd:getBodyPart(BodyPartType.FromIndex(i))
        if part:HasInjury() then
            base = base - 0.1
        end
        if part:bandaged() then
            base = base + 0.05
        end
    end

    -- upper leg pain
    local leg = bd:getBodyPart(BodyPartType.UpperLeg_L)
    local pain = leg:getAdditionalPain(true)
    if pain > 20 then
        base = base - (pain - 20) / 100
    end

    -- shoes
    local runMod = player:getRunSpeedModifier()
    base = base * (1.0 - math.abs(1.0 - runMod) / 2.0)
    base = base * runMod

    -- temperature
    local thermo = bd:getThermoregulator()
    if thermo then
        base = base * thermo:getMovementModifier()
    end

    -- leg injury
    local walkInjury = math.max(0, player:getVariableFloat("WalkInjury", 0))
    local moveRatio = clamp(player:getMoveSpeed() / 0.06, 0, 1)
    local injuryRatio = 1 / (1 + walkInjury * 0.7)
    local legRatio = math.min(moveRatio, injuryRatio)
    base = base * legRatio

    -- run/sprint permission penalties
    local canSprint = player:canSprint()

    local canRun = true
    local ok, result = pcall(function() return player:isAllowRun() end)
    if ok then
        canRun = result
    end

    if not canRun then
        base = base * 0.8
    elseif not canSprint then
        base = base * 0.9
    end

    return clamp(base / 0.8, 0, 1)
end

---@param player IsoPlayer
---@return integer
local function GetMoveCooldownMs(player)
    if GetPlayerMobilityFloat(player) > MOBILITY_FAST_THRESHOLD then
        return MOVE_COOLDOWN_FAST_MS
    end
    return MOVE_COOLDOWN_SLOW_MS
end

---@param x integer
---@param y integer
---@param playerZ integer
local function igniteSquareAt(x, y, playerZ)
    local cell = getCell()
    if not cell then return end

    local sq = cell:getGridSquare(x, y, playerZ)
    if sq then
        IsoFireManager.StartFire(cell, sq, true, 100, 3000)
        return
    end

    local groundSq = cell:getGridSquare(x, y, 0)
    if groundSq then
        IsoFireManager.StartFire(cell, groundSq, true, 100, 3000)
    end
end

function EffectFireSnake:OnStart()
    ChaosEffectBase:OnStart()
    self.started = false

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local startSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, playerSquare:getZ(),
        SPAWN_MIN_RADIUS, SPAWN_MAX_RADIUS, SPAWN_MAX_TRIES, false, true, false)
    if not startSquare then return end

    self.headX = startSquare:getX()
    self.headY = startSquare:getY()
    self.moveTimer = ChaosManualTimer.new(GetMoveCooldownMs(player))
    self.started = true

    igniteSquareAt(self.headX, self.headY, playerSquare:getZ())
end

---@param deltaMs integer
function EffectFireSnake:OnTick(deltaMs)
    local p = getPlayer()

    local s = GetPlayerMobilityFloat(p)

    print(string.format("Mobility: %f. Is allow to run: %s", s, tostring(p:isAllowRun())))

    -- local baseMove = p:getMoveSpeed()
    -- local canSprint = p:canSprint()
    -- local walkSpeed = p:getVariableFloat("WalkSpeed", 0)
    -- local walkInjury = p:getVariableFloat("WalkInjury", 0)
    -- local runMod = p:getRunSpeedModifier()

    -- print(string.format("baseMove=%f canSprint=%s walkSpeed=%f walkInjury=%f runMod=%s",
    --     (baseMove), tostring(canSprint), (walkSpeed), (walkInjury), (runMod)))

    if not self.started then return end

    self.moveTimer:add(deltaMs)
    if not self.moveTimer:isEnded() then return end
    self.moveTimer:reset()

    local player = getPlayer()
    if not player then return end

    self.moveTimer:setMax(GetMoveCooldownMs(player))

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local targetX = playerSquare:getX()
    local targetY = playerSquare:getY()
    local playerZ = playerSquare:getZ()

    local dx = targetX - self.headX
    local dy = targetY - self.headY
    if dx == 0 and dy == 0 then return end

    if dx > 0 then
        self.headX = self.headX + 1
    elseif dx < 0 then
        self.headX = self.headX - 1
    end

    if dy > 0 then
        self.headY = self.headY + 1
    elseif dy < 0 then
        self.headY = self.headY - 1
    end

    igniteSquareAt(self.headX, self.headY, playerZ)
end

function EffectFireSnake:OnEnd()
    ChaosEffectBase:OnEnd()
end
